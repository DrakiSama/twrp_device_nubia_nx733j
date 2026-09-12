# TWRP para Nubia Z70 Ultra (NX733J / PQ84A01)

Árbol en depuración. Los cambios de fstab y flags se validaron en RAM sobre
TWRP `3.7.1_16-by Draki (da439bd)` el 2026-09-12; falta compilar y probar un arranque
nuevo. No se ha validado todavía el flasheo completo de una IMG, ZIP u OTA.

## Estado comprobado

- ADB y descifrado de userdata operativos en el recovery instalado.
- Siete particiones lógicas EROFS montadas en solo lectura con la configuración corregida.
- Flags de flasheo reconocidas para lógicas y particiones físicas por slot.
- Grupo real: `qti_dynamic_partitions`; super: 17179869184 bytes.
- USB OTG temporalmente retirado del fstab: la detección actual confunde UFS interno con USB.
- Fastbootd, backup/restore y arranque del build nuevo pendientes de prueba.

## Particiones

Lógicas: system, system_ext, product, vendor, odm, vendor_dlkm y system_dlkm.
Se resuelven mediante `logical,slotselect`, sin números dm-N ni slot fijo.

El fstab stock de Android (`fstab.qcom`) se mantiene separado del fstab de recovery.
Las flags TWRP usan el formato completo con `flashimg`, `canbewiped` y `wipeingui`.
Las particiones EROFS no se ofrecen como backups de archivos.

TWRP genera automáticamente la entrada Super: no está oculta ni bloqueada por
eliminarla del fstab. No confundir firmware modem con las particiones de datos
NV/modemst/fsg. No se alteraron estas particiones durante el diagnóstico.

## Compilación

El workflow `.github/workflows/build-validation.yml` compila desde cero en un runner alojado por GitHub (`ubuntu-22.04`). Se ejecuta manualmente desde Actions y guarda la imagen, SHA-256, manifiesto y logs como artefactos durante 14 días. No publica una release ni flashea el dispositivo.

El workflow antiguo `.github/workflows/build.yml` utiliza un runner propio y el directorio
`/home/draki/twrp`. Clona este árbol desde GitHub, por lo que los cambios locales
deben llegar al repositorio/rama configurados antes de usar ese workflow.

```bash
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_NX733J
m recoveryimage -j$(nproc)
```

Manifest empleado: https://github.com/TWRP-Test/platform_manifest_twrp_aosp,
rama `twrp-16.0`. Device path: `device/nubia/NX733J`.

Revisar el resultado del ramdisk y probar arranque, descifrado y módulos antes de
marcar el build como estable. El informe y las evidencias locales de esta sesión
están en `diagnostics/` junto al directorio extraído del árbol.
