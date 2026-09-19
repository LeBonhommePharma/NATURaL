#!/usr/bin/env python3
"""Negative packaging regressions using synthetic fixtures (not signing evidence)."""
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch
import subprocess
import sys

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('archive_validator', Path(__file__).with_name('validate-archive.py'))
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class ArchiveValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.archive = Path(self.temp.name) / 'Example.xcarchive'
        self.app = self.archive / 'Products/Applications/Bonhomme.app'
        self.put(self.archive / 'Info.plist', {'ApplicationProperties': {
            'ApplicationPath': 'Applications/Bonhomme.app',
            'CFBundleIdentifier': 'com.natural.Bonhomme', 'CFBundleVersion': '42'}})
        self.bundle(self.app, 'com.natural.Bonhomme', 'iPhoneOS', UIDeviceFamily=[1, 2])
        (self.app / 'Acknowledgements.txt').write_bytes((Path(__file__).resolve().parents[1] / 'Bonhomme/Resources/Acknowledgements.txt').read_bytes())
        self.watch = self.app / 'Watch/BonhommeWatch.app'
        self.bundle(self.watch, 'com.natural.Bonhomme.watchkitapp', 'WatchOS', WKApplication=True,
                    WKCompanionAppBundleIdentifier='com.natural.Bonhomme')
        for name, suffix in [('NATURaLWidgets', 'Widgets'), ('NATURaLLiveActivity', 'LiveActivity')]:
            self.bundle(self.app / 'PlugIns' / (name + '.appex'), 'com.natural.Bonhomme.' + suffix, 'iPhoneOS')

    def put(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(plistlib.dumps(value))

    def bundle(self, path, identifier, platform, **extra):
        self.put(path / 'Info.plist', dict(CFBundleIdentifier=identifier, CFBundleVersion='42',
                 CFBundleShortVersionString='1.0', CFBundleExecutable=path.stem,
                 CFBundleSupportedPlatforms=[platform], **extra))
        (path / path.stem).touch()
        self.put(path / 'PrivacyInfo.xcprivacy', {'NSPrivacyTracking': False, 'NSPrivacyCollectedDataTypes': []})
        binary = self.archive / 'dSYMs' / (path.name + '.dSYM') / 'Contents/Resources/DWARF' / path.stem
        binary.parent.mkdir(parents=True)
        binary.touch()

    def mutate(self, path, key, value):
        data = plistlib.loads(path.read_bytes())
        data[key] = value
        self.put(path, data)

    def validate(self):
        return validator.validate_structure(self.archive, 'ios', '42')

    def test_complete_structure(self):
        self.assertEqual(len(self.validate()), 4)

    def test_watch_missing(self):
        self.watch.rename(self.app / 'MisplacedWatch.app')
        with self.assertRaisesRegex(ValueError, 'embedded Watch'):
            self.validate()

    def test_misplaced_extension(self):
        path = self.app / 'PlugIns/NATURaLWidgets.appex'
        path.rename(self.app / path.name)
        with self.assertRaisesRegex(ValueError, 'Missing plist'):
            self.validate()

    def test_wrong_extension_build(self):
        self.mutate(self.app / 'PlugIns/NATURaLWidgets.appex/Info.plist', 'CFBundleVersion', '1')
        with self.assertRaisesRegex(ValueError, 'build number mismatch'):
            self.validate()

    def test_simulator_product_rejected(self):
        self.mutate(self.app / 'Info.plist', 'CFBundleSupportedPlatforms', ['iPhoneSimulator'])
        with self.assertRaisesRegex(ValueError, 'wrong platform'):
            self.validate()

    def test_missing_ipad_support(self):
        self.mutate(self.app / 'Info.plist', 'UIDeviceFamily', [1])
        with self.assertRaisesRegex(ValueError, 'both iPhone and iPad'):
            self.validate()

    def test_missing_symbols(self):
        next((self.archive / 'dSYMs').rglob('DWARF/BonhommeWatch')).unlink()
        with self.assertRaisesRegex(ValueError, 'crash symbols missing'):
            self.validate()

    def test_missing_manifest(self):
        (self.watch / 'PrivacyInfo.xcprivacy').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing plist'):
            self.validate()

    def test_missing_acknowledgements(self):
        (self.app / 'Acknowledgements.txt').unlink()
        with self.assertRaisesRegex(ValueError, 'acknowledgements missing'):
            self.validate()

    def test_truncated_acknowledgements(self):
        path = self.app / 'Acknowledgements.txt'
        path.write_bytes(path.read_bytes()[:500])
        with self.assertRaisesRegex(ValueError, 'Complete pinned license missing'):
            self.validate()

    def test_signing_team_mismatch(self):
        result = subprocess.CompletedProcess([], 0, stdout='', stderr='TeamIdentifier=WRONGTEAM\n')
        with patch.object(validator.subprocess, 'run', return_value=result):
            with self.assertRaisesRegex(ValueError, 'wrong or absent signing team'):
                validator.validate_signatures([self.app], 'ios')

    def test_invalid_signature(self):
        with patch.object(validator.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'codesign')):
            with self.assertRaises(subprocess.CalledProcessError):
                validator.validate_signatures([self.app], 'ios')

    def test_native_mac_structure(self):
        archive = Path(self.temp.name) / 'Mac.xcarchive'
        app = archive / 'Products/Applications/BonhommeMac.app'
        self.put(archive / 'Info.plist', {'ApplicationProperties': {
            'ApplicationPath': 'Applications/BonhommeMac.app',
            'CFBundleIdentifier': 'com.natural.Bonhomme.mac', 'CFBundleVersion': '42'}})
        self.put(app / 'Contents/Info.plist', dict(CFBundleIdentifier='com.natural.Bonhomme.mac',
                 CFBundleVersion='42', CFBundleShortVersionString='1.0', CFBundleExecutable='BonhommeMac',
                 CFBundleSupportedPlatforms=['MacOSX']))
        self.put(app / 'Contents/Resources/PrivacyInfo.xcprivacy', {'NSPrivacyTracking': False, 'NSPrivacyCollectedDataTypes': []})
        for binary in [app / 'Contents/MacOS/BonhommeMac', archive / 'dSYMs/BonhommeMac.app.dSYM/Contents/Resources/DWARF/BonhommeMac']:
            binary.parent.mkdir(parents=True)
            binary.touch()
        self.assertEqual(validator.validate_structure(archive, 'macos', '42'), [app])

    def test_mac_signed_sandbox_missing(self):
        responses = [subprocess.CompletedProcess([], 0),
                     subprocess.CompletedProcess([], 0, stderr='TeamIdentifier=ZJLX84G8QV\n'),
                     subprocess.CompletedProcess([], 0, stdout=plistlib.dumps({}))]
        with patch.object(validator.subprocess, 'run', side_effect=responses):
            with self.assertRaisesRegex(ValueError, 'lacks App Sandbox'):
                validator.validate_signatures([self.app], 'macos')

    def tv_archive(self):
        self.archive = Path(self.temp.name) / 'TV.xcarchive'
        app = self.archive / 'Products/Applications/BonhommeTV.app'
        self.put(self.archive / 'Info.plist', {'ApplicationProperties': {
            'ApplicationPath': 'Applications/BonhommeTV.app',
            'CFBundleIdentifier': 'com.natural.BonhommeTV', 'CFBundleVersion': '42'}})
        self.bundle(app, 'com.natural.BonhommeTV', 'AppleTVOS', UIDeviceFamily=[3],
                    NSBonjourServices=['_bonhomme._tcp'],
                    NSLocalNetworkUsageDescription='Share your session with this television.')
        (app / 'Assets.car').touch()
        return app

    def test_tvos_structure(self):
        app = self.tv_archive()
        self.assertEqual(validator.validate_structure(self.archive, 'tvos', '42'), [app])

    def test_tvos_simulator_archive_rejected(self):
        app = self.tv_archive()
        self.mutate(app / 'Info.plist', 'CFBundleSupportedPlatforms', ['AppleTVSimulator'])
        with self.assertRaisesRegex(ValueError, 'wrong platform'):
            validator.validate_structure(self.archive, 'tvos')

    def test_tvos_wrong_device_family_rejected(self):
        app = self.tv_archive()
        self.mutate(app / 'Info.plist', 'UIDeviceFamily', [1, 2])
        with self.assertRaisesRegex(ValueError, 'target Apple TV'):
            validator.validate_structure(self.archive, 'tvos')

    def test_tvos_missing_asset_catalog_rejected(self):
        app = self.tv_archive()
        (app / 'Assets.car').unlink()
        with self.assertRaisesRegex(ValueError, 'asset catalog missing'):
            validator.validate_structure(self.archive, 'tvos')

    def test_tvos_missing_bonjour_declaration_rejected(self):
        app = self.tv_archive()
        self.mutate(app / 'Info.plist', 'NSBonjourServices', [])
        with self.assertRaisesRegex(ValueError, 'Bonjour service'):
            validator.validate_structure(self.archive, 'tvos')


if __name__ == '__main__':
    unittest.main()
