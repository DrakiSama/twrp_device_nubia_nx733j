# TWRP para Nubia Z70 Ultra (NX733J / PQ84A01)

---

## 🇪🇸 Español

### Estado

| Funcionalidad | Estado |
|--------------|--------|
| ADB | ✅ Funcional |
| MTP | ✅ Por defecto |
| Display | ✅ 1260×2800 |
| Touch | ✅ Goodix GT9916 |
| Fastbootd | ✅ |
| Flasheo particiones | ✅ boot_a/b, vendor_boot_a/b, init_boot_a/b, dtbo_a/b, recovery_a/b |
| Backup/Restore | ✅ Compresión habilitada |
| USB-OTG | ✅ |
| EDL Mode | ✅ Reinicio a EDL |
| Crypto / Decrypt | ❌ Reinicia al intentar desencriptar |
| Batería | ❌ No disponible en recovery (kernel limitation) |
| Vibrator | ❌ Causa lag táctil severo, deshabilitado |

### Características

- **Splash personalizado**: "TWRP by Draki"
- **Idioma por defecto**: Español (es_ES)
- **Tamaño de fuente**: 20
- **Timeout de pantalla**: 120 segundos
- **Compresión de backups**: Habilitada
- **Modo EDL**: Botón en menú Reiniciar
- **MTP por defecto**: Al conectar USB
- **Slot switching manual**: Particiones `_a`/`_b` visibles en Install
- **Protección IMEI/SIM**: `modem` oculto, `persist` no flasheable
- **Self-hosted runner**: Builds locales en ~5 min

### Build local (WSL2 / Linux)

```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp -b twrp-16.0 --depth=1
repo sync -c --no-tags --optimized-fetch --prune -j$(nproc)
git clone https://github.com/DrakiSama/twrp_device_nubia_nx733j -b twrp-16.0 device/nubia/NX733J
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_NX733J
m recoveryimage -j$(nproc)
```

### Particiones protegidas

| Partición | Contiene | Protegida |
|-----------|----------|-----------|
| `modem` | Firmware radio, IMEI | Oculta en Install |
| `persist` | Calibraciones | Visible pero no flasheable |
| `misc` | Bootloader | Oculta |
| `frp` | FRP lock | Oculta |

### Issues conocidos

- **Decrypt**: El dispositivo se reinicia al desencriptar /data. Probablemente relacionado con crypto kernel o f2fs.
- **Batería**: El kernel no expone `/sys/class/power_supply/battery` en recovery.
- **WiFi**: No incluido en recovery (no necesario).

---

## 🇬🇧 English

### Status

| Feature | Status |
|---------|--------|
| ADB | ✅ Working |
| MTP | ✅ Enabled by default |
| Display | ✅ 1260×2800 |
| Touch | ✅ Goodix GT9916 |
| Fastbootd | ✅ |
| Partition flashing | ✅ boot_a/b, vendor_boot_a/b, init_boot_a/b, dtbo_a/b, recovery_a/b |
| Backup/Restore | ✅ Compression enabled |
| USB-OTG | ✅ |
| EDL Mode | ✅ Reboot to EDL |
| Crypto / Decrypt | ❌ Reboots when attempting decrypt |
| Battery | ❌ Unavailable in recovery (kernel limitation) |
| Vibrator | ❌ Causes severe touch lag, disabled |

### Features

- **Custom splash**: "TWRP by Draki"
- **Default locale**: Spanish (es_ES)
- **Font size**: 20
- **Screen timeout**: 120 seconds
- **Backup compression**: Enabled
- **EDL mode**: Button in Reboot menu
- **MTP by default**: On USB connect
- **Manual slot switching**: `_a`/`_b` partitions visible in Install
- **IMEI/SIM protection**: `modem` hidden, `persist` non-flashable
- **Self-hosted runner**: Local builds in ~5 min

### Build locally (WSL2 / Linux)

```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp -b twrp-16.0 --depth=1
repo sync -c --no-tags --optimized-fetch --prune -j$(nproc)
git clone https://github.com/DrakiSama/twrp_device_nubia_nx733j -b twrp-16.0 device/nubia/NX733J
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_NX733J
m recoveryimage -j$(nproc)
```

### Protected partitions

| Partition | Contains | Protection |
|-----------|----------|------------|
| `modem` | Radio firmware, IMEI | Hidden from Install |
| `persist` | Calibrations | Visible but non-flashable |
| `misc` | Bootloader config | Hidden |
| `frp` | FRP lock | Hidden |

### Known issues

- **Decrypt**: Device reboots when decrypting /data. Likely crypto kernel or f2fs related.
- **Battery**: Kernel does not expose `/sys/class/power_supply/battery` in recovery.
- **WiFi**: Not included in recovery (not needed).

---

## 🏗️ CI / Build

The repository uses GitHub Actions with a self-hosted runner for faster builds.

Workflow: `.github/workflows/build.yml`

## 🙏 Thanks

- [YuKongA/twrp_device_xiaomi_sm8750_thales](https://github.com/YuKongA/twrp_device_xiaomi_sm8750_thales)
- [reminon/twrp_device_nubia_nx789j](https://github.com/reminon/twrp_device_nubia_nx789j)
