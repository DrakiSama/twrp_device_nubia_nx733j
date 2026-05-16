#!/vendor/bin/sh
# mount_vendor_dlkm.sh
# Carga módulos de batería desde vendor_dlkm
# TWRP ya montó vendor_dlkm en /vendor_dlkm (fstab logical)

SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null || echo "_a")

# Esperar a que vendor_dlkm esté montado por TWRP (timeout 10s)
for i in 1 2 3 4 5 6 7 8 9 10; do
    if grep -q " /vendor_dlkm " /proc/mounts 2>/dev/null; then
        break
    fi
    sleep 1
done

# Si TWRP no lo montó, intentar nosotros
if ! grep -q " /vendor_dlkm " /proc/mounts 2>/dev/null; then
    DEV="/dev/block/bootdevice/by-name/vendor_dlkm${SLOT}"
    if [ -e "$DEV" ]; then
        mkdir -p /vendor_dlkm
        mount -t ext4 -o ro "$DEV" /vendor_dlkm 2>/dev/null
    fi
fi

# Bind-mount módulos a /vendor/lib/modules (por si el symlink de GKI no existe)
if grep -q " /vendor_dlkm " /proc/mounts 2>/dev/null; then
    MOD_DIR=$(find /vendor_dlkm/lib/modules -maxdepth 2 -name "*.ko" -print -quit 2>/dev/null | xargs -r dirname | head -1)
    if [ -z "$MOD_DIR" ]; then
        MOD_DIR="/vendor_dlkm/lib/modules"
    fi
    if [ -d "$MOD_DIR" ] && ls "$MOD_DIR"/*.ko &>/dev/null; then
        mkdir -p /vendor/lib/modules
        mount --bind "$MOD_DIR" /vendor/lib/modules 2>/dev/null
    fi
fi

# Cargar módulos de batería (si TWRP no los cargó automáticamente)
MODULES="qti_battery_charger bcl_pmic5 bcl_soc zte_power_supply"
for mod in $MODULES; do
    if ! lsmod 2>/dev/null | grep -qw "${mod}"; then
        KO=$(find /vendor_dlkm/lib/modules /vendor/lib/modules -name "${mod}.ko" 2>/dev/null | head -1)
        if [ -n "$KO" ]; then
            insmod "$KO" 2>/dev/null
        fi
    fi
done

exit 0
