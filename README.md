# TWRP para Nubia Z70 Ultra (NX733J / PQ84A01)

Árbol en depuración para TWRP 16. El usuario confirmó arranque, touch, ADB,
descifrado con PIN, batería y vibración en el build **b8.1-52997c9**.
Los cambios posteriores todavía necesitan compilación y validación en el teléfono.
No se considera validado el flasheo y arranque de cualquier ROM, ZIP u OTA.

## Estado comprobado y pendientes

- Metadata y userdata F2FS: descifrado metadata/FBE con PIN operativo.
- Siete particiones lógicas EROFS: system, system_ext, product, vendor, odm,
  vendor_dlkm y system_dlkm. No existe odm_dlkm.
- Alias de particiones del slot seleccionado y destinos explícitos A/B.
- El usuario instaló recovery.img desde TWRP. Los logs confirmaron escritura de
  recovery_b a /dev/block/sde60 y hashes A/B iguales tras flash both slots.
- Un ZIP de diagnóstico ejecutó update-binary; otro produjo ERROR 42.
  Estas pruebas no escribieron imágenes ni validan una OTA payload.bin.
- USB observado como mtp,adb. Transferencia MTP, OTG, fastbootd y backup/restore
  siguen pendientes de pruebas completas.
- OTG permanece retirado del fstab: la configuración antigua confundía UFS
  interno con almacenamiento USB. Requiere validar un dispositivo USB real.

## Particiones y flasheo IMG

El fstab de recovery y twrp.flags se mantienen separados del fstab stock Android.
Las lógicas usan logical,slotselect; no dependen de un número dm-N o de un slot fijo.
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
apareciera el enlace. late-cpu-sensor.patch conserva la lectura habilitada para
TW_CUSTOM_CPU_TEMP_PATH, respeta TW_NO_CPU_TEMP explícito y mantiene la caché.

El nuevo servicio independiente vendor.recovery-cpu busca el sensor hasta 30
veces, sin bloquear la UI ni esperar al ADSP. Crea /tmp/nx733j-cpu-temp cuando
el nodo es legible y termina; si falta, informa el fallo sin usar un sensor PMIC.
Probado con sysfs simulado y ejecución manual en RAM. Falta validar el servicio
en un arranque limpio y confirmar la temperatura visible del nuevo build.

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
