#!/usr/bin/env python3
"""Validate localized Apple permission strings and Xcode resource membership.

Uses Apple's plutil parser on macOS. Checks source wiring, not a built bundle or
the linguistic quality of translations. Run directly or from validate-submission.
"""
from pathlib import Path
import json
import plistlib
import re
import subprocess


def _require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_permission_localizations(root, project=None):
    root = Path(root)
    if project is None:
        project = json.loads(subprocess.check_output([
            'plutil', '-convert', 'json', '-o', '-',
            str(root / 'NATURaL.xcodeproj/project.pbxproj'),
        ]))
    objects = project['objects']
    parents = {
        child: key
        for key, value in objects.items()
        if value.get('isa') in ('PBXGroup', 'PBXVariantGroup')
        for child in value.get('children', [])
    }

    def resolved_path(ref):
        value = objects[ref]
        path = Path(value.get('path', ''))
        if ref in parents and value.get('sourceTree') == '<group>':
            return resolved_path(parents[ref]) / path
        return path

    primary = plistlib.loads((root / 'Bonhomme/Info.plist').read_bytes())
    languages = primary.get('CFBundleLocalizations', [])
    _require(languages and len(languages) == len(set(languages)),
             'iOS must declare a nonempty, unique list of supported languages')
    known = objects[project['rootObject']].get('knownRegions', [])
    _require(set(languages) <= set(known), 'Xcode knownRegions misses app languages')
    file_count = string_count = 0
    for target in objects.values():
        if target.get('isa') != 'PBXNativeTarget':
            continue
        if target.get('productType') not in (
            'com.apple.product-type.application',
            'com.apple.product-type.application.watchapp2',
            'com.apple.product-type.app-extension',
        ):
            continue
        configs = [objects[c]['buildSettings'] for c in
                   objects[target['buildConfigurationList']]['buildConfigurations']]
        info_paths = {c.get('INFOPLIST_FILE') for c in configs}
        _require(None not in info_paths, target['name'] + ': missing Info.plist setting')
        for info_path in info_paths:
            info_path = Path(info_path)
            info = plistlib.loads((root / info_path).read_bytes())
            keys = {k for k in info if k.startswith('NS') and k.endswith('UsageDescription')}
            if not keys:
                continue
            if 'CFBundleLocalizations' in info:
                _require(set(info['CFBundleLocalizations']) == set(languages),
                         target['name'] + ': declared languages differ from iOS')
            resources = [objects[objects[f]['fileRef']]
                         for p in target['buildPhases']
                         if objects[p]['isa'] == 'PBXResourcesBuildPhase'
                         for f in objects[p]['files']]
            groups = [r for r in resources
                      if r.get('name', r.get('path')) == 'InfoPlist.strings']
            _require(len(groups) == 1 and groups[0]['isa'] == 'PBXVariantGroup',
                     target['name'] + ': bundle exactly one InfoPlist.strings variant group')
            refs = groups[0]['children']
            _require(len(refs) == len(languages), target['name'] + ': wrong localization count')
            _require({objects[r].get('name') for r in refs} == set(languages),
                     target['name'] + ': missing or duplicate localization references')
            for ref in refs:
                language = objects[ref]['name']
                relative = resolved_path(ref)
                expected = info_path.parent / (language + '.lproj') / 'InfoPlist.strings'
                _require(relative == expected, target['name'] + ': wrong localized resource path: ' + str(relative))
                path = root / relative
                source = path.read_text(encoding='utf-8')
                declared_keys = re.findall(r'^\s*"(NS[^"\n]+UsageDescription)"\s*=', source, re.MULTILINE)
                _require(len(declared_keys) == len(set(declared_keys)), str(relative) + ': duplicate keys')
                values = json.loads(subprocess.check_output([
                    'plutil', '-convert', 'json', '-o', '-', str(path),
                ], stderr=subprocess.STDOUT))
                _require(set(values) == keys, str(relative) + ': missing or unexpected permission keys')
                for key, text in values.items():
                    _require(isinstance(text, str) and text.strip(), str(relative) + ': empty ' + key)
                    _require(len(text.encode('utf-8')) < 4000, str(relative) + ': oversized ' + key)
                    if language == 'en':
                        _require(text == info[key], str(relative) + ': English differs from Info.plist fallback: ' + key)
                    else:
                        _require(text != info[key], str(relative) + ': untranslated English: ' + key)
                file_count += 1
                string_count += len(values)
    _require(file_count > 0, 'No localized permission resources found')
    return file_count, string_count


if __name__ == '__main__':
    try:
        files, strings = validate_permission_localizations(Path(__file__).resolve().parents[1])
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit('FAIL: ' + str(error))
    print(f'PASS: {strings} permission strings in {files} bundled localization files')
