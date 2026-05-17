#!/bin/bash
# build.sh - Build TWRP for NX733J
# Ejecutar desde ~/twrp/
# Usage: bash device/nubia/NX733J/scripts/build.sh

set -e

DEVICE_PATH="device/nubia/NX733J"
BUILD_DATE=$(date +%F)
START_TIME=$(date +%s)

echo "=== Actualizando device tree ==="
cd "$DEVICE_PATH"
git pull
cd ../..

echo "=== Limpiando build anterior ==="
rm -rf out/target/product/NX733J

echo "=== Configurando ccache ==="
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
export CCACHE_MAXSIZE=10G

echo "=== Iniciando build ==="
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_NX733J
m recoveryimage

echo "=== Copiando imagen a ~/twrp/ ==="
cp out/target/product/NX733J/recovery.img ~/twrp/TWRP-3.7.1-16-NX733J-${BUILD_DATE}.img

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "============================================"
echo "✅ Build completado en ${DURATION}s"
echo "   Tamaño: $(ls -lh ~/twrp/TWRP-3.7.1-16-NX733J-${BUILD_DATE}.img | awk '{print $5}')"
echo ""
echo "Para flashear desde Windows:"
echo "   wsl cp ~/twrp/TWRP-3.7.1-16-NX733J-${BUILD_DATE}.img /mnt/c/Users/$(whoami)/Desktop/"
echo "   Luego desde ToolBox (opción 12) flashear recovery_b"
echo "============================================"
