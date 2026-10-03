#!/usr/bin/env python3
"""Fail closed if the NX733J slot-A and no-wipe policies drift."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
tables = [
    root / "recovery/root/twrp.flags",
    root / "recovery/root/system/etc/twrp.flags",
]
expected_data = "/data f2fs /dev/block/by-name/userdata flags=backup=1;flashimg=0;canbewiped=0;wipeingui=0;storage"
for table in tables:
    lines = table.read_text(encoding="utf-8").splitlines()
    for path in ("/data", "/metadata", "/persist"):
        row = next((line for line in lines if line.startswith(path + " ")), None)
        if row is None or "flashimg=0" not in row or "canbewiped=0" not in row or "wipeingui=0" not in row:
            print(f"Unsafe or missing protected partition row {path} in {table}", file=sys.stderr)
            raise SystemExit(1)
    if next(line for line in lines if line.startswith("/data ")) != expected_data:
        print(f"Unexpected userdata policy in {table}", file=sys.stderr)
        raise SystemExit(1)

logical_patch = (root / ".github/patches/logical-image-flash.patch").read_text(encoding="utf-8")
if 'active_slot != "_a"' not in logical_patch or 'compare(Mount_Point.size() - 2, 2, "_b")' not in logical_patch:
    print("IMG slot-A fail-closed guard is missing", file=sys.stderr)
    raise SystemExit(1)

warning_patch = (root / ".github/patches/nx733j-slot-policy.patch").read_text(encoding="utf-8")
for token in ("/vbmeta_a", "/vbmeta_system_a", "WARNING: AVB metadata", "matches the device firmware and slot A"):
    if token not in warning_patch:
        print(f"Missing vbmeta warning behavior: {token}", file=sys.stderr)
        raise SystemExit(1)

slot_policy = warning_patch
for token in ("flash_in_both_slots", "Flashing both slots is disabled", "operation_end(1)"):
    if token not in slot_policy:
        print(f"Missing pre-write slot policy: {token}", file=sys.stderr)
        raise SystemExit(1)
for token in ("tw_flash_vbmeta_ack", "swipe again to continue", "Get_Active_Slot_Suffix() != \"_a\""):
    if token not in slot_policy:
        print(f"Missing two-step VBMeta confirmation: {token}", file=sys.stderr)
        raise SystemExit(1)

print("Both flag tables protect userdata/metadata/persist; IMG writes are slot-A-only; vbmeta A targets show a warning.")
