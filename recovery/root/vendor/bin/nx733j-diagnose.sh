#!/sbin/sh
# Read-only support report. No serials, user files, writes, mounts or settings.
export PATH=/sbin:/system/bin
echo 'NX733J recovery diagnostics'
for property in ro.twrp.version ro.twrp.device.version ro.boot.slot_suffix sys.usb.config sys.usb.state init.svc.vendor.recovery-hardware; do
    printf '%s: ' "$property"
    getprop "$property"
done
printf 'Kernel: '; uname -r
for value in capacity status temp; do
    file="/sys/class/power_supply/battery/$value"
    if [ -r "$file" ]; then printf 'Battery %s: ' "$value"; cat "$file"; fi
done
for processor in /sys/class/remoteproc/remoteproc*; do
    [ -r "$processor/name" ] || continue
    printf 'Remoteproc '; cat "$processor/name"
    cat "$processor/state"
done
if [ -r /sys/class/leds/vibrator/ram_num ]; then
    printf 'Haptics: '; cat /sys/class/leds/vibrator/ram_num
fi
for zone in /sys/class/thermal/thermal_zone*; do
    [ -r "$zone/type" ] || continue
    [ "$(cat "$zone/type")" = cpuss-0-0 ] || continue
    printf 'CPU cpuss-0-0 (millidegrees C): '; cat "$zone/temp"
done
slot=$(getprop ro.boot.slot_suffix)
case "$slot" in _a|_b) ;; *) echo 'Invalid slot'; exit 1 ;; esac
for part in boot init_boot vendor_boot recovery dtbo; do
    device="/dev/block/by-name/${part}${slot}"
    printf '%s: ' "$part"
    readlink -f "$device"
    blockdev --getsize64 "$device"
done
for part in system system_ext product vendor odm vendor_dlkm system_dlkm; do
    device="/dev/block/mapper/${part}${slot}"
    printf '%s: ' "$part"
    if [ -b "$device" ]; then
        readlink -f "$device"
        blockdev --getsize64 "$device"
        printf 'Read-only: '; blockdev --getro "$device"
    else
        echo 'mapping absent'
    fi
done
echo 'Relevant mounts:'
grep -E ' /(data|metadata|firmware|vendor_dlkm|system_dlkm) ' /proc/mounts
echo 'Hardware initialization log:'
dmesg | grep -E 'nx733j-recovery:|vendor.recovery-hardware' | tail -12
