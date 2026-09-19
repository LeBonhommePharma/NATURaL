#!/usr/bin/env python3
"""Regression checks for submission asset failures; no Xcode or network required."""
import json
from pathlib import Path
import shutil
import struct
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
from submission_assets import ROOT, validate_acknowledgements, validate_mac_icon_catalog


class MacIconTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.catalog = Path(self.temp.name) / 'AppIcon.appiconset'
        shutil.copytree(ROOT / 'BonhommeMac/Assets.xcassets/AppIcon.appiconset', self.catalog)

    def rewrite_catalog(self, transform):
        path = self.catalog / 'Contents.json'
        value = json.loads(path.read_text())
        transform(value)
        path.write_text(json.dumps(value))

    def test_complete_current_catalog(self):
        validate_mac_icon_catalog(self.catalog)

    def test_missing_slot(self):
        self.rewrite_catalog(lambda value: value['images'].pop())
        with self.assertRaisesRegex(ValueError, 'all ten'):
            validate_mac_icon_catalog(self.catalog)

    def test_duplicate_slot(self):
        self.rewrite_catalog(lambda value: value['images'].append(value['images'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicates'):
            validate_mac_icon_catalog(self.catalog)

    def test_wrong_actual_pixel_dimensions(self):
        path = self.catalog / 'icon-1024.png'
        data = bytearray(path.read_bytes())
        data[16:24] = struct.pack('>II', 512, 512)
        path.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'expected 1024x1024'):
            validate_mac_icon_catalog(self.catalog)

    def test_wrong_idiom(self):
        self.rewrite_catalog(lambda value: value['images'][0].update(idiom='ios'))
        with self.assertRaisesRegex(ValueError, 'wrong idiom'):
            validate_mac_icon_catalog(self.catalog)


class LicenseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.licenses = self.root / 'Docs/AppStore/licenses'
        shutil.copytree(ROOT / 'Docs/AppStore/licenses', self.licenses)
        self.resolved = self.root / 'NATURaL.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
        self.resolved.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / self.resolved.relative_to(self.root), self.resolved)
        self.ack = self.root / 'Acknowledgements.txt'
        shutil.copyfile(ROOT / 'Bonhomme/Resources/Acknowledgements.txt', self.ack)

    def test_complete_current_notices(self):
        validate_acknowledgements(self.ack, self.root)

    def test_stale_revision(self):
        value = json.loads(self.resolved.read_text())
        value['pins'][0]['state']['revision'] = 'new-revision'
        self.resolved.write_text(json.dumps(value))
        with self.assertRaisesRegex(ValueError, 'Stale license provenance'):
            validate_acknowledgements(self.ack, self.root)

    def test_tampered_license(self):
        path = self.licenses / 'CareKit-LICENSE.txt'
        path.write_bytes(path.read_bytes() + b'changed')
        with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
            validate_acknowledgements(self.ack, self.root)

    def test_missing_attribution_for_identical_apache_text(self):
        self.ack.write_bytes(self.ack.read_bytes().replace(b'swift-collections 1.4.1\n', b''))
        with self.assertRaisesRegex(ValueError, 'Missing dependency/version attribution'):
            validate_acknowledgements(self.ack, self.root)


if __name__ == '__main__':
    unittest.main()
