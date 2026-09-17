#!/usr/bin/env python3
"""Offline release configuration checks. Does not claim signing or App Review approval."""
from pathlib import Path
import json
import plistlib
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def require(condition, message):
    if not condition:
        raise SystemExit('FAIL: ' + message)

project = json.loads(subprocess.check_output([
    'plutil', '-convert', 'json', '-o', '-',
    str(ROOT / 'NATURaL.xcodeproj/project.pbxproj')
]))
objects = project['objects']
parents = {child: key for key, value in objects.items() if value.get('isa') == 'PBXGroup' for child in value.get('children', [])}
def resolved_path(ref):
    value = objects[ref]
    path = Path(value.get('path', ''))
    if ref in parents and value.get('sourceTree') == '<group>':
        path = resolved_path(parents[ref]) / path
    return path
targets = {v['name']: v for v in objects.values() if v.get('isa') == 'PBXNativeTarget'}
for name, platform in [('Bonhomme', 'ios'), ('BonhommeWatch', 'watchos')]:
    target = targets[name]
    resources = [objects[p] for p in target['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase']
    filenames = [objects[objects[b]['fileRef']]['path'] for p in resources for b in p['files']]
    for phase in resources:
        for build_file in phase['files']:
            resource = objects[build_file]['fileRef']
            require((ROOT / resolved_path(resource)).exists(), name + ' resource path: ' + str(resolved_path(resource)))
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
live_filenames = [objects[objects[b]['fileRef']]['path'] for p in live_resources for b in p['files']]
require('PrivacyInfo.xcprivacy' in live_filenames, 'Live Activity privacy manifest not bundled')
for extra in (
    ROOT / 'NATURaLWidgets/PrivacyInfo.xcprivacy',
    ROOT / 'NATURaLLiveActivity/PrivacyInfo.xcprivacy',
    ROOT / 'BonhommeCore/Sources/BonhommeCore/Resources/PrivacyInfo.xcprivacy',
):
    extra_manifest = plistlib.loads(extra.read_bytes())
    require(extra_manifest.get('NSPrivacyTracking') is False, str(extra) + ' must declare no tracking')
    require(extra_manifest.get('NSPrivacyCollectedDataTypes') == [], str(extra) + ' must declare no collected data types')

# TV / visionOS: resource phases, catalogs, privacy. Flattened RGB until layered Design files land.
for name, iconset, size in (
    ('BonhommeTV', ROOT / 'BonhommeTV/Assets.xcassets/AppIcon.appiconset', (1280, 768)),
    ('BonhommeVision', ROOT / 'BonhommeVision/Assets.xcassets/AppIcon.appiconset', (1024, 1024)),
):
    target = targets[name]
    resources = [objects[p] for p in target['buildPhases'] if objects[p]['isa'] == 'PBXResourcesBuildPhase']
    require(resources, name + ' missing Resources build phase')
    filenames = [objects[objects[b]['fileRef']]['path'] for p in resources for b in p['files']]
    require('Assets.xcassets' in filenames and 'PrivacyInfo.xcprivacy' in filenames, name + ' resources not bundled')
    for config_id in objects[target['buildConfigurationList']]['buildConfigurations']:
        settings = objects[config_id]['buildSettings']
        require(settings.get('ASSETCATALOG_COMPILER_APPICON_NAME') == 'AppIcon', name + ' icon selection')
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
print('PASS: icon format and wiring, API manifests, Watch embedding, free access, on-device privacy.')
print('Still required: signed archive validation, device testing, App Store Connect metadata.')
