#!/vendor/bin/sh
# mount_vendor_dlkm.sh
# Monta vendor_dlkm si TWRP no lo hizo

SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null || echo "_a")

for i in 1 2 3 4 5 6 7 8 9 10; do
    if grep -q " /vendor_dlkm " /proc/mounts 2>/dev/null; then
        break
    fi
    sleep 1
done

if ! grep -q " /vendor_dlkm " /proc/mounts 2>/dev/null; then
    DEV="/dev/block/bootdevice/by-name/vendor_dlkm${SLOT}"
    if [ -e "$DEV" ]; then
        mkdir -p /vendor_dlkm
        mount -t ext4 -o ro "$DEV" /vendor_dlkm 2>/dev/null
    fi
fi

exit 0
