#!/usr/bin/env python3
"""Work around Godot 4.7.2 native export overwriting every provider authority.

Changes the second duplicate string pool entry back to <package>.androidx-startup.
Only AndroidManifest.xml changes. Caller must zipalign and re-sign the output.
Source: platform/android/export/export_plugin.cpp, provider/authorities replacement.
No external dependencies, secrets, or source engine modifications.
"""
import argparse
import struct
import zipfile
from pathlib import Path


def u32(data, offset):
    return struct.unpack_from('<I', data, offset)[0]


def read_length(data, offset, utf8):
    if utf8:
        value = data[offset]
        return (((value & 0x7f) << 8) | data[offset+1], offset+2) if value & 0x80 else (value, offset+1)
    value = struct.unpack_from('<H', data, offset)[0]
    return (((value & 0x7fff) << 16) | struct.unpack_from('<H', data, offset+2)[0], offset+4) if value & 0x8000 else (value, offset+2)


def encode_length(value, utf8):
    if utf8:
        return bytes([(value >> 8) | 0x80, value & 0xff]) if value > 127 else bytes([value])
    return struct.pack('<HH', (value >> 16) | 0x8000, value & 0xffff) if value > 32767 else struct.pack('<H', value)


def fix_manifest(data, package):
    assert struct.unpack_from('<H', data)[0] == 3, 'Not Android binary XML'
    start = struct.unpack_from('<H', data, 2)[0]
    kind, header_size, pool_size = struct.unpack_from('<HHI', data, start)
    assert kind == 1 and header_size == 28, 'Unexpected XML string pool'
    count, style_count, flags, strings_start, styles_start = struct.unpack_from('<IIIII', data, start+8)
    utf8 = bool(flags & 0x100)
    entries = []
    for i in range(count):
        at = start + strings_start + u32(data, start+header_size+i*4)
        length, at = read_length(data, at, utf8)
        if utf8:
            byte_count, at = read_length(data, at, True)
            value = data[at:at+byte_count].decode('utf-8')
        else:
            value = data[at:at+length*2].decode('utf-16le')
        entries.append(value)
    duplicate = package + '.fileprovider'
    indexes = [i for i, value in enumerate(entries) if value == duplicate]
    # Fail closed if a different engine changes the manifest structure.
    if len(indexes) != 2:
        raise ValueError(f'Expected two duplicated provider authority strings, got {len(indexes)}')
    entries[indexes[1]] = package + '.androidx-startup'
    offsets = []
    encoded = bytearray()
    for value in entries:
        offsets.append(len(encoded))
        units = len(value.encode('utf-16le')) // 2
        if utf8:
            payload = value.encode('utf-8')
            encoded += encode_length(units, True) + encode_length(len(payload), True) + payload + b'\0'
        else:
            encoded += encode_length(units, False) + value.encode('utf-16le') + b'\0\0'
    encoded += b'\0' * (-len(encoded) % 4)
    style_offsets = data[start+header_size+count*4:start+header_size+(count+style_count)*4]
    styles = data[start+styles_start:start+pool_size] if style_count else b''
    strings_start = header_size + (count+style_count)*4
    styles_start = strings_start + len(encoded) if style_count else 0
    new_size = strings_start + len(encoded) + len(styles)
    # Clear SORTED flag: replacing a string may change sort order.
    pool = struct.pack('<HHIIIIII', 1, header_size, new_size, count, style_count, flags & ~1, strings_start, styles_start)
    pool += struct.pack('<' + 'I'*count, *offsets) + style_offsets + encoded + styles
    result = bytearray(data[:start] + pool + data[start+pool_size:])
    struct.pack_into('<I', result, 4, len(result))
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--package', default='org.canislegatus.beavermayhem')
    args = parser.parse_args()
    with zipfile.ZipFile(args.source) as source, zipfile.ZipFile(args.output, 'w') as output:
        for entry in source.infolist():
            if entry.filename.upper().startswith('META-INF/'):
                continue  # Any obsolete JAR signature must not survive rewriting.
            content = source.read(entry)
            if entry.filename == 'AndroidManifest.xml':
                content = fix_manifest(content, args.package)
            output.writestr(entry, content)
    print('Repaired Android provider authorities; output requires zipalign and signing.')


if __name__ == '__main__':
    main()
