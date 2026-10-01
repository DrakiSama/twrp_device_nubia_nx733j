#!/usr/bin/env python3
"""Check vbmeta image targets and keep the two shipped flag tables aligned."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
tables = [
    root / "recovery/root/twrp.flags",
    root / "recovery/root/system/etc/twrp.flags",
]
expected = {
    "/vbmeta": "/vbmeta emmc /dev/block/by-name/vbmeta flags=slotselect;backup=1;flashimg=1;canbewiped=0;wipeingui=0",
    "/vbmeta_a": "/vbmeta_a emmc /dev/block/by-name/vbmeta_a flags=backup=0;flashimg=1;canbewiped=0;wipeingui=0;display=VBMeta-A",
    "/vbmeta_b": "/vbmeta_b emmc /dev/block/by-name/vbmeta_b flags=backup=0;flashimg=1;canbewiped=0;wipeingui=0;display=VBMeta-B",
    "/vbmeta_system": "/vbmeta_system emmc /dev/block/by-name/vbmeta_system flags=slotselect;backup=1;flashimg=1;canbewiped=0;wipeingui=0",
    "/vbmeta_system_a": "/vbmeta_system_a emmc /dev/block/by-name/vbmeta_system_a flags=backup=0;flashimg=1;canbewiped=0;wipeingui=0;display=VBMeta-System-A",
    "/vbmeta_system_b": "/vbmeta_system_b emmc /dev/block/by-name/vbmeta_system_b flags=backup=0;flashimg=1;canbewiped=0;wipeingui=0;display=VBMeta-System-B",
}

for table in tables:
    lines = table.read_text(encoding="utf-8").splitlines()
    actual = {line.split()[0]: line for line in lines if line.startswith("/vbmeta")}
    if actual != expected:
        print(f"Unexpected vbmeta flags in {table}", file=sys.stderr)
        print(f"Expected: {expected}", file=sys.stderr)
        print(f"Actual:   {actual}", file=sys.stderr)
        raise SystemExit(1)

print("Both twrp.flags tables expose active-slot vbmeta aliases and explicit A/B IMG targets.")
