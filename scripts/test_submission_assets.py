#!/usr/bin/env python3
"""Regression checks for submission asset failures; no Xcode or network required."""
import json
from pathlib import Path
import shutil
import struct
import sys
import tempfile
import unittest
import zlib

sys.dont_write_bytecode = True
from submission_assets import ROOT, validate_acknowledgements, validate_mac_icon_catalog, validate_tv_brand_catalog, _validate_tv_foreground_alpha


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


class TVBrandTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.catalog = Path(self.temp.name) / 'AppIcon.brandassets'
        shutil.copytree(ROOT / 'BonhommeTV/Assets.xcassets/AppIcon.brandassets', self.catalog)
        self.stack = self.catalog / 'App Icon - Small.imagestack'
        self.foreground = self.stack / 'Foreground.imagestacklayer/Content.imageset'

    def rewrite(self, path, transform):
        value = json.loads(path.read_text())
        transform(value)
        path.write_text(json.dumps(value))

    def test_current_layered_catalog(self):
        validate_tv_brand_catalog(self.catalog)

    def test_missing_top_shelf(self):
        self.rewrite(self.catalog / 'Contents.json', lambda v: v['assets'].pop())
        with self.assertRaisesRegex(ValueError, 'standard/wide'):
            validate_tv_brand_catalog(self.catalog)

    def test_missing_retina_layer(self):
        self.rewrite(self.foreground / 'Contents.json', lambda v: v['images'].pop())
        with self.assertRaisesRegex(ValueError, 'image scales'):
            validate_tv_brand_catalog(self.catalog)

    def test_duplicate_flat_catalog(self):
        self.catalog.with_suffix('.appiconset').mkdir()
        with self.assertRaisesRegex(ValueError, 'Duplicate flat'):
            validate_tv_brand_catalog(self.catalog)

    def test_reversed_layers(self):
        self.rewrite(self.stack / 'Contents.json', lambda v: v['layers'].reverse())
        with self.assertRaisesRegex(ValueError, 'RGBA foreground'):
            validate_tv_brand_catalog(self.catalog)

    def test_duplicate_layers(self):
        self.rewrite(self.stack / 'Contents.json', lambda v: v['layers'].__setitem__(1, v['layers'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate layers'):
            validate_tv_brand_catalog(self.catalog)

    def test_wrong_layer_pixel_size(self):
        path = self.foreground / 'image@1x.png'
        data = bytearray(path.read_bytes())
        data[16:24] = struct.pack('>II', 240, 400)
        path.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'pixel dimensions'):
            validate_tv_brand_catalog(self.catalog)

    def test_external_path_reference(self):
        self.rewrite(self.stack / 'Contents.json', lambda v: v['layers'][0].update(filename='../Other.imagestacklayer'))
        with self.assertRaisesRegex(ValueError, 'invalid local'):
            validate_tv_brand_catalog(self.catalog)

    @staticmethod
    def alpha_fixture(alpha_at):
        # Synthetic test pixels only; no production artwork is changed.
        def chunk(kind, payload):
            return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload))
        raw = b''.join(b'\0' + b''.join(bytes((255, 100, 0, alpha_at(x, y))) for x in range(20)) for y in range(20))
        return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 20, 20, 8, 6, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))

    def test_transparent_margin_with_visible_art(self):
        data = self.alpha_fixture(lambda x, y: 255 if 5 <= x < 15 and 5 <= y < 15 else 0)
        _validate_tv_foreground_alpha(data, 20, 20, 'fixture')

    def test_empty_foreground(self):
        with self.assertRaisesRegex(ValueError, 'empty or negligible'):
            _validate_tv_foreground_alpha(self.alpha_fixture(lambda x, y: 0), 20, 20, 'fixture')

    def test_safe_zone_violation(self):
        with self.assertRaisesRegex(ValueError, 'transparent safe zone'):
            _validate_tv_foreground_alpha(self.alpha_fixture(lambda x, y: 255), 20, 20, 'fixture')


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
