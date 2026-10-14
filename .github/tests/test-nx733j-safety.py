#!/usr/bin/env python3
"""Check NX733J IMG slot targeting and no-wipe policies."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
tables = [root / "recovery/root/twrp.flags", root / "recovery/root/system/etc/twrp.flags"]
expected_data = "/data f2fs /dev/block/by-name/userdata flags=backup=1;flashimg=0;canbewiped=0;wipeingui=0;storage"
logical_names = ("system", "system_ext", "product", "vendor", "odm", "vendor_dlkm", "system_dlkm")

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
    for name in logical_names:
        for slot in ("a", "b"):
            row = f"/{name}_{slot} "
            if not any(line.startswith(row) and "flashimg=1" in line for line in lines):
                print(f"Missing logical IMG target {row.strip()} in {table}", file=sys.stderr)
                raise SystemExit(1)

logical_patch = (root / ".github/patches/logical-image-flash.patch").read_text(encoding="utf-8")
slot_target_patch = (root / ".github/patches/logical-slot-targets.patch").read_text(encoding="utf-8")
if ("nx733j_active_slot_warning" not in logical_patch or "if (!explicit_slot)" not in logical_patch
        or 'Mount_Point == "/super"' not in logical_patch):
    print("Active-slot warning, logical target selection, or raw-super protection is missing", file=sys.stderr)
    raise SystemExit(1)
for token in ("/dev/block/mapper/{}", "explicit_slot", "Get_Active_Slot_Suffix()"):
    if token not in slot_target_patch:
        print(f"Missing explicit logical slot mapping behavior: {token}", file=sys.stderr)
        raise SystemExit(1)

slot_policy = (root / ".github/patches/nx733j-slot-policy.patch").read_text(encoding="utf-8")
for token in ("flash_in_both_slots", "explicit A or B image target", "operation_end(1)"):
    if token not in slot_policy:
        print(f"Missing pre-write slot policy: {token}", file=sys.stderr)
        raise SystemExit(1)

print("Protected partitions remain non-flashable; physical and logical A/B IMG targets are available; active-slot writes warn.")
