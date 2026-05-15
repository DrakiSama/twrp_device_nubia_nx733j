# Changelog — TWRP device tree for Nubia Z70 Ultra (NX733J)

## [2026-05-15] — Full optimization pass

### Kernel & Build
- Auto-detect kernel source vs prebuilt (fallback automático)
- Prebuilt kernel cableado correctamente via `TARGET_PREBUILT_KERNEL`
- `TWRP_REQUIRED_MODULES += prebuilt` eliminado (causaba build error)

### Modules (TW_LOAD_VENDOR_MODULES)
- **Agregados**: `msm.ko` (DRM display, `CONFIG_DRM_MSM=m`), `gpucc-sun.ko`, `bcl_soc.ko`
- **Agregados**: `qti_battery_charger.ko`, `zte_power_supply.ko`, `bcl_pmic5.ko` (fix battery display)
- **Eliminados**: `msm_drm.ko` (no existe), `smartpa_stat_dlkm.ko` (no existe), `aw882xx_dlkm.ko` (comentado en Makefile)

### Init scripts
- `odm.vibratorfeature-service` comentado (causaba touch lag)
- `vendor.qti.vibrator` + `post-fs-data` trigger comentados (touch lag severo)
- `odm.touch_report` → `ztethp` (servicio de touch correcto)
- `odm.weaver-service`, `odm.keymint-strongbox`, `odm.se_omapi` comentados (solo existen en ODM)

### VINTF manifest
- `IHealth/default` agregado (battery capacity, charging)
- `IBootControl/default` agregado (A/B slot switching)

### OTA assert
- `TARGET_OTA_ASSERT_DEVICE` → `NX733J,PQ84A01` (no rechaza flash en ROM stock)

### ueventd
- Permisos para `/dev/thp` y `/dev/input_agent` agregados

### Archivos eliminados
- Directorio `odm/` completo (solo contenía archivos de vibrador)
- `vendor/bin/hw/vendor.qti.hardware.vibrator.service`
- 8 `.so` de vibrador en `vendor/lib64/`
- **Total ahorrado: ~870 KB**

---

## [2026-05-06] — NX733J: Initial device adaptation

### system.prop
- Expandido con props reales del NX733J (fingerprint, platform, crypto)
- `ro.adb.secure=0` para ADB root en recovery

### BoardConfig.mk
- Tamaños de partición verificados con `fastboot getvar` en dispositivo real
- Super partition: 16 GB (17179869184 bytes)
- Dynamic partition group: `nubia_dynamic_partitions`
- Crypto: FBE con ICE wrappedkey, fscrypt v2
- CPU: `oryon` (Snapdragon 8 Elite)
- GPU: Adreno 830
- Platform: `sun` (SM8750)

### Known issues (from README)
- ~~Vibrator causes touch delay~~ → **FIXED** (servicios deshabilitados)
- Battery capacity display broken → **MITIGATED** (módulos agregados, probar)
- Not adequately tested

---

## Historial completo (git log)

```
df73fa7 Optimize NX733J tree: modules, init, Hal manifest, kernel detection
28d8032 NX733J: simplify system.prop for recovery
1fa451d NX733J: expand system.prop using real device props
62bdf9f Update BoardConfig.mk
c29fab9 Update build.yml
88af76e NX733J: Initial commit
```
