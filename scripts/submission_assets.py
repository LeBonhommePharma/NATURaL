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


def validate_tv_brand_catalog(catalog):
    """Validate Apple's layered TV brand schema and our conservative bloom safe zone.

    Two real layers are intentional: translucent artwork over an opaque background.
    Asset compilation, parallax appearance and store acceptance still require Xcode.
    """
    def metadata(path):
        value = json.loads((path / 'Contents.json').read_text())
        require(value.get('info', {}).get('version') == 1, f'{path.name}: missing asset format version')
        return value

    def child(parent, filename, suffix):
        require(filename and Path(filename).name == filename and filename.endswith(suffix),
                f'{parent.name}: invalid local {suffix} reference')
        return parent / filename

    def image_set(path, size, scales, transparent=False):
        entries = metadata(path).get('images', [])
        require(len(entries) == len(scales) and {e.get('scale') for e in entries} == set(scales),
                f'{path}: missing or duplicate TV image scales')
        for entry in entries:
            require(entry.get('idiom') == 'tv', f'{path}: TV image has wrong idiom')
            file = child(path, entry.get('filename'), '.png')
            data = file.read_bytes()
            require(len(data) >= 33 and data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR', f'{file}: invalid PNG')
            width, height, depth, color = struct.unpack('>IIBB', data[16:26])
            scale = int(entry['scale'][0])
            require((width, height) == (size[0] * scale, size[1] * scale), f'{file}: incorrect TV pixel dimensions')
            require(depth == 8 and color == (6 if transparent else 2), f'{file}: expected {"RGBA foreground" if transparent else "opaque RGB background or shelf"}')
            require(b'tRNS' not in data, f'{file}: unexpected palette transparency')
            if transparent:
                _validate_tv_foreground_alpha(data, width, height, file)

    require(catalog.suffix == '.brandassets', 'TV app icon must be layered .brandassets')
    require(not catalog.with_suffix('.appiconset').exists(), 'Duplicate flat TV AppIcon catalog must be archived outside Assets.xcassets')
    assets = metadata(catalog).get('assets', [])
    expected = {('primary-app-icon', '400x240'), ('primary-app-icon', '1280x768'),
                ('top-shelf-image', '1920x720'), ('top-shelf-image-wide', '2320x720')}
    require(len(assets) == 4 and {(a.get('role'), a.get('size')) for a in assets} == expected,
            'TV brand needs small/store layered icons and standard/wide Top Shelf')
    for asset in assets:
        require(asset.get('idiom') == 'tv', 'TV brand asset has wrong idiom')
        size = tuple(map(int, asset['size'].split('x')))
        scales = ('1x',) if size == (1280, 768) else ('1x', '2x')
        if asset['role'] != 'primary-app-icon':
            image_set(child(catalog, asset.get('filename'), '.imageset'), size, scales)
            continue
        stack = child(catalog, asset.get('filename'), '.imagestack')
        layers = metadata(stack).get('layers', [])
        require(len(layers) == 2, f'{stack}: expected separate foreground and background layers')
        require(len({layer.get('filename') for layer in layers}) == 2, f'{stack}: duplicate layers')
        for index, layer in enumerate(layers):
            directory = child(stack, layer.get('filename'), '.imagestacklayer')
            metadata(directory)
            sets = list(directory.glob('*.imageset'))
            require(len(sets) == 1, f'{directory}: expected one embedded imageset')
            image_set(sets[0], size, scales, transparent=index == 0)


def _validate_tv_foreground_alpha(data, width, height, file):
    """Decode RGBA8 PNG alpha without an imaging dependency (all PNG row filters)."""
    import zlib
    compressed = bytearray()
    offset = 8
    while offset + 12 <= len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        block = data[offset + 8:offset + 8 + length]
        require(len(block) == length, f'{file}: truncated PNG chunk')
        if kind == b'IDAT':
            compressed.extend(block)
        offset += length + 12
    require(data[28] == 0, f'{file}: interlaced foreground unsupported by offline gate')
    raw = zlib.decompress(compressed)
    stride = width * 4
    require(len(raw) == (stride + 1) * height, f'{file}: invalid PNG scanlines')
    previous = bytearray(stride)
    visible = 0
    for y in range(height):
        start = y * (stride + 1)
        filter_type = raw[start]
        require(filter_type in range(5), f'{file}: invalid PNG filter')
        row = bytearray(raw[start + 1:start + 1 + stride])
        for x in range(3, stride, 4):
            left = row[x - 4] if x >= 4 else 0
            up = previous[x]
            upper_left = previous[x - 4] if x >= 4 else 0
            if filter_type == 1:
                row[x] = (row[x] + left) & 255
            elif filter_type == 2:
                row[x] = (row[x] + up) & 255
            elif filter_type == 3:
                row[x] = (row[x] + (left + up) // 2) & 255
            elif filter_type == 4:
                p = left + up - upper_left
                distances = (abs(p - left), abs(p - up), abs(p - upper_left))
                predictor = (left, up, upper_left)[distances.index(min(distances))]
                row[x] = (row[x] + predictor) & 255
            alpha = row[x]
            px = x // 4
            # Project policy, not a claimed Apple numeric requirement: at least
            # 10% clear padding gives the bloom room during focus/parallax.
            if px < width // 10 or px >= width - width // 10 or y < height // 10 or y >= height - height // 10:
                require(alpha == 0, f'{file}: foreground exceeds 10% transparent safe zone')
            visible += alpha > 0
        previous = row
    require(visible > width * height // 100, f'{file}: foreground is empty or negligible')
