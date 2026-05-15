#!/vendor/bin/sh
# mount_vendor_dlkm.sh
# Monta vendor_dlkm y carga módulos del kernel necesarios para TWRP
# (batería, etc.). Los módulos vendor están en vendor_dlkm en GKI 2.0.

SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null || echo "_a")

# ----- 1. Montar vendor_dlkm -----
try_mount() {
    local dev="$1" mnt="$2"
    mkdir -p "$mnt"
    if mount -t ext4 -o ro "$dev" "$mnt" 2>/dev/null; then
        return 0
    fi
    # Intentar con wait
    if [ -e "$dev" ]; then
        mount -t ext4 -o ro "$dev" "$mnt" 2>/dev/null && return 0
    fi
    return 1
}

VENDOR_DLKM="/vendor_dlkm"
MOUNTED=false

# 1a. Por slot (ej: /dev/block/by-name/vendor_dlkm_a)
try_mount "/dev/block/bootdevice/by-name/vendor_dlkm${SLOT}" "$VENDOR_DLKM" && MOUNTED=true

# 1b. Por device mapper (lógicas dentro de super)
if ! $MOUNTED; then
    for dm in /dev/block/mapper/vendor_dlkm*; do
        [ -e "$dm" ] && try_mount "$dm" "$VENDOR_DLKM" && { MOUNTED=true; break; }
    done
fi

# 1c. Buscar el mapper por nombre de grupo
if ! $MOUNTED; then
    for dm in /dev/block/mapper/*vendor_dlkm*; do
        [ -e "$dm" ] && try_mount "$dm" "$VENDOR_DLKM" && { MOUNTED=true; break; }
    done
fi

# ----- 2. Vincular módulos a /vendor/lib/modules -----
if $MOUNTED; then
    # Buscar directorio de módulos (puede tener subdirectorio con versión)
    MOD_DIR=$(find "$VENDOR_DLKM/lib/modules" -maxdepth 2 -name "*.ko" -print -quit 2>/dev/null | xargs -r dirname | head -1)
    if [ -z "$MOD_DIR" ]; then
        # Intentar con el directorio directamente
        MOD_DIR="$VENDOR_DLKM/lib/modules"
    fi

    if [ -d "$MOD_DIR" ] && [ "$(ls "$MOD_DIR"/*.ko 2>/dev/null | wc -l)" -gt 0 ]; then
        # Bind-mount al path que espera TWRP
        mkdir -p /vendor/lib/modules
        mount --bind "$MOD_DIR" /vendor/lib/modules 2>/dev/null
    fi
fi

# ----- 3. Cargar módulos de batería manualmente -----
# TWRP ya intentó cargar módulos y falló, los cargamos nosotros
MODULES="qti_battery_charger bcl_pmic5 bcl_soc zte_power_supply"
for mod in $MODULES; do
    # Buscar en vendor_dlkm o vendor/lib/modules
    for base in /vendor_dlkm/lib/modules /vendor/lib/modules; do
        KO=$(find "$base" -name "${mod}.ko" 2>/dev/null | head -1)
        if [ -n "$KO" ]; then
            insmod "$KO" 2>/dev/null && echo "mount_vendor_dlkm: loaded $KO" && break
        fi
    done
done

# ----- 4. Forzar recarga de módulos de display/touch si no estaban -----
# (opcional, por si acaso)
for mod in msm drm_display_helper panel_event_notifier dispcc-sun; do
    if ! lsmod 2>/dev/null | grep -q "${mod} "; then
        KO=$(find /vendor/lib/modules -name "${mod}.ko" 2>/dev/null | head -1)
        [ -n "$KO" ] && insmod "$KO" 2>/dev/null
    fi
done

exit 0
