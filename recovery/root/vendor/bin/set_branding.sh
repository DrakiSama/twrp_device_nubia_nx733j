#!/vendor/bin/sh
# set_branding.sh — Agrega "by Draki" al version string de TWRP
# Se ejecuta después de que TWRP inicializa ro.twrp.version

VERSION=$(getprop ro.twrp.version 2>/dev/null)
if [ -n "$VERSION" ]; then
    case "$VERSION" in
        *"by Draki"*) ;;
        *) resetprop ro.twrp.version "$VERSION by Draki" 2>/dev/null ;;
    esac
fi
exit 0
