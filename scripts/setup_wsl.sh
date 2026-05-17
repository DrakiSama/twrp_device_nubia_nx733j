#!/bin/bash
# setup_wsl.sh - One-time TWRP build environment setup on WSL2
# Ejecutar UNA SOLA vez desde WSL2 (Ubuntu)

set -e

echo "=== Instalando dependencias ==="
sudo apt update
sudo apt install -y repo git gnupg flex bison build-essential zip curl zlib1g-dev \
  gcc-multilib g++-multilib libc6-dev-i386 libncurses-dev \
  libx11-dev libgl1-mesa-dev libxml2-utils \
  xsltproc unzip fontconfig python3 python-is-python3 ccache

echo "=== Creando directorio twrp ==="
mkdir -p ~/twrp && cd ~/twrp

echo "=== Sincronizando TWRP source (una vez, toma ~15 min) ==="
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp -b twrp-16.0 --depth=1
repo sync -c --no-tags --optimized-fetch --prune

echo "=== Clonando device tree ==="
git clone https://github.com/DrakiSama/twrp_device_nubia_nx733j -b twrp-16.0 device/nubia/NX733J

# Setup ccache
echo 'export USE_CCACHE=1' >> ~/.bashrc
echo 'export CCACHE_DIR=~/.ccache' >> ~/.bashrc
echo 'export CCACHE_MAXSIZE=10G' >> ~/.bashrc
source ~/.bashrc

echo ""
echo "============================================"
echo "✅ Entorno listo!"
echo "Para construir: cd ~/twrp && bash device/nubia/NX733J/scripts/build.sh"
echo "============================================"
