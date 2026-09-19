#!/usr/bin/env python3
"""Conservative source inventory; static lookup coverage is not linguistic QA.

Counts LocalizedString/Array and verified local copy(en, fr) helpers. Separates
interpolations/expressions and native SwiftUI literal candidates, which this
supplemental runtime does not translate. Does not scan tests or dependencies.
"""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = 'en fr es ja zh ko ru de ar it pt'.split()
RESOURCE_ROOT = ROOT / 'BonhommeCore/Sources/BonhommeCore/Resources'
RESOURCE_NAMES = ['SupplementalNavigation', 'SupplementalGuidance', 'SupplementalTV']
SOURCE_ROOTS = ['Bonhomme', 'BonhommeWatch', 'BonhommeTV', 'BonhommeVision',
                'BonhommeMac', 'NATURaLWidgets', 'NATURaLLiveActivity',
                'BonhommeCore/Sources/BonhommeCore']


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'duplicate JSON key: {key}')
        result[key] = value
    return result


def load_catalog(root=RESOURCE_ROOT):
    result = {}
    for name in RESOURCE_NAMES:
        entries = json.loads((root / f'{name}.json').read_text(), object_pairs_hook=unique_object)
        if not isinstance(entries, dict):
            raise ValueError(f'{name}: expected object')
        for english, translations in entries.items():
            if not english or english in result:
                raise ValueError(f'{name}: empty/duplicate English key: {english}')
            if not isinstance(translations, dict) or set(translations) != set(LANGUAGES):
                raise ValueError(f'{name}: all eleven language fields required: {english}')
            if translations['en'] != english:
                raise ValueError(f'{name}: English key must equal en value: {english}')
            if any(not isinstance(v, str) or not v.strip() or '\\(' in v for v in translations.values()):
                raise ValueError(f'{name}: empty/nonliteral translation: {english}')
            result[english] = translations
    return result


# Token tuple: kind, decoded value, source offset, has interpolation.
def tokens(source):
    out = []
    i = 0
    n = len(source)

    def string_at(start):
        q = start
        while q < n and source[q] == '#': q += 1
        hashes = source[start:q]
        triple = source.startswith('"""', q)
        delimiter = '"""' if triple else '"'
        end = delimiter + hashes
        escape = '\\' + hashes
        j = q + len(delimiter)
        text = ''
        dynamic = False
        while j < n:
            if source.startswith(end, j):
                return ('multiline' if triple else 'string', text, start, dynamic), j + len(end)
            if source.startswith(escape, j):
                k = j + len(escape)
                if k < n and source[k] == '(':
                    dynamic = True
                    # Balanced interpolation can contain its own nested strings.
                    depth = 1
                    k += 1
                    while k < n and depth:
                        if source[k] == '"' or re.match(r'#+"', source[k:k+12]):
                            _, k = string_at(k)
                            continue
                        if source[k] == '(': depth += 1
                        elif source[k] == ')': depth -= 1
                        k += 1
                    text += '<interpolation>'
                    j = k
                    continue
                if k < n and source[k] == 'u' and source[k+1:k+2] == '{':
                    finish = source.find('}', k+2)
                    if finish < 0: raise ValueError('unterminated Unicode escape')
                    text += chr(int(source[k+2:finish], 16)); j = finish + 1; continue
                if k < n:
                    text += {'n': '\n', 'r': '\r', 't': '\t', '0': '\0'}.get(source[k], source[k])
                    j = k + 1; continue
            text += source[j]; j += 1
        raise ValueError(f'unterminated string at {start}')

    while i < n:
        if source[i].isspace(): i += 1; continue
        if source.startswith('//', i):
            pos = source.find('\n', i); i = n if pos < 0 else pos; continue
        if source.startswith('/*', i):
            depth = 1; i += 2
            while i < n and depth:
                if source.startswith('/*', i): depth += 1; i += 2
                elif source.startswith('*/', i): depth -= 1; i += 2
                else: i += 1
            continue
        if source[i] == '"' or re.match(r'#+"', source[i:i+12]):
            token, i = string_at(i); out.append(token); continue
        match = re.match(r'[A-Za-z_][A-Za-z_0-9]*', source[i:])
        if match:
            value = match.group(); out.append(('id', value, i, False)); i += len(value); continue
        out.append(('punct', source[i], i, False)); i += 1
    return out


def split_arguments(values):
    result, current, depth = [], [], 0
    for token in values:
        symbol = token[1] if token[0] == 'punct' else ''
        if symbol == ',' and depth == 0:
            result.append(current); current = []; continue
        current.append(token)
        if symbol in ('(', '[', '{'): depth += 1
        elif symbol in (')', ']', '}'): depth -= 1
    if current: result.append(current)
    return result


def literal(values):
    return values[0] if len(values) == 1 and values[0][0] == 'string' else None


def scan_source(source, path='<source>'):
    values = tokens(source)
    entries, other = [], []
    copy_helper = bool(re.search(r'LocalizedString\(\s*en:\s*en\s*,\s*fr:\s*fr\s*\)', source))
    for i, token in enumerate(values[:-1]):
        name = token[1]
        if token[0] != 'id' or values[i+1][1] != '(': continue
        if i and values[i-1][1] == 'func': continue
        accepted = name in ('LocalizedString', 'LocalizedStringArray') or (name == 'copy' and copy_helper)
        native = name in ('Text', 'Label', 'Button', 'navigationTitle', 'Section', 'Toggle', 'Picker')
        if not accepted and not native: continue
        depth, end = 1, i+2
        while end < len(values) and depth:
            if values[end][0] == 'punct':
                if values[end][1] == '(': depth += 1
                elif values[end][1] == ')': depth -= 1
            end += 1
        if depth: raise ValueError(f'{path}: unterminated call')
        args = split_arguments(values[i+2:end-1])
        if not args: continue
        location = {'source': path, 'line': source.count('\n', 0, token[2])+1, 'call': name}
        if not accepted:
            english = literal(args[0])
            if english:
                other.append(location | {'kind': 'dynamic' if english[3] else 'static', 'english': english[1]})
            continue
        fields = dict(zip(['en', 'fr'], args)) if name == 'copy' else {
            arg[0][1]: arg[2:] for arg in args if len(arg) >= 2 and arg[1][1] == ':'
        }
        english = fields.get('en', [])
        is_array = name == 'LocalizedStringArray'
        array_elements = lambda items: split_arguments(items[1:-1]) if items and items[0][1] == '[' and items[-1][1] == ']' else None
        segments = array_elements(english) if is_array else [english]
        if segments is None: segments = [english]
        explicit, unresolved = [], []
        for lang in LANGUAGES:
            value = fields.get(lang, [])
            if not value: continue
            if is_array:
                arr = array_elements(value)
                if arr:
                    explicit.append(lang)
                elif arr is None: unresolved.append(lang)
            else:
                string = literal(value)
                if string is None: unresolved.append(lang)
                elif string[3]: unresolved.append(lang)
                elif string[1]: explicit.append(lang)
        for segment in segments:
            english = literal(segment)
            kind = 'expression' if english is None else ('dynamic' if english[3] else 'static')
            entries.append(location | {'kind': kind, 'english': english[1] if english else None,
                                       'inline_languages': explicit, 'unresolved_languages': unresolved})
    return entries, other


def inventory(root=ROOT):
    catalog = load_catalog(root / RESOURCE_ROOT.relative_to(ROOT))
    entries, native = [], []
    for directory in SOURCE_ROOTS:
        for path in sorted((root / directory).rglob('*.swift')):
            found, candidates = scan_source(path.read_text(), str(path.relative_to(root)))
            entries += found; native += candidates
    coverage = {lang: Counter() for lang in LANGUAGES if lang != 'en'}
    for entry in entries:
        if entry['kind'] != 'static' or not entry['english']: continue
        entry['remaining_languages'] = []
        for lang, counts in coverage.items():
            if lang in entry['inline_languages']: counts['inline'] += 1
            elif lang in entry['unresolved_languages']: counts['expression_not_assessed'] += 1
            elif lang in catalog.get(entry['english'], {}): counts['supplemental'] += 1
            else:
                counts['english_fallback'] += 1; entry['remaining_languages'].append(lang)
    return {'scope': SOURCE_ROOTS, 'limitations': [
        'Counts English string entries at source call sites (arrays expanded), not runtime reachability or unique screens.',
        'Dynamic interpolation and nonliteral expressions, including multiline literals not decoded by this scanner, are reported separately.',
        'Nonempty explicit arrays are preserved wholesale; translation alignment and language quality require review.',
        'Native SwiftUI literal candidates do not use the supplemental lookup; framework/localization resources may resolve them separately.',
        'Only copy helpers forwarding directly to LocalizedString(en: en, fr: fr) are included.',
        'Interpolated English text receives supplemental lookup only if its complete runtime value exactly matches a catalog key.',
    ], 'supplemental_keys': len(catalog), 'supplemental_values': len(catalog)*len(LANGUAGES),
        'calls_by_kind': dict(Counter(entry['kind'] for entry in entries)),
        'native_swiftui_candidates': len(native),
        'coverage_by_language': {lang: dict(counts) for lang, counts in coverage.items()},
        'entries': entries, 'native_candidates': native}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--check-resources', action='store_true')
    args = parser.parse_args()
    if args.check_resources:
        catalog = load_catalog()
        print(f'PASS: {len(catalog)} exact English keys, {len(catalog)*len(LANGUAGES)} nonempty language values')
        return
    report = inventory()
    if args.output: args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ('entries', 'native_candidates')}, ensure_ascii=False, indent=2))

if __name__ == '__main__': main()
