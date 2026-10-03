# TWRP para Nubia Z70 Ultra (NX733J / PQ84A01)

Device tree en desarrollo para TWRP 16. El último build documentado es
**b16.1-878ad43**, CI run [37139677597](https://github.com/DrakiSama/twrp_device_nubia_nx733j/actions/runs/37139677597),
imagen `recovery-NX733J-878ad43.img` (104857600 bytes; SHA-256
`A282838C3CF6FA7F9A85C9E99A9402DBCB1442796FC3405816A7E40B8810827D`). El usuario
confirmó batería, vibración y temperatura CPU en ese build.

Los cambios de seguridad IMG en esta revisión requieren otra compilación y pruebas
en el teléfono. No considerar esta revisión una build final ni asumir que instala
o arranca cualquier ROM, ZIP u OTA.

## Estado comprobado y pendientes

- Metadata y userdata F2FS: descifrado metadata/FBE con PIN operativo en pruebas
  anteriores; volver a validar el PIN en la build final.
- Siete particiones lógicas EROFS: system, system_ext, product, vendor, odm,
  vendor_dlkm y system_dlkm. No existe odm_dlkm.
- Alias de particiones del slot seleccionado y destinos explícitos A/B. La política
  de IMG nueva exige slot A y rechaza destinos `_b`.
- La opción “Flash both slots” se rechaza antes de escribir.
- `/data`, `/metadata` y `/persist` no son destinos IMG ni se pueden borrar desde
  las opciones de wipe de TWRP en esta política.
- El usuario instaló recovery.img desde TWRP. Los logs confirmaron escritura de
  recovery_b a /dev/block/sde60 y hashes A/B iguales tras flash both slots.
- Un ZIP de diagnóstico ejecutó update-binary; otro produjo ERROR 42. Estas pruebas
  no escribieron imágenes ni validan una OTA `payload.bin`. Sideload ZIP no equivale
  a instalar una OTA moderna basada en `payload.bin`.
- USB observado como mtp,adb. Transferencia MTP, OTG, fastbootd y backup/restore
  siguen pendientes de pruebas completas.
- OTG permanece retirado del fstab: la configuración antigua confundía UFS
  interno con almacenamiento USB. Requiere validar un dispositivo USB real.

## Particiones y flasheo IMG

El fstab de recovery y twrp.flags se mantienen separados del fstab stock Android.
Las lógicas usan logical,slotselect; no dependen de un número dm-N. Para proteger
el fallback stock B, el escritor IMG exige que A esté activo y comprueba que el
mapeo corresponda a A. Un ZIP ejecuta su propio instalador; esta guarda IMG no
controla escrituras que un ZIP realice por su cuenta.
Grupo qti_dynamic_partitions, super de 17179869184 bytes.

Los parches permiten IMG raw y Android sparse en lógicas EROFS, conservando su
método de backup. Exigen metadata montada, bloqueo exclusivo de /metadata/ota,
estado vacío o none y snapshots vacíos. El mapeo debe pertenecer al slot elegido
y ser lineal sobre super. Estados desconocidos o ilegibles se rechazan.

Antes de escribir se comprueban tamaño expandido, capacidad del destino, tipo
bloque, estado de solo lectura y desmontaje. La apertura exclusiva rechaza un
destino ocupado. La ruta lógica no usa BLKDISCARD ni crea/trunca archivos de
destino; comprueba errores y fsync. No redimensiona super, fusiona snapshots,
cambia AVB ni selecciona otro slot.

La UI muestra mount point y bloque real antes de escribir. Recovery usa el slot
seleccionado; Recovery-A y Recovery-B identifican destinos fijos. Super continúa
siendo una entrada generada por TWRP. No confundir modem con datos NV/modemst/fsg.

`vbmeta` y `vbmeta_system` permiten seleccionar IMG para el slot activo; las entradas
`VBMeta-A/B` y `VBMeta-System-A/B` son explícitas y no aparecen como destinos de
backup ni wipe. La interfaz avisa que una imagen AVB incompatible puede impedir
arrancar Android. El primer intento cancela la operación y muestra la advertencia;
un segundo swipe confirma el mismo archivo y destino. La confirmación se asocia a
la ruta, archivo y partición exactos y se consume antes de escribir. Esto no certifica
que la imagen sea correcta. El workflow comprueba las seis entradas en ambas tablas
`twrp.flags`. El flash real de `vbmeta_a` sigue pendiente.

## Batería, vibración y temperatura

El servicio vendor.recovery-hardware inicia únicamente el ADSP esperado con
adsp.mdt, usando modem montado en solo lectura. No reinicia un DSP activo ni
modifica firmware seleccionado, calibraciones o políticas de carga.
En b8.1, el log confirmó salida 0 del servicio y aparición de la batería en frío.

Haptic usa duration_aw y activate_aw directamente, con ajustes habilitados.
El HAL vendor.qti.vibrator sigue deshabilitado por el antecedente de lag táctil.
El usuario confirmó vibración; queda revisar todas las duraciones desde la UI.
haptic_ram.bin proviene del stock del dispositivo y se publicó con autorización:
SHA-256 e446c67665c16cca99ded8d07a9cc016277a25b5cf0a7203254f8157fddc96ee.

La temperatura usa exclusivamente cpuss-0-0, descubierto por nombre. En b8.1 el
sensor entregaba valores, pero TWRP había fijado tw_no_cpu_temp=1 antes de que
apareciera el archivo temporal. late-cpu-sensor.patch conserva la lectura habilitada para
TW_CUSTOM_CPU_TEMP_PATH, respeta TW_NO_CPU_TEMP explícito y mantiene la caché.

El servicio independiente vendor.recovery-cpu busca el sensor hasta 30 veces,
sin bloquear la UI ni esperar al ADSP. Publica la lectura de cpuss-0-0 como un
archivo regular en /tmp/nx733j-cpu-temp cada dos segundos. Esto evita que
DataManager dependa de permisos para seguir un enlace hacia sysfs. Si falta el
sensor o falla la publicación, informa el fallo sin sustituirlo por un sensor
PMIC. La prueba simulada comprueba detección inmediata y tardía, rechazo de
PMIC, publicación y error de escritura.

## Resultados de la CLI

cli-result.patch transmite el resultado de ORS al cliente twrp y a la acción GUI.
Una instalación ZIP fallida devuelve 1; una terminada correctamente devuelve 0.
No intenta conservar el código original de update-binary (por ejemplo, 42).
Una conexión cerrada sin resultado válido también devuelve error.

El cliente conserva la salida completa, rechaza comandos que exceden el límite
de línea ORS o contienen saltos de línea, y evita un bucle de espera que consuma
CPU continuamente. Se corrige además el resultado invertido de getcap.
El caso especial de sideload mantiene el regreso al menú y transmite su resultado
real a la CLI. El comportamiento de scripts de arranque permanece igual.

Cliente y recovery deben proceder del mismo build: el resultado se transmite
mediante un trailer binario por el FIFO, separado del texto del instalador.
La prueba compila el cliente real con FIFOs temporales y el dispatcher/callback
GUI con dependencias simuladas. No equivale a una prueba de instalación real;
otros comandos ORS conservan la semántica de errores del motor upstream.

## Diagnóstico

Ejecutar desde el PC:

```sh
adb shell /system/bin/sh /sbin/nx733j-diagnose.sh
```

Informe de lectura: versión, slot de arranque, reloj UTC, USB, batería, ADSP,
haptics, sensor CPU y su enlace, bloques/tamaños y montajes relevantes.
Las temperaturas indican unidades: batería en décimas de grado, CPU en miligrados.
Distingue sensor/enlace ausentes y lectura no disponible. Una sección opcional
de logs vacía no provoca un código de error. No recoge archivos personales.
Un servicio oneshot en estado stopped puede haber terminado correctamente:
consultar el código de salida en el log.

## Compilación

El workflow principal es .github/workflows/build-validation.yml, manual en
GitHub hosted ubuntu-22.04. Sincroniza TWRP 16, aplica los parches y ejecuta
sus pruebas antes de compilar. Usa m recoveryimage -j4, Soong limitado a 10 GiB,
swap de 16 GiB y caché comprimida del compilador de hasta 5 GB.

Publica únicamente recovery-NX733J-<sha>.img durante 14 días. Identificación,
revisiones, SHA-256, duración y estadísticas quedan en el resumen de Actions.
Cada build muestra by Draki b<run_number>.<run_attempt>-<sha>; local sin archivo
generado muestra by Draki local. No se inicia Actions al subir un commit.

Antes del upload se verifica tamaño máximo de recovery (104857600 bytes) y
presencia de los intérpretes usados por los scripts/hooks dentro del ramdisk.
Todos los hooks usan /system/bin/sh: este ramdisk no trae /sbin/sh.
Los scripts se instalan en /sbin para que montar vendor no los oculte.

Manifest: https://github.com/TWRP-Test/platform_manifest_twrp_aosp, rama twrp-16.0.
Device path: device/nubia/NX733J. El workflow antiguo build.yml depende de un
runner propio y no es el flujo usado para estas validaciones.
