#!/usr/bin/env python3
"""Inspect a real xcarchive; this is not Apple's Organizer validation or App Review."""
import argparse
from pathlib import Path
import plistlib
import subprocess
from submission_assets import validate_acknowledgements

TEAM = 'ZJLX84G8QV'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_plist(path):
    require(path.is_file(), f'Missing plist: {path}')
    return plistlib.loads(path.read_bytes())


def validate_structure(archive, platform, build_number=None):
    """Return app bundles after inspecting compiled metadata, not source settings."""
    applications = archive / 'Products/Applications'
    apps = list(applications.glob('*.app'))
    require(len(apps) == 1, 'Archive must contain exactly one top-level application')
    app = apps[0]
    is_mac = platform == 'macos'
    info_path = lambda bundle: bundle / ('Contents/Info.plist' if is_mac else 'Info.plist')
    root_info = read_plist(info_path(app))
    expected_id = 'com.natural.Bonhomme.mac' if is_mac else 'com.natural.Bonhomme'
    require(root_info.get('CFBundleIdentifier') == expected_id, 'Unexpected application bundle identifier')
    archive_info = read_plist(archive / 'Info.plist')
    properties = archive_info.get('ApplicationProperties', {})
    require(properties.get('ApplicationPath') == 'Applications/' + app.name, 'Archive ApplicationPath does not identify the app')
    require(properties.get('CFBundleIdentifier') == expected_id, 'Archive bundle identifier differs from app')
    version = root_info.get('CFBundleShortVersionString')
    build = root_info.get('CFBundleVersion')
    require(isinstance(version, str) and version and '$(' not in version, 'Unresolved or missing marketing version')
    require(isinstance(build, str) and build and '$(' not in build, 'Unresolved or missing build number')
    if build_number is not None:
        require(build == str(build_number), 'Archive has the wrong build number')
    require(properties.get('CFBundleVersion') == build, 'Archive build number differs from app')
    bundles = [(app, expected_id, 'MacOSX' if is_mac else 'iPhoneOS')]
    if not is_mac:
        validate_acknowledgements(app / 'Acknowledgements.txt')
        require(set(root_info.get('UIDeviceFamily', [])) == {1, 2}, 'iOS app must support both iPhone and iPad')
        watch_apps = list((app / 'Watch').glob('*.app'))
        require(len(watch_apps) == 1, 'Exactly one embedded Watch app is required')
        watch = watch_apps[0]
        watch_info = read_plist(watch / 'Info.plist')
        require(watch_info.get('WKCompanionAppBundleIdentifier') == expected_id, 'Watch companion identifier mismatch')
        require(watch_info.get('WKApplication') is True, 'Watch application flag is missing')
        bundles.append((watch, expected_id + '.watchkitapp', 'WatchOS'))
        for name, suffix in [('NATURaLWidgets', '.Widgets'), ('NATURaLLiveActivity', '.LiveActivity')]:
            bundles.append((app / 'PlugIns' / (name + '.appex'), expected_id + suffix, 'iPhoneOS'))
    for bundle, identifier, supported_platform in bundles:
        info = read_plist(info_path(bundle))
        require(info.get('CFBundleIdentifier') == identifier, f'{bundle.name}: bundle identifier mismatch')
        require(info.get('CFBundleVersion') == build, f'{bundle.name}: build number mismatch')
        require(info.get('CFBundleShortVersionString') == version, f'{bundle.name}: marketing version mismatch')
        require(supported_platform in info.get('CFBundleSupportedPlatforms', []), f'{bundle.name}: wrong platform (simulator archive?)')
        executable = info.get('CFBundleExecutable', '')
        require(executable and '/' not in executable, f'{bundle.name}: missing executable name')
        binary = bundle / ('Contents/MacOS' if is_mac else '') / executable
        require(binary.is_file(), f'{bundle.name}: executable missing')
        resources = bundle / 'Contents/Resources' if is_mac else bundle
        manifest = read_plist(resources / 'PrivacyInfo.xcprivacy')
        require(manifest.get('NSPrivacyTracking') is False, f'{bundle.name}: tracking declaration mismatch')
        require(manifest.get('NSPrivacyCollectedDataTypes') == [], f'{bundle.name}: collection declaration mismatch')
        require((archive / 'dSYMs' / (bundle.name + '.dSYM') / 'Contents/Resources/DWARF' / executable).is_file(), f'{bundle.name}: crash symbols missing')
    return [bundle for bundle, _, _ in bundles]


def validate_signatures(bundles, platform):
    for bundle in bundles:
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(bundle)], check=True, capture_output=True)
        signature = subprocess.run(['codesign', '-dv', '--verbose=4', str(bundle)], check=True, capture_output=True, text=True)
        require(f'TeamIdentifier={TEAM}' in signature.stderr.splitlines(), f'{bundle.name}: wrong or absent signing team')
        if platform == 'macos':
            result = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(bundle)], check=True, capture_output=True)
            require(plistlib.loads(result.stdout).get('com.apple.security.app-sandbox') is True, 'Signed Mac app lacks App Sandbox')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    parser.add_argument('--platform', choices=['ios', 'macos'], default='ios')
    parser.add_argument('--build-number')
    args = parser.parse_args()
    try:
        bundles = validate_structure(args.archive, args.platform, args.build_number)
        validate_signatures(bundles, args.platform)
    except (ValueError, OSError, plistlib.InvalidFileException, subprocess.CalledProcessError) as error:
        parser.exit(1, f'FAIL: {error}\n')
    print(f'PASS: {len(bundles)} archived app/extension bundles, versions, device platforms, privacy manifests, symbols and signing team.')
    print('Still required: Organizer distribution validation, hardware testing and App Store Connect processing.')


if __name__ == '__main__':
    main()
