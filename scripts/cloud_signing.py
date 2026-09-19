#!/usr/bin/env python3
"""Manual, offline App Store signing on disposable GitHub-hosted macOS runners.

No API key, provisioning updates, export, upload or submission is performed.
"""
import argparse
import base64
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import secrets
import shlex
import shutil
import ssl
import subprocess
import sys
import uuid

TEAM = 'ZJLX84G8QV'
ROOT = Path(__file__).resolve().parents[1]
BUNDLES = {
    'ios': {
        'com.natural.Bonhomme': ('IOS', 'iOS', 'Bonhomme/Bonhomme.entitlements'),
        'com.natural.Bonhomme.watchkitapp': ('WATCH', 'watchOS', 'BonhommeWatch/BonhommeWatch.entitlements'),
        'com.natural.Bonhomme.Widgets': ('WIDGETS', 'iOS', 'NATURaLWidgets/NATURaLWidgets.entitlements'),
        'com.natural.Bonhomme.LiveActivity': ('LIVE_ACTIVITY', 'iOS', None),
    },
    'tvos': {'com.natural.BonhommeTV': ('TVOS', 'tvOS', None)},
    'macos': {'com.natural.Bonhomme.mac': ('MACOS', 'OSX', 'BonhommeMac/BonhommeMac.entitlements')},
}

TARGETS = {
    'com.natural.Bonhomme': 'Bonhomme',
    'com.natural.Bonhomme.watchkitapp': 'BonhommeWatch',
    'com.natural.Bonhomme.Widgets': 'NATURaLWidgets',
    'com.natural.Bonhomme.LiveActivity': 'NATURaLLiveActivity',
    'com.natural.BonhommeTV': 'BonhommeTV',
    'com.natural.Bonhomme.mac': 'BonhommeMac',
}


def signing_config(platform, fingerprint, keychain):
    # Unknown targets (including Swift package resource bundles) get no profile.
    lines = [f'DEVELOPMENT_TEAM = {TEAM}', 'CODE_SIGN_STYLE = Manual',
             f'CODE_SIGN_IDENTITY = {fingerprint}',
             'PROVISIONING_PROFILE_SPECIFIER = $(NATURAL_PROFILE_$(TARGET_NAME))',
             f'OTHER_CODE_SIGN_FLAGS = $(inherited) --keychain "{keychain}"']
    lines.extend(f'NATURAL_PROFILE_{TARGETS[bundle_id]} = {bundle_id}' for bundle_id in BUNDLES[platform])
    return '\n'.join(lines) + '\n'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def run(args, **kwargs):
    # Never expose command arguments, environment, stdout or stderr on failure:
    # security's argv includes the temporary keychain and P12 passwords.
    result = subprocess.run(args, capture_output=True, **kwargs)
    require(result.returncode == 0, f'{Path(args[0]).name} failed (exit {result.returncode}); credentials were not printed')
    return result.stdout


def utc(value):
    require(isinstance(value, dt.datetime), 'Profile validity date missing')
    return value.replace(tzinfo=dt.timezone.utc) if value.tzinfo is None else value.astimezone(dt.timezone.utc)


def validate_profile(profile, bundle_id, platform, certificate, now=None, required_entitlements=None):
    now = now or dt.datetime.now(dt.timezone.utc)
    require(profile.get('TeamIdentifier') == [TEAM], 'Provisioning profile team mismatch')
    require(profile.get('Name') == bundle_id, 'Profile Name must equal its exact bundle identifier')
    try:
        uuid.UUID(profile.get('UUID', ''))
    except (ValueError, AttributeError):
        raise ValueError('Invalid profile UUID') from None
    require(utc(profile.get('CreationDate')) <= now, 'Profile is not yet valid')
    require(utc(profile.get('ExpirationDate')) > now + dt.timedelta(days=1), 'Profile expires within 24 hours')
    require('ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices'), 'Use an App Store profile, not development, ad hoc, enterprise or Developer ID')
    platforms = set(profile.get('Platform', []))
    # Apple historically identifies watch profiles as iOS.
    accepted = {'iOS', 'watchOS'} if platform == 'watchOS' else {platform}
    require(bool(platforms & accepted), 'Profile platform mismatch')
    entitlements = profile.get('Entitlements', {})
    identifier_key = 'com.apple.application-identifier' if platform == 'OSX' else 'application-identifier'
    prefixes = profile.get('ApplicationIdentifierPrefix', [])
    require(len(prefixes) == 1 and isinstance(prefixes[0], str), 'Profile App ID prefix missing')
    require(entitlements.get(identifier_key) == prefixes[0] + '.' + bundle_id, 'Profile must authorize the exact bundle ID; wildcards are not accepted')
    require(entitlements.get('com.apple.developer.team-identifier') == TEAM, 'Profile entitlement team mismatch')
    require(not entitlements.get('get-task-allow') and not entitlements.get('com.apple.security.get-task-allow'), 'Distribution profile permits debugging')
    certificates = profile.get('DeveloperCertificates', [])
    require(len(certificates) == 1 and certificates[0] == certificate, 'Profile must contain the selected distribution certificate')
    for key, value in (required_entitlements or {}).items():
        if key == 'com.apple.security.app-sandbox':
            continue  # Unrestricted Mac entitlement; not a provisioning capability.
        if key == 'aps-environment':
            value = 'production'  # Distribution signing must use the production entitlement.
        authorized = entitlements.get(key)
        if isinstance(value, list):
            require(isinstance(authorized, list) and set(value) <= set(authorized), f'Profile lacks required capability {key}')
        else:
            require(authorized == value, f'Profile lacks required capability {key}')
    return profile['UUID']


def secret_bytes(name):
    value = os.environ.get(name, '')
    require(value, f'Missing GitHub environment secret: {name}')
    try:
        return base64.b64decode(''.join(value.split()), validate=True)
    except ValueError:
        raise ValueError(f'{name} must contain base64-encoded file bytes') from None


def paths():
    require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('RUNNER_ENVIRONMENT') == 'github-hosted',
            'Signing setup is restricted to disposable GitHub-hosted runners')
    directory = Path(os.environ['RUNNER_TEMP']).resolve() / 'natural-signing'
    return directory, directory / 'state.json'


def save_state(path, state):
    path.write_text(json.dumps(state))
    path.chmod(0o600)


def prepare(platform):
    directory, state_path = paths()
    require(not directory.exists(), 'Signing scratch directory already exists')
    os.umask(0o077)
    directory.mkdir()
    keychain = directory / 'signing.keychain-db'
    original_search = shlex.split(run(['security', 'list-keychains', '-d', 'user'], text=True))
    state = {'platform': platform, 'keychain': str(keychain), 'search': original_search, 'installed': [], 'profiles': {}}
    save_state(state_path, state)
    prefix = 'NATURAL_MAC_' if platform == 'macos' else 'NATURAL_'
    p12 = directory / 'distribution.p12'
    p12.write_bytes(secret_bytes(prefix + 'DISTRIBUTION_P12_BASE64'))
    password = os.environ.get(prefix + 'P12_PASSWORD', '')
    require(password, f'Missing GitHub environment secret: {prefix}P12_PASSWORD')
    keychain_password = secrets.token_urlsafe(32)
    run(['security', 'create-keychain', '-p', keychain_password, str(keychain)])
    run(['security', 'set-keychain-settings', '-lut', '7200', str(keychain)])
    run(['security', 'unlock-keychain', '-p', keychain_password, str(keychain)])
    run(['security', 'import', str(p12), '-k', str(keychain), '-P', password, '-T', '/usr/bin/codesign', '-T', '/usr/bin/security'])
    run(['security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', keychain_password, str(keychain)])
    identities = run(['security', 'find-identity', '-v', '-p', 'codesigning', str(keychain)], text=True)
    matches = re.findall(r'\d+\) ([A-F0-9]{40}) "([^"]+)"', identities)
    require(len(matches) == 1, 'P12 must contain exactly one valid signing identity and private key')
    fingerprint, name = matches[0]
    allowed = ('Apple Distribution:', '3rd Party Mac Developer Application:') if platform == 'macos' else ('Apple Distribution:', 'iPhone Distribution:')
    require(name.startswith(allowed), 'Certificate is not an App Store distribution identity')
    pem = run(['security', 'find-certificate', '-a', '-p', str(keychain)], text=True)
    certificates = [ssl.PEM_cert_to_DER_cert(part) for part in re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', pem, re.S)]
    certificate = next((c for c in certificates if hashlib.sha1(c).hexdigest().upper() == fingerprint), None)
    require(certificate is not None, 'Signing certificate could not be matched to private key')
    cert_path = directory / 'distribution.cer'
    cert_path.write_bytes(certificate)
    subject = run(['openssl', 'x509', '-inform', 'DER', '-in', str(cert_path), '-noout', '-subject', '-nameopt', 'RFC2253'], text=True)
    require(re.search(r'(?:^|,)OU=' + TEAM + r'(?:,|$)', subject.removeprefix('subject=').strip()), 'Signing certificate team mismatch')
    run(['openssl', 'x509', '-inform', 'DER', '-in', str(cert_path), '-noout', '-checkend', '86400'])
    state['certificate_sha256'] = hashlib.sha256(certificate).hexdigest()
    state['certificate_sha1'] = fingerprint
    for bundle_id, (secret, profile_platform, entitlement_file) in BUNDLES[platform].items():
        raw = secret_bytes('NATURAL_' + secret + '_PROFILE_BASE64')
        temporary = directory / (secret + '.profile')
        temporary.write_bytes(raw)
        profile = plistlib.loads(run(['security', 'cms', '-D', '-i', str(temporary)]))
        entitlements = plistlib.loads((ROOT / entitlement_file).read_bytes()) if entitlement_file else {}
        identifier = validate_profile(profile, bundle_id, profile_platform, certificate, required_entitlements=entitlements)
        extension = '.provisionprofile' if platform == 'macos' else '.mobileprovision'
        # Xcode 16+ location; the legacy location also supports older macOS tooling.
        for relative in ('Library/Developer/Xcode/UserData/Provisioning Profiles', 'Library/MobileDevice/Provisioning Profiles'):
            destination = Path.home() / relative / (identifier + extension)
            require(not destination.exists(), 'Refusing to replace an existing runner provisioning profile')
            destination.parent.mkdir(parents=True, exist_ok=True)
            state['installed'].append(str(destination)); save_state(state_path, state)
            destination.write_bytes(raw)
        state['profiles'][bundle_id] = {'uuid': identifier, 'sha256': hashlib.sha256(raw).hexdigest()}
        save_state(state_path, state)
    run(['security', 'list-keychains', '-d', 'user', '-s', str(keychain), *original_search])
    (directory / 'signing.xcconfig').write_text(signing_config(platform, fingerprint, keychain))
    p12.unlink()
    print(f'Prepared isolated distribution signing for {len(BUNDLES[platform])} bundles; private material remains outside the checkout.')


def verify_settings():
    directory, state_path = paths()
    state = json.loads(state_path.read_text())
    for bundle_id, (_, platform, _) in BUNDLES[state['platform']].items():
        sdk = {'iOS': 'iphoneos', 'watchOS': 'watchos', 'tvOS': 'appletvos', 'OSX': 'macosx'}[platform]
        target = TARGETS[bundle_id]
        output = run(['xcodebuild', '-project', str(ROOT / 'NATURaL.xcodeproj'), '-target', target,
                      '-configuration', 'Release', '-sdk', sdk, '-xcconfig', str(directory / 'signing.xcconfig'),
                      '-showBuildSettings', '-json'], text=True)
        values = json.loads(output)
        settings = next((entry['buildSettings'] for entry in values if entry.get('target') == target), None)
        require(settings is not None, 'Xcode did not resolve the expected shipping target')
        require(settings.get('PRODUCT_BUNDLE_IDENTIFIER') == bundle_id, 'Target bundle ID changed; review signing map')
        require(settings.get('PROVISIONING_PROFILE_SPECIFIER') == bundle_id, 'Xcode per-target profile expansion did not resolve')
        require(settings.get('CODE_SIGN_STYLE') == 'Manual', 'Xcode did not select manual signing')
        require(settings.get('CODE_SIGN_IDENTITY') == state['certificate_sha1'], 'Xcode signing identity override did not resolve')
    print('PASS: Xcode resolved the expected manual profile and identity for every shipping target.')


def verify_archive(archive):
    directory, state_path = paths()
    state = json.loads(state_path.read_text())
    platform = state['platform']
    # Reuse the structural and cryptographic checks; this adds distribution checks.
    import importlib.util
    spec = importlib.util.spec_from_file_location('archive_validation', ROOT / 'scripts/validate-archive.py')
    module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
    bundles = module.validate_structure(archive, platform, os.environ['BUILD_NUMBER'])
    module.validate_signatures(bundles, platform)
    for index, bundle in enumerate(bundles):
        is_mac = platform == 'macos'
        info = plistlib.loads((bundle / ('Contents/Info.plist' if is_mac else 'Info.plist')).read_bytes())
        bundle_id = info['CFBundleIdentifier']
        profile_path = bundle / ('Contents/embedded.provisionprofile' if is_mac else 'embedded.mobileprovision')
        raw = profile_path.read_bytes()
        require(hashlib.sha256(raw).hexdigest() == state['profiles'][bundle_id]['sha256'], 'Archive embedded an unexpected provisioning profile')
        profile = plistlib.loads(run(['security', 'cms', '-D', '-i', str(profile_path)]))
        prefix = directory / f'archive-cert-{index}-'
        run(['codesign', '-d', '--extract-certificates', str(prefix), str(bundle)])
        certificate = Path(str(prefix) + '0').read_bytes()
        require(hashlib.sha256(certificate).hexdigest() == state['certificate_sha256'], 'Archive signed with an unexpected certificate')
        _, profile_platform, entitlement_file = BUNDLES[platform][bundle_id]
        requested = plistlib.loads((ROOT / entitlement_file).read_bytes()) if entitlement_file else {}
        validate_profile(profile, bundle_id, profile_platform, certificate, required_entitlements=requested)
        signed = plistlib.loads(run(['codesign', '-d', '--entitlements', ':-', str(bundle)]))
        require(not signed.get('get-task-allow') and not signed.get('com.apple.security.get-task-allow'), 'Archive signature permits debugging')
        identifier_key = 'com.apple.application-identifier' if is_mac else 'application-identifier'
        require(signed.get(identifier_key) == profile['Entitlements'][identifier_key], 'Signed application identifier differs from profile')
        if 'aps-environment' in requested:
            require(signed.get('aps-environment') == 'production', 'Archive uses development push environment')
    print(f'PASS: {len(bundles)} distribution-signed bundles use the selected, unexpired App Store profiles and certificate.')


def cleanup():
    directory, state_path = paths()
    if not directory.exists():
        return
    failed = False
    if state_path.exists():
        state = json.loads(state_path.read_text())
        for command in (['security', 'list-keychains', '-d', 'user', '-s', *state['search']],
                        ['security', 'delete-keychain', state['keychain']]):
            result = subprocess.run(command, capture_output=True)
            # Missing keychain is expected if preparation failed before creation.
            if result.returncode and Path(state['keychain']).exists():
                failed = True
        for path in state['installed']:
            Path(path).unlink(missing_ok=True)
    shutil.rmtree(directory)
    require(not failed, 'Keychain cleanup failed; disposable hosted runner will still be destroyed')
    print('Removed temporary keychain, profiles and signing files.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'verify-settings', 'verify', 'cleanup'])
    parser.add_argument('--platform', choices=list(BUNDLES))
    parser.add_argument('--archive', type=Path)
    args = parser.parse_args()
    try:
        if args.action == 'prepare':
            require(args.platform in BUNDLES, 'Select a signing platform'); prepare(args.platform)
        elif args.action == 'verify-settings':
            verify_settings()
        elif args.action == 'verify':
            require(args.archive is not None, 'Provide the archive path'); verify_archive(args.archive)
        else:
            cleanup()
    except (ValueError, OSError, KeyError, plistlib.InvalidFileException) as error:
        # Exceptions from run() are deliberately redacted above.
        parser.exit(1, f'FAIL: {error}\n')


if __name__ == '__main__':
    main()
