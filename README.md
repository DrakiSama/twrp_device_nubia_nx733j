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

## Batería y firmware de vibración

Prueba en RAM del 2026-09-13: iniciar el remoteproc ADSP con el firmware del slot
activo hizo aparecer battery/usb/wireless; battery informó 37% y Charging.
El próximo build inicia únicamente ADSP, después de montar modem de solo lectura,
sin reiniciar un DSP activo ni cambiar su selección de firmware. La espera es
acotada y se ejecuta en segundo plano para no bloquear el init del recovery.
Falta validar este orden de inicialización en un arranque limpio del nuevo build.

Se incluye haptic_ram.bin extraído del vendor stock de este teléfono, SHA-256
e446c67665c16cca99ded8d07a9cc016277a25b5cf0a7203254f8157fddc96ee.
Al cargarlo desde el /vendor/firmware del ramdisk, ram_num pasó de 0 a 4.
Esto valida la carga del firmware, no la vibración de la interfaz: TW_NO_HAPTICS
permanece activado y el HAL sigue deshabilitado por el antecedente de lag táctil.
No se añadieron módulos indiscriminadamente; los drivers correspondientes ya
estaban cargados. No se modificaron políticas de carga ni calibraciones.

Validación posterior de 2686751: haptic_ram carga sus cuatro efectos tras reinicio,
pero el exec temprano de ADSP terminó con 127. Iniciarlo desde ADB recuperó batería.
La siguiente revisión usa un servicio oneshot con PATH y entorno del linker
explícitos y salida a kmsg. Requiere otra validación en frío; no se considera aún
resuelta la inicialización automática. Los logs del flasheo a recovery_b muestran
escritura correcta a /dev/block/sde60; tras flashear ambos slots sus SHA-256 coinciden.

## Identificación y revisión de inicio

Cada ejecución de Actions añade `by Draki b<run_number>.<run_attempt>-<commit>`
a la versión visible de TWRP, usando un build-version.mk generado antes de lunch.
Una compilación local sin ese archivo muestra `by Draki local`.

En 91759f2 el servicio fallaba con 127 durante el montaje inicial; el mismo
servicio iniciado después por ctl.start terminó con RC=0 y recuperó batería.
El helper ahora se instala y ejecuta desde /sbin, fuera del punto /vendor que
TWRP monta temporalmente. Sigue pendiente probar esta corrección en arranque frío.

Se habilitan los ajustes de vibración mediante duration_aw y activate_aw; el HAL
vendor.qti.vibrator permanece deshabilitado. El firmware cargó cuatro efectos y
el usuario confirmó un pulso directo de 300 ms; uno de 80 ms no fue perceptible.
Todavía falta verificar la respuesta y duración elegida desde la UI del nuevo build.

## Diagnóstico y claridad de destinos

`adb shell /sbin/sh /sbin/nx733j-diagnose.sh` genera un informe de solo lectura:
build, slot, USB, batería, ADSP, haptics, CPU, tamaños y mapas. No lee archivos
personales ni cambia propiedades; puede guardarse redirigiendo la salida en el PC.

El flasheo muestra mount point y dispositivo real antes de comenzar. Los destinos
fijos tienen nombres como Recovery-A y Recovery-B. El alias Recovery continúa
usando el slot seleccionado; no se modifica la selección ni el comportamiento A/B.

La temperatura CPU usa el sensor cpuss-0-0 descubierto por nombre, en lugar de
thermal_zone1, que en este dispositivo era pm8010m_tz (PMIC). El enlace temporal
lo crea el helper de hardware. Si no existe el sensor, no se sustituye por otro.
Los helpers de montaje y branding también se ejecutan desde /sbin. Se elimina
la llamada a odm.prepdecrypt, un servicio inexistente que generaba errores.
USB/MTP se observó configurado como mtp,adb; no se alteró su configuración ni se
consideró validada una transferencia MTP real. OTG requiere prueba con hardware.
