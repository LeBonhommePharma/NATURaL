#!/usr/bin/env python3
"""Offline release configuration checks. Does not claim signing or App Review approval."""
from pathlib import Path
import argparse
import json
import plistlib
import struct
import subprocess
from submission_assets import validate_acknowledgements, validate_mac_icon_catalog, validate_tv_brand_catalog
from permission_localizations import validate_permission_localizations

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--include-macos', action='store_true', help='Also require native Mac App Store packaging')
args = parser.parse_args()

def require(condition, message):
    if not condition:
        raise SystemExit('FAIL: ' + message)

project = json.loads(subprocess.check_output([
    'plutil', '-convert', 'json', '-o', '-',
    str(ROOT / 'NATURaL.xcodeproj/project.pbxproj')
]))
objects = project['objects']
parents = {child: key for key, value in objects.items() if value.get('isa') in ('PBXGroup', 'PBXVariantGroup') for child in value.get('children', [])}
def resolved_path(ref):
    value = objects[ref]
    path = Path(value.get('path', ''))
    if ref in parents and value.get('sourceTree') == '<group>':
        path = resolved_path(parents[ref]) / path
    return path
def resource_paths(ref):
    value = objects[ref]
    if value['isa'] == 'PBXVariantGroup':
        require(bool(value.get('children')), 'Localized resource group must not be empty')
        return [path for child in value['children'] for path in resource_paths(child)]
    return [resolved_path(ref)]
def resource_name(ref):
    value = objects[ref]
    return value.get('path', value.get('name'))

try:
    validate_permission_localizations(ROOT, project)
except (ValueError, OSError, subprocess.CalledProcessError) as error:
    raise SystemExit('FAIL: ' + str(error))
targets = {v['name']: v for v in objects.values() if v.get('isa') == 'PBXNativeTarget'}
ios_products = {objects[p]['productName'] for p in targets['Bonhomme'].get('packageProductDependencies', [])}
require(ios_products == {'BonhommeCore', 'CareKitStore'}, 'Linked products changed: review dependency acknowledgements before release')
ios_resources = [objects[f]['fileRef'] for p in targets['Bonhomme']['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase' for f in objects[p]['files']]
require(any(resolved_path(r) == Path('Bonhomme/Resources/Acknowledgements.txt') for r in ios_resources), 'iOS acknowledgements must be included in Copy Bundle Resources')
try:
    validate_acknowledgements(ROOT / 'Bonhomme/Resources/Acknowledgements.txt')
except (ValueError, OSError) as error:
    raise SystemExit('FAIL: ' + str(error))
for name, platform in [('Bonhomme', 'ios'), ('BonhommeWatch', 'watchos')]:
    target = targets[name]
    resources = [objects[p] for p in target['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase']
    filenames = [resource_name(objects[b]['fileRef']) for p in resources for b in p['files']]
    for phase in resources:
        for build_file in phase['files']:
            resource = objects[build_file]['fileRef']
            for path in resource_paths(resource):
                require((ROOT / path).exists(), name + ' resource path: ' + str(path))
    require('Assets.xcassets' in filenames and 'PrivacyInfo.xcprivacy' in filenames, name + ' resources not bundled')
    for config_id in objects[target['buildConfigurationList']]['buildConfigurations']:
        settings = objects[config_id]['buildSettings']
        require(settings['ASSETCATALOG_COMPILER_APPICON_NAME'] == 'AppIcon', name + ' icon selection')
    iconset = ROOT / name / 'Assets.xcassets/AppIcon.appiconset'
    catalog = json.loads((iconset / 'Contents.json').read_text())
    for entry in catalog['images']:
        require(entry['platform'] == platform, name + ' icon platform')
        data = (iconset / entry['filename']).read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', name + ' icon must be PNG')
        width, height, depth, color = struct.unpack('>IIBB', data[16:26])
        require((width, height) == (1024, 1024), name + ' icon must be 1024 square')
        require(depth == 8 and color == 2 and b'tRNS' not in data, name + ' icon must be opaque RGB')
    manifest = plistlib.loads((ROOT / name / 'PrivacyInfo.xcprivacy').read_bytes())
    require(bool(manifest['NSPrivacyAccessedAPITypes']), name + ' required-reason API manifest')
    require(manifest.get('NSPrivacyTracking') is False, name + ' must declare no tracking')
    require(manifest.get('NSPrivacyCollectedDataTypes') == [], name + ' must declare no collected data types')
    require(manifest.get('NSPrivacyTrackingDomains') == [], name + ' must declare no tracking domains')

watch = plistlib.loads((ROOT / 'BonhommeWatch/Info.plist').read_bytes())
phone = plistlib.loads((ROOT / 'Bonhomme/Info.plist').read_bytes())
require(watch['WKApplication'] is True, 'WKApplication must be Boolean')
require(watch['WKCompanionAppBundleIdentifier'] == 'com.natural.Bonhomme', 'Watch companion mismatch')
require('workout-processing' in watch['WKBackgroundModes'], 'Watch workout background mode missing')
project_configs = objects[objects[project['rootObject']]['buildConfigurationList']]['buildConfigurations']
for config in project_configs:
    require('@executable_path/Frameworks' in objects[config]['buildSettings']['LD_RUNPATH_SEARCH_PATHS'], 'Swift runtime search path missing')
require('@main\nstruct WorkoutLiveActivity: Widget' in (ROOT / 'NATURaLLiveActivity/WorkoutLiveActivity.swift').read_text(), 'Live Activity extension entry point missing')
require(phone.get('NSSupportsLiveActivities') is True, 'Live Activities declaration missing')
watch_id = next(k for k,v in objects.items() if v is targets['BonhommeWatch'])
require(any(objects[d].get('target') == watch_id for d in targets['Bonhomme']['dependencies']), 'Watch target dependency missing')
require(any(objects[p].get('name') == 'Embed Watch Content' for p in targets['Bonhomme']['buildPhases']), 'Watch is not embedded')
def embedded_product(target_name, product_name, destination, path=''):
    target = targets[target_name]
    return any(
        phase.get('isa') == 'PBXCopyFilesBuildPhase'
        and str(phase.get('dstSubfolderSpec')) == destination
        and phase.get('dstPath', '') == path
        and any(objects[objects[f]['fileRef']].get('path') == product_name for f in phase.get('files', []))
        for phase in (objects[p] for p in target['buildPhases'])
    )

require(embedded_product('Bonhomme', 'BonhommeWatch.app', '16', '$(CONTENTS_FOLDER_PATH)/Watch'), 'Watch product must be embedded in the app Watch directory')
for extension in ('NATURaLWidgets', 'NATURaLLiveActivity'):
    require(embedded_product('Bonhomme', extension + '.appex', '13'), extension + ' must be embedded in PlugIns (dstSubfolderSpec 13)')
    extension_id = next(k for k, v in objects.items() if v is targets[extension])
    require(any(objects[d].get('target') == extension_id for d in targets['Bonhomme']['dependencies']), extension + ' target dependency missing')
    resource_refs = [objects[f]['fileRef'] for p in targets[extension]['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase' for f in objects[p]['files']]
    require(any(objects[r].get('path') == 'PrivacyInfo.xcprivacy' for r in resource_refs), extension + ' privacy manifest not bundled')
    for ref in resource_refs:
        for path in resource_paths(ref):
            require((ROOT / path).exists(), extension + ' resource path: ' + str(path))
release_versions = set()
for name in ('Bonhomme', 'BonhommeWatch', 'NATURaLWidgets', 'NATURaLLiveActivity'):
    target = targets[name]
    configurations = {objects[c]['name']: objects[c]['buildSettings'] for c in objects[target['buildConfigurationList']]['buildConfigurations']}
    release = configurations['Release']
    release_versions.add(release.get('MARKETING_VERSION'))
    require('DEBUG' not in release.get('SWIFT_ACTIVE_COMPILATION_CONDITIONS', '').split(), name + ' Release enables debug code')
    require(release.get('DEBUG_INFORMATION_FORMAT') == 'dwarf-with-dsym', name + ' Release must generate crash symbol files')
    info = plistlib.loads((ROOT / release['INFOPLIST_FILE']).read_bytes())
    require(info.get('CFBundleVersion') == '$(CURRENT_PROJECT_VERSION)', name + ' build number must use archive override')
    require(info.get('CFBundleShortVersionString') == '$(MARKETING_VERSION)', name + ' version must use build setting')
    if name != 'Bonhomme':
        require(release.get('SKIP_INSTALL') == 'YES', name + ' must not create a separate archive product')
    else:
        require(set(release.get('TARGETED_DEVICE_FAMILY', '').split(',')) == {'1', '2'}, 'Release must support iPhone and iPad')
require(len(release_versions) == 1 and None not in release_versions, 'Embedded app/extension marketing versions must match')
for path in (ROOT / 'Bonhomme').rglob('*.swift'):
    require('PaywallView' not in path.read_text() and 'SubscriptionStoreView' not in path.read_text(), 'Purchase barrier in ' + str(path))
persistence = (ROOT / 'Bonhomme/Services/Persistence/PersistentModels.swift').read_text()
require('cloudKitDatabase: .automatic' not in persistence, 'Health store must remain local')
require('cloudKitDatabase: .none' in persistence, 'Health store must disable CloudKit')
require('case cloudKitSynced' not in persistence, 'CloudKit sync mode must not ship')
entitlements = (ROOT / 'Bonhomme/Bonhomme.entitlements').read_text()
require('icloud-services' not in entitlements, 'iCloud services entitlement must not ship')
require('icloud-container-identifiers' not in entitlements, 'iCloud container entitlement must not ship')
require('ubiquity-kvstore-identifier' not in entitlements, 'iCloud KVS entitlement must not ship')
for swift in (ROOT / 'Bonhomme').rglob('*.swift'):
    require('NSUbiquitousKeyValueStore' not in swift.read_text(), 'iCloud KVS in ' + str(swift))
    require('import CloudKit' not in swift.read_text(), 'CloudKit import in ' + str(swift))
youtube = (ROOT / 'Bonhomme/Features/Workout/YouTubePlayerView.swift').read_text()
require('#if DEBUG && canImport(UIKit)' in youtube, 'YouTube player must be Debug-only')
live_target = targets['NATURaLLiveActivity']
live_resources = [objects[p] for p in live_target['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase']
live_filenames = [resource_name(objects[b]['fileRef']) for p in live_resources for b in p['files']]
require('PrivacyInfo.xcprivacy' in live_filenames, 'Live Activity privacy manifest not bundled')
for extra in (
    ROOT / 'NATURaLWidgets/PrivacyInfo.xcprivacy',
    ROOT / 'NATURaLLiveActivity/PrivacyInfo.xcprivacy',
    ROOT / 'BonhommeCore/Sources/BonhommeCore/Resources/PrivacyInfo.xcprivacy',
):
    extra_manifest = plistlib.loads(extra.read_bytes())
    require(extra_manifest.get('NSPrivacyTracking') is False, str(extra) + ' must declare no tracking')
    require(extra_manifest.get('NSPrivacyCollectedDataTypes') == [], str(extra) + ' must declare no collected data types')

# TV / visionOS: resource phases, catalogs, privacy. TV uses true layered brand assets.
for name, iconset, size in (
    ('BonhommeTV', ROOT / 'BonhommeTV/Assets.xcassets/AppIcon.brandassets', (1280, 768)),
    ('BonhommeVision', ROOT / 'BonhommeVision/Assets.xcassets/AppIcon.appiconset', (1024, 1024)),
):
    target = targets[name]
    resources = [objects[p] for p in target['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase']
    require(resources, name + ' missing Resources build phase')
    filenames = [resource_name(objects[b]['fileRef']) for p in resources for b in p['files']]
    require('Assets.xcassets' in filenames and 'PrivacyInfo.xcprivacy' in filenames, name + ' resources not bundled')
    for config_id in objects[target['buildConfigurationList']]['buildConfigurations']:
        settings = objects[config_id]['buildSettings']
        require(settings.get('ASSETCATALOG_COMPILER_APPICON_NAME') == 'AppIcon', name + ' icon selection')
    if name == 'BonhommeTV':
        try:
            validate_tv_brand_catalog(iconset)
        except (ValueError, OSError) as error:
            raise SystemExit('FAIL: ' + str(error))
    else:
        data = (iconset / 'AppIcon.png').read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n', name + ' icon must be PNG')
        width, height, depth, color = struct.unpack('>IIBB', data[16:26])
        require((width, height) == size, name + ' icon pixel size')
        require(depth == 8 and color == 2 and b'tRNS' not in data, name + ' icon must be opaque RGB')
    extra = ROOT / name / 'PrivacyInfo.xcprivacy'
    extra_manifest = plistlib.loads(extra.read_bytes())
    require(extra_manifest.get('NSPrivacyTracking') is False, str(extra) + ' must declare no tracking')
    require(extra_manifest.get('NSPrivacyCollectedDataTypes') == [], str(extra) + ' must declare no collected data types')
    info = plistlib.loads((ROOT / name / 'Info.plist').read_bytes())
    require(info.get('ITSAppUsesNonExemptEncryption') is False, name + ' export compliance missing')
    require(info.get('CFBundleDisplayName') == 'NATURaL', name + ' display name')
# Hosted tests import the app module and cannot target an older iOS version.
app_configs = {objects[c]['name']: objects[c]['buildSettings'] for c in objects[targets['Bonhomme']['buildConfigurationList']]['buildConfigurations']}
for test_name in ('BonhommeTests', 'BonhommeUITests'):
    for c in objects[targets[test_name]['buildConfigurationList']]['buildConfigurations']:
        config = objects[c]
        app_version = tuple(map(int, app_configs[config['name']]['IPHONEOS_DEPLOYMENT_TARGET'].split('.')))
        test_version = tuple(map(int, config['buildSettings']['IPHONEOS_DEPLOYMENT_TARGET'].split('.')))
        require(test_version >= app_version, test_name + ' deployment target is older than its host app')

if args.include_macos:
    try:
        validate_mac_icon_catalog(ROOT / 'BonhommeMac/Assets.xcassets/AppIcon.appiconset')
    except (ValueError, OSError) as error:
        raise SystemExit('FAIL: ' + str(error))
    require('BonhommeMac' in targets, 'native macOS target missing')
    mac = targets['BonhommeMac']
    resources = [resource_name(objects[f]['fileRef']) for p in mac['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase' for f in objects[p]['files']]
    require('Assets.xcassets' in resources and 'PrivacyInfo.xcprivacy' in resources, 'Mac icon catalog and privacy manifest must be bundled')
    for p in mac['buildPhases']:
        if objects[p]['isa'] == 'PBXResourcesBuildPhase':
            for f in objects[p]['files']:
                ref = objects[f]['fileRef']
                for path in resource_paths(ref):
                    require((ROOT / path).exists(), 'Mac resource missing: ' + str(path))
    manifest = plistlib.loads((ROOT / 'BonhommeMac/PrivacyInfo.xcprivacy').read_bytes())
    require(manifest.get('NSPrivacyTracking') is False and manifest.get('NSPrivacyCollectedDataTypes') == [], 'Mac privacy declaration mismatch')
    for c in objects[mac['buildConfigurationList']]['buildConfigurations']:
        settings = objects[c]['buildSettings']
        require(settings.get('ASSETCATALOG_COMPILER_APPICON_NAME') == 'AppIcon', 'Mac app icon selection missing')
        entitlements = plistlib.loads((ROOT / settings['CODE_SIGN_ENTITLEMENTS']).read_bytes())
        require(entitlements.get('com.apple.security.app-sandbox') is True, 'Mac App Store requires App Sandbox')
    info = plistlib.loads((ROOT / 'BonhommeMac/Info.plist').read_bytes())
    require(info.get('ITSAppUsesNonExemptEncryption') is False, 'Mac export compliance declaration missing')
print('PASS: source packaging configuration, icon format, privacy manifests, embedded products, free access, local storage.')
print('Still required: signed archive validation, device testing, App Store Connect metadata.')
