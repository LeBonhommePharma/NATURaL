#!/usr/bin/env python3
"""Coverage-inventory parser and bundled-resource validation regressions."""
import json
from pathlib import Path
import tempfile
import unittest
from localization_inventory import LANGUAGES, RESOURCE_NAMES, load_catalog, scan_source

class LocalizationInventoryTests(unittest.TestCase):
    def testIgnoresCommentsAndSeparatesInterpolationsFromLiteralEscapes(self):
        source = r'''
        // LocalizedString(en: "Not real", fr: "Non")
        /* LocalizedString(en: "Also not real", fr: "Non") */
        let a = LocalizedString(en: "Pose guide", fr: "Guide", it: "")
        let b = LocalizedString(en: "Step \(number)", fr: "Étape \(number)")
        let c = LocalizedString(en: "Literal \\(number)", fr: "Littéral")
        let d = LocalizedString(en: "Nested \(format("name"))", fr: "Valeur")
        '''
        entries, _ = scan_source(source)
        self.assertEqual([x['kind'] for x in entries], ['static', 'dynamic', 'static', 'dynamic'])
        self.assertEqual(entries[0]['inline_languages'], ['en', 'fr'])
        self.assertEqual(entries[2]['english'], r'Literal \(number)')

    def testArraysHelpersExpressionsAndNativeCandidatesRemainDistinct(self):
        source = '''
        func copy(_ en: String, _ fr: String) -> String { LocalizedString(en: en, fr: fr).localized }
        Text("Native candidate")
        copy("Cancel", "Annuler")
        LocalizedStringArray(en: ["First", "Second"], fr: [], es: ["Primero", "Segundo"])
        LocalizedString(en: flag ? "One" : "Two", fr: computed)
        '''
        entries, native = scan_source(source)
        self.assertEqual(len(native), 1)
        self.assertEqual(native[0]['english'], 'Native candidate')
        strings = [x for x in entries if x['kind'] == 'static']
        self.assertEqual([x['english'] for x in strings], ['Cancel', 'First', 'Second'])
        self.assertEqual(strings[1]['inline_languages'], ['en', 'es'])
        self.assertEqual(sum(x['kind'] == 'expression' for x in entries), 2)

    def testRawAndUnicodeStrings(self):
        entries, _ = scan_source(r'LocalizedString(en: #"Literal \(value)"#, fr: "A\u{00e9}")')
        self.assertEqual(entries[0]['kind'], 'static')
        self.assertEqual(entries[0]['english'], r'Literal \(value)')

    def testMultilineAndDynamicTranslationsAreNotCountedAsVerifiedStatic(self):
        source = '\n'.join(['LocalizedString(en: """', '    Multiline', '    """, fr: "Texte")',
                             'LocalizedString(en: "Static", fr: "\\(computed)")'])
        entries, _ = scan_source(source)
        self.assertEqual(entries[0]['kind'], 'expression')
        self.assertEqual(entries[1]['kind'], 'static')
        self.assertIn('fr', entries[1]['unresolved_languages'])
        self.assertNotIn('fr', entries[1]['inline_languages'])

    def testCatalogRequiresAllLanguagesAndRejectsDuplicateKeys(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in RESOURCE_NAMES:
                (root / f'{name}.json').write_text('{}')
            target = root / f'{RESOURCE_NAMES[0]}.json'
            target.write_text(json.dumps({'Example': dict.fromkeys(LANGUAGES, 'Example')}))
            self.assertEqual(len(load_catalog(root)), 1)
            target.write_text('{"Example": {}, "Example": {}}')
            with self.assertRaisesRegex(ValueError, 'duplicate'):
                load_catalog(root)
            target.write_text(json.dumps({'Example': {'en': 'Example'}}))
            with self.assertRaisesRegex(ValueError, 'eleven'):
                load_catalog(root)

    def testRealCatalogIsComplete(self):
        self.assertIn('Pose guide', load_catalog())

if __name__ == '__main__': unittest.main()
