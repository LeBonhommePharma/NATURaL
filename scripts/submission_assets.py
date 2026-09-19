"""Shared offline asset checks; these do not replace SDK compilation or store validation."""
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
# Inspected graph: Bonhomme -> CareKitStore -> AsyncAlgorithms -> Collections.
# FHIRModels is resolved by CareKitFHIR, which the app does not link.
IOS_LINKED_PACKAGES = ('CareKit', 'swift-async-algorithms', 'swift-collections')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_acknowledgements(path, root=ROOT):
    require(path.is_file(), f'Bundled dependency acknowledgements missing: {path}')
    contents = path.read_bytes()
    directory = root / 'Docs/AppStore/licenses'
    manifest = json.loads((directory / 'manifest.json').read_text())
    pins = json.loads((root / 'NATURaL.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved').read_text())['pins']
    entries = {entry['package'].lower(): entry for entry in manifest}
    require(len(entries) == len(manifest), 'Duplicate package in license manifest')
    require(set(entries) == {pin['identity'] for pin in pins}, 'Package resolution changed: refresh license manifest and review linked dependency graph')
    for pin in pins:
        entry = entries[pin['identity']]
        require(all(entry[key] == pin['state'][key] for key in ('revision', 'version')), f"Stale license provenance: {entry['package']}")
        license_bytes = (directory / entry['license_file']).read_bytes()
        require(hashlib.sha256(license_bytes).hexdigest() == entry['sha256'], f"License checksum mismatch: {entry['package']}")
        if entry['package'] in IOS_LINKED_PACKAGES:
            require(f"{entry['package']} {entry['version']}\n".encode() in contents, f"Missing dependency/version attribution: {entry['package']}")
            require(license_bytes in contents, f"Complete pinned license missing from acknowledgements: {entry['package']}")
    require(all(package.lower() in entries for package in IOS_LINKED_PACKAGES), 'Linked dependency missing from license manifest')


def validate_mac_icon_catalog(iconset):
    entries = json.loads((iconset / 'Contents.json').read_text())['images']
    expected = {(f'{size}x{size}', f'{scale}x') for size in (16, 32, 128, 256, 512) for scale in (1, 2)}
    actual = [(entry.get('size'), entry.get('scale')) for entry in entries]
    require(len(actual) == len(expected) and set(actual) == expected, 'Mac AppIcon must define all ten 1x/2x slots without duplicates')
    for entry in entries:
        require(entry.get('idiom') == 'mac', 'Mac icon slot has wrong idiom')
        filename = entry.get('filename', '')
        require(filename and Path(filename).name == filename, 'Mac icon slot needs a local filename')
        data = (iconset / filename).read_bytes()
        require(len(data) >= 33 and data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR', f'{filename}: PNG header missing')
        width, height, depth, color = struct.unpack('>IIBB', data[16:26])
        pixels = int(entry['size'].split('x')[0]) * int(entry['scale'][0])
        require((width, height) == (pixels, pixels), f'{filename}: expected {pixels}x{pixels} pixels for {entry["size"]}@{entry["scale"]}')
        require(depth == 8 and color in (2, 6), f'{filename}: expected 8-bit RGB or RGBA PNG')
