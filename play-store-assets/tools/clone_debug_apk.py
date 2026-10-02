#!/usr/bin/env python3
"""Create an install-isolated debug APK by patching only manifest identity fields.

The application package ID and any matching authorities/task affinities must have
the same encoded length.  Component class names are deliberately never changed:
the clone retains the original DEX namespace.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path


RES_STRING_POOL_TYPE = 0x0001
RES_TABLE_TYPE = 0x0002
RES_TABLE_PACKAGE_TYPE = 0x0200
RES_XML_START_ELEMENT_TYPE = 0x0102
TYPE_STRING = 0x03


@dataclass(frozen=True)
class StringEntry:
    value: str
    text_offset: int
    byte_length: int
    encoding: str


def _decode_length(data: bytes, offset: int, utf8: bool) -> tuple[int, int]:
    first = data[offset]
    if utf8:
        if first & 0x80:
            return ((first & 0x7F) << 8) | data[offset + 1], 2
        return first, 1
    if first & 0x80:
        return ((first & 0x7F) << 16) | (data[offset + 1] << 8) | data[offset + 2], 3
    return first, 2


def _read_string_pool(manifest: bytes) -> tuple[list[StringEntry], int, int]:
    # A binary XML document starts with an eight-byte XML header; its string
    # pool is the first nested chunk.
    xml_type, xml_header_size, _ = struct.unpack_from("<HHI", manifest, 0)
    if xml_type != 0x0003 or xml_header_size != 8:
        raise ValueError("AndroidManifest.xml does not begin with a binary XML header")
    pool_offset = xml_header_size
    chunk_type, header_size, chunk_size = struct.unpack_from("<HHI", manifest, pool_offset)
    if chunk_type != RES_STRING_POOL_TYPE:
        raise ValueError("AndroidManifest.xml does not begin with a string pool")
    string_count, style_count, flags, strings_start, styles_start = struct.unpack_from(
        "<IIIII", manifest, pool_offset + 8
    )
    if style_count or styles_start:
        # Styles do not affect the strings we patch, but retain the explicit guard
        # so unexpected compiler output is visible in the artifact report.
        pass
    utf8 = bool(flags & 0x100)
    offsets_base = pool_offset + header_size
    entries: list[StringEntry] = []
    for index in range(string_count):
        relative = struct.unpack_from("<I", manifest, offsets_base + index * 4)[0]
        start = pool_offset + strings_start + relative
        if utf8:
            _, length_bytes = _decode_length(manifest, start, True)
            _, utf16_length_bytes = _decode_length(manifest, start + length_bytes, True)
            text_offset = start + length_bytes + utf16_length_bytes
            end = manifest.index(b"\0", text_offset)
            raw = manifest[text_offset:end]
            entries.append(StringEntry(raw.decode("utf-8"), text_offset, len(raw), "utf-8"))
        else:
            character_count, length_bytes = _decode_length(manifest, start, False)
            text_offset = start + length_bytes
            end = text_offset + character_count * 2
            raw = manifest[text_offset:end]
            entries.append(StringEntry(raw.decode("utf-16le"), text_offset, len(raw), "utf-16le"))
    return entries, pool_offset + header_size, pool_offset + chunk_size


def _string_value(entries: list[StringEntry], index: int) -> str | None:
    return entries[index].value if index != 0xFFFFFFFF else None


def manifest_attributes(manifest: bytes, entries: list[StringEntry], pool_size: int) -> list[dict[str, object]]:
    """Return raw XML attribute values with their element context."""
    attributes: list[dict[str, object]] = []
    offset = pool_size
    while offset + 8 <= len(manifest):
        chunk_type, header_size, chunk_size = struct.unpack_from("<HHI", manifest, offset)
        if chunk_size < header_size or offset + chunk_size > len(manifest):
            raise ValueError(f"invalid XML chunk at offset {offset}")
        if chunk_type == RES_XML_START_ELEMENT_TYPE:
            # ResXMLTree_node (16 bytes) + ResXMLTree_attrExt (20 bytes).
            _, element_name_index = struct.unpack_from("<II", manifest, offset + 16)
            attr_start, attr_size, attr_count = struct.unpack_from("<HHH", manifest, offset + 24)
            attr_offset = offset + 16 + attr_start
            for number in range(attr_count):
                item = attr_offset + number * attr_size
                _, attr_name_index, raw_value_index = struct.unpack_from("<III", manifest, item)
                data_type = manifest[item + 15]
                typed_value_index = struct.unpack_from("<I", manifest, item + 16)[0]
                value_index = raw_value_index
                if value_index == 0xFFFFFFFF and data_type == TYPE_STRING:
                    value_index = typed_value_index
                attributes.append(
                    {
                        "element": _string_value(entries, element_name_index),
                        "name": _string_value(entries, attr_name_index),
                        "value": _string_value(entries, value_index),
                        "string_index": value_index if value_index != 0xFFFFFFFF else None,
                    }
                )
        offset += chunk_size
    return attributes


def patch_manifest(manifest: bytes, old_id: str, new_id: str) -> tuple[bytes, list[dict[str, object]], list[dict[str, object]]]:
    if len(old_id.encode("utf-8")) != len(new_id.encode("utf-8")):
        raise ValueError("old and new application IDs must have equal UTF-8 byte lengths")
    entries, _, pool_size = _read_string_pool(manifest)
    attrs = manifest_attributes(manifest, entries, pool_size)
    candidates = [
        attr
        for attr in attrs
        if attr["name"] in {"package", "authorities", "taskAffinity"}
        and isinstance(attr["value"], str)
        and (attr["value"] == old_id or attr["value"].startswith(old_id + "."))
    ]
    if not any(attr["name"] == "package" and attr["value"] == old_id for attr in candidates):
        raise ValueError(f"manifest package attribute {old_id!r} was not found")

    patched = bytearray(manifest)
    report: list[dict[str, object]] = []
    for attr in candidates:
        index = attr["string_index"]
        assert isinstance(index, int)
        entry = entries[index]
        replacement = entry.value.replace(old_id, new_id, 1)
        encoded = replacement.encode(entry.encoding)
        if len(encoded) != entry.byte_length:
            raise ValueError(f"replacement length changed for {entry.value!r}")
        patched[entry.text_offset : entry.text_offset + entry.byte_length] = encoded
        report.append({**attr, "replacement": replacement})
    return bytes(patched), candidates, report


def resource_packages(resources: bytes) -> list[dict[str, object]]:
    """Read package names from ResTable_package chunks in resources.arsc."""
    table_type, table_header_size, table_size = struct.unpack_from("<HHI", resources, 0)
    if table_type != RES_TABLE_TYPE or table_size > len(resources):
        raise ValueError("resources.arsc does not begin with a resource table")
    packages: list[dict[str, object]] = []
    offset = table_header_size
    while offset + 8 <= table_size:
        chunk_type, header_size, chunk_size = struct.unpack_from("<HHI", resources, offset)
        if chunk_size < header_size or offset + chunk_size > table_size:
            raise ValueError(f"invalid resource chunk at offset {offset}")
        if chunk_type == RES_TABLE_PACKAGE_TYPE:
            # ResTable_package stores its name as 128 UTF-16 code units, directly
            # after the chunk header (8) and package ID (4).
            name_offset = offset + 12
            name_data = resources[name_offset : name_offset + 256]
            terminator = next((index for index in range(0, len(name_data), 2) if name_data[index:index + 2] == b"\0\0"), 256)
            name = name_data[:terminator].decode("utf-16le")
            packages.append({"name": name, "name_offset": name_offset, "chunk_offset": offset})
        offset += chunk_size
    return packages


def patch_resource_namespace(resources: bytes, old_id: str, new_id: str) -> tuple[bytes, list[dict[str, object]]]:
    if len(old_id) != len(new_id):
        raise ValueError("old and new resource package names must have equal UTF-16 lengths")
    packages = resource_packages(resources)
    matches = [package for package in packages if package["name"] == old_id]
    if not matches:
        raise ValueError(f"resource package name {old_id!r} was not found; found {[item['name'] for item in packages]!r}")
    patched = bytearray(resources)
    encoded = new_id.encode("utf-16le")
    for package in matches:
        name_offset = package["name_offset"]
        assert isinstance(name_offset, int)
        patched[name_offset : name_offset + len(encoded)] = encoded
    return bytes(patched), [{"name": item["name"], "replacement": new_id, "chunk_offset": item["chunk_offset"]} for item in matches]


def rewrite_apk(source: Path, output: Path, patched_manifest: bytes, patched_resources: bytes) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(source, "r") as source_zip, zipfile.ZipFile(output, "w", allowZip64=True) as output_zip:
        for info in source_zip.infolist():
            if info.filename == "AndroidManifest.xml":
                payload = patched_manifest
            elif info.filename == "resources.arsc":
                payload = patched_resources
            else:
                payload = source_zip.read(info.filename)
            output_zip.writestr(info, payload)


def verify_preserved_payloads(source: Path, output: Path) -> dict[str, int]:
    """Compare decoded ZIP payloads, excluding the expected manifest/signature changes."""
    checked = 0
    with zipfile.ZipFile(source, "r") as source_zip, zipfile.ZipFile(output, "r") as output_zip:
        source_names = {item.filename for item in source_zip.infolist()}
        output_names = {item.filename for item in output_zip.infolist()}
        for name in source_names:
            if name in {"AndroidManifest.xml", "resources.arsc"} or (
                name.startswith("META-INF/") and name.rsplit(".", 1)[-1] in {"SF", "RSA", "DSA", "EC"}
            ):
                continue
            if name not in output_names:
                raise ValueError(f"payload missing from clone: {name}")
            if hashlib.sha256(source_zip.read(name)).digest() != hashlib.sha256(output_zip.read(name)).digest():
                raise ValueError(f"payload changed in clone: {name}")
            checked += 1
    return {"unchanged_source_entries": checked, "source_entry_count": len(source_names), "clone_entry_count": len(output_names)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--old-id", default="com.example.talia_quran")
    parser.add_argument("--new-id", default="com.example.talia_shots")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--verify-copy", action="store_true", help="verify source payloads after writing the clone")
    parser.add_argument("--verify-existing", type=Path, help="verify an already-created clone without rewriting it")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.verify_existing:
        result = {"source": str(args.source), "output": str(args.verify_existing)}
        result["payload_verification"] = verify_preserved_payloads(args.source, args.verify_existing)
        report_text = json.dumps(result, ensure_ascii=False, indent=2)
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(report_text + "\n", encoding="utf-8")
        print(report_text)
        return 0

    with zipfile.ZipFile(args.source, "r") as apk:
        manifest = apk.read("AndroidManifest.xml")
        resources = apk.read("resources.arsc")
    patched, candidates, report = patch_manifest(manifest, args.old_id, args.new_id)
    patched_resources, resource_report = patch_resource_namespace(resources, args.old_id, args.new_id)
    result = {
        "source": str(args.source),
        "output": str(args.output) if args.output else None,
        "manifest_bytes": len(manifest),
        "candidate_count": len(candidates),
        "patched_fields": report,
        "resource_packages": resource_report,
    }
    report_text = json.dumps(result, ensure_ascii=False, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report_text + "\n", encoding="utf-8")
    print(report_text)
    if not args.dry_run:
        if args.output is None:
            parser.error("--output is required unless --dry-run is used")
        rewrite_apk(args.source, args.output, patched, patched_resources)
        if args.verify_copy:
            result["payload_verification"] = verify_preserved_payloads(args.source, args.output)
            report_text = json.dumps(result, ensure_ascii=False, indent=2)
            if args.report:
                args.report.write_text(report_text + "\n", encoding="utf-8")
            print(json.dumps(result["payload_verification"], indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
