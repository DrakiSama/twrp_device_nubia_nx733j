# TWRP para Nubia Z70 Ultra (NX733J / PQ84A01)

Árbol en depuración. La imagen b0becfc compiló en GitHub y arrancó en el teléfono.
Las pruebas del 2026-09-13 detectaron dos regresiones: los HAL de cifrado no se
registraban en el manifiesto de recovery y el parser upstream de twrp.flags
interpretaba mal las columnas. Ambas causas se validaron con cambios temporales
en RAM: PIN aceptado y alias físicos del slot activo con tamaños correctos.
Este árbol incorpora el manifiesto en system/etc/vintf y el workflow aplica el
parche del parser. Falta validar un arranque en frío de la siguiente imagen.
No se ha validado todavía el flasheo completo de una IMG, ZIP u OTA.

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

El workflow `.github/workflows/build-validation.yml` usa un runner alojado por GitHub (`ubuntu-22.04`) y cuatro trabajos de compilación, con el límite de memoria de Soong y 16 GiB de swap. Se ejecuta manualmente desde Actions y publica únicamente el `.img` como artefacto durante 14 días. SHA-256, revisiones y estadísticas quedan en el resumen de la ejecución; los logs se consultan en los pasos de Actions.

Una caché de compilador comprimida de hasta 5 GB se reutiliza entre ejecuciones. La primera compilación llena la caché; las siguientes pueden reutilizar los objetos C/C++ válidos. Las fuentes todavía se sincronizan y Soong se regenera en cada VM. No se publica una release ni se flashea el dispositivo.

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

## Pruebas IMG y ZIP

En el build 89dead7, un ZIP de diagnóstico con update-binary terminó con RC=0:
comprobó shell root, salida a la UI, almacenamiento descifrado y lectura de las
cinco particiones físicas del slot activo y siete lógicas. No escribió imágenes.
Esto no valida un instalador Edify, una OTA payload.bin ni una ROM concreta.

El parser de destinos A/B ya resuelve los alias activos correctamente. El próximo
build añade una ruta dedicada para IMG raw y Android sparse en particiones lógicas,
sin cambiar su método de respaldo por archivos. Comprueba que el destino corresponde
al slot seleccionado y que todos los segmentos del mapa son lineales sobre super.

Requiere metadata montada, bloqueo exclusivo de /metadata/ota, estado vacío o `none`
y directorio de snapshots vacío. Un estado desconocido, ilegible o no terminado se
rechaza; no se cancela ni fusiona una OTA. Este control es conservador: otros formatos
de estado también se rechazan. No se redimensionan particiones ni se modifica AVB.

Antes de escribir, desmonta el destino y comprueba tipo de dispositivo, capacidad
real y estado de solo lectura. La apertura exclusiva rechaza un dispositivo ocupado.
Las imágenes sparse se importan y se valida su tamaño expandido; las raw también
deben caber en la asignación actual. Esta ruta no hace BLKDISCARD ni crea/trunca
archivos de destino, y comprueba errores de escritura y fsync.

El workflow ejecuta pruebas del código C++ extraído del árbol parcheado con E/S
simulada: controles de OTA, mapas, tamaños, errores y limpieza de recursos, además
de las 18 pruebas del flasheo sparse físico. Falta compilar este cambio y probarlo
con una imagen compatible. No se ha realizado ninguna escritura de imagen durante
el diagnóstico. El ZIP de diagnóstico no demuestra que una ROM o una OTA arranque.
