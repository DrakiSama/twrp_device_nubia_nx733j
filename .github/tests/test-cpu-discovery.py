#!/usr/bin/env python3
"""Exercise CPU sensor discovery and readable tmpfs publication in isolation."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

source = Path(sys.argv[1]).read_text()
for scenario in ["immediate", "late", "missing", "pmic-only", "publish-error"]:
    with tempfile.TemporaryDirectory(prefix="twrp-cpu-test-") as temp:
        root = Path(temp)
        thermal = root / "sys/class/thermal"
        thermal.mkdir(parents=True)
        (root / "tmp").mkdir()
        (root / "dev").mkdir()
        (root / "bin").mkdir()

        def zone(name, kind):
            directory = thermal / name
            directory.mkdir(exist_ok=True)
            (directory / "type").write_text(kind)
            (directory / "temp").write_text("45100\n")

        zone("thermal_zone1", "pm8010m_tz")
        if scenario in ["immediate", "publish-error"]:
            zone("thermal_zone25", "cpuss-0-0")

        # Advance discovery time and hot-add the CPU sensor for the late case.
        sleep = """#!/bin/sh
n=0
[ ! -f "$TEST_ROOT/ticks" ] || n=$(cat "$TEST_ROOT/ticks")
n=$((n + 1))
echo "$n" > "$TEST_ROOT/ticks"
if [ "$TEST_SCENARIO" = late ] && [ "$n" -eq 3 ]; then
    mkdir -p "$TEST_ROOT/sys/class/thermal/thermal_zone28"
    echo cpuss-0-0 > "$TEST_ROOT/sys/class/thermal/thermal_zone28/type"
    echo 45100 > "$TEST_ROOT/sys/class/thermal/thermal_zone28/temp"
fi
"""
        (root / "bin/sleep").write_text(sleep)
        (root / "bin/sleep").chmod(0o755)
        if scenario == "publish-error":
            (root / "bin/mv").write_text("#!/bin/sh\nexit 1\n")
            (root / "bin/mv").chmod(0o755)

        script = source.replace("/sys/class/thermal", str(thermal))
        script = script.replace("/tmp/nx733j-cpu-temp", str(root / "tmp/nx733j-cpu-temp"))
        script = script.replace("/dev/kmsg", str(root / "dev/kmsg"))
        # Bound the production polling loop to two samples for this test.
        script = script.replace("while :; do", 'samples=0\nwhile [ "$samples" -lt 2 ]; do\n    samples=$((samples + 1))')
        env = dict(os.environ, PATH=str(root / "bin") + ":" + os.environ["PATH"],
                   TEST_ROOT=str(root), TEST_SCENARIO=scenario)
        result = subprocess.run(["sh", "-c", script], env=env,
                                capture_output=True, timeout=5)
        ticks = int((root / "ticks").read_text()) if (root / "ticks").exists() else 0
        published = root / "tmp/nx733j-cpu-temp"
        if scenario in ["immediate", "late"]:
            expected_zone = "thermal_zone28" if scenario == "late" else "thermal_zone25"
            assert result.returncode == 0, (scenario, result.stderr)
            assert published.is_file() and not published.is_symlink()
            assert published.read_text() == "45100\n"
            assert ticks == (5 if scenario == "late" else 2)
            assert expected_zone in (root / "dev/kmsg").read_text()
        elif scenario in ["missing", "pmic-only"]:
            assert result.returncode != 0 and not published.exists(), (scenario, result)
            assert ticks == 29
        else:
            assert result.returncode != 0 and not published.exists(), result
            assert "Unable to publish CPU temperature" in (root / "dev/kmsg").read_text()
print("CPU discovery/publication: 5 scenarios passed")
