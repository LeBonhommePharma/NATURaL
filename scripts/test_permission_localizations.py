#!/usr/bin/env python3
"""Regression tests for permission resource validation (Apple plutil required)."""
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest

from permission_localizations import validate_permission_localizations


@unittest.skipUnless(sys.platform == 'darwin' and shutil.which('plutil'), 'Requires Apple plutil')
class PermissionLocalizationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        app = self.root / 'Bonhomme'
        app.mkdir()
        (app / 'Info.plist').write_bytes(plistlib.dumps({
            'CFBundleLocalizations': ['en', 'fr'],
            'NSCameraUsageDescription': 'Optional camera guidance on this device.',
        }))
        self.paths = {}
        for lang, text in [('en', 'Optional camera guidance on this device.'),
                           ('fr', 'Guide facultatif avec la caméra sur cet appareil.')]:
            folder = app / (lang + '.lproj')
            folder.mkdir()
            self.paths[lang] = folder / 'InfoPlist.strings'
            self.paths[lang].write_text('"NSCameraUsageDescription" = ' + json.dumps(text) + ';\n')
        self.project = {'rootObject': 'project', 'objects': {
            'project': {'isa': 'PBXProject', 'knownRegions': ['en', 'fr']},
            'app': {'isa': 'PBXNativeTarget', 'name': 'Bonhomme',
                    'productType': 'com.apple.product-type.application',
                    'buildConfigurationList': 'configs', 'buildPhases': ['resources']},
            'configs': {'isa': 'XCConfigurationList', 'buildConfigurations': ['release']},
            'release': {'isa': 'XCBuildConfiguration',
                        'buildSettings': {'INFOPLIST_FILE': 'Bonhomme/Info.plist'}},
            'resources': {'isa': 'PBXResourcesBuildPhase', 'files': ['build']},
            'build': {'isa': 'PBXBuildFile', 'fileRef': 'variant'},
            'group': {'isa': 'PBXGroup', 'children': ['variant'],
                      'sourceTree': '<group>', 'path': 'Bonhomme'},
            'variant': {'isa': 'PBXVariantGroup', 'name': 'InfoPlist.strings',
                        'children': ['en', 'fr'], 'sourceTree': '<group>'},
            **{lang: {'isa': 'PBXFileReference', 'name': lang,
                      'path': lang + '.lproj/InfoPlist.strings', 'sourceTree': '<group>'}
               for lang in ['en', 'fr']},
        }}

    def validate(self):
        return validate_permission_localizations(self.root, self.project)

    def testCompleteLocalizedResourcesPass(self):
        self.assertEqual(self.validate(), (2, 2))

    def testMissingPermissionKeyFails(self):
        self.paths['fr'].write_text('"OtherKey" = "Texte";\n')
        with self.assertRaisesRegex(ValueError, 'missing or unexpected'):
            self.validate()

    def testMalformedStringsFailAppleParser(self):
        self.paths['fr'].write_text('"NSCameraUsageDescription" = "unterminated;\n')
        with self.assertRaises(subprocess.CalledProcessError):
            self.validate()

    def testDuplicateKeysFailInsteadOfSilentlyOverriding(self):
        original = self.paths['fr'].read_text()
        self.paths['fr'].write_text(original + original)
        with self.assertRaisesRegex(ValueError, 'duplicate keys'):
            self.validate()

    def testMissingTargetResourceMembershipFails(self):
        self.project['objects']['resources']['files'] = []
        with self.assertRaisesRegex(ValueError, 'bundle exactly one'):
            self.validate()

    def testWrongPlatformResourceFails(self):
        self.project['objects']['fr']['path'] = '../BonhommeWatch/fr.lproj/InfoPlist.strings'
        with self.assertRaisesRegex(ValueError, 'wrong localized resource path'):
            self.validate()

    def testUntranslatedEnglishFails(self):
        self.paths['fr'].write_text(self.paths['en'].read_text())
        with self.assertRaisesRegex(ValueError, 'untranslated English'):
            self.validate()


if __name__ == '__main__':
    unittest.main()
