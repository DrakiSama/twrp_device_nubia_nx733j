# Continuidad — temperatura CPU en TWRP NX733J

Continúa el trabajo en `DrakiSama/twrp_device_nubia_nx733j`, branch `twrp-16.0`. Lee primero este resumen y revisa el commit `878ad4341d060f8f77555779072cb30525532c09`; no reviertas ni sustituyas cambios de otros agentes.

## Síntoma y diagnóstico

El teléfono está conectado en TWRP por ADB. Ejecuta `adb devices -l` y confirma el dispositivo antes de pruebas. Build instalado: `b15.1-20c8970`, slot `_b`. `tw_no_cpu_temp=0`; `/tmp/nx733j-cpu-temp` era un enlace a `/sys/class/thermal/thermal_zone27/temp`, tipo `cpuss-0-0`, con valores cercanos a 45 °C. La barra del recovery mostraba `CPU: °C`. El enlace y el sensor funcionan desde shell, pero no se confirmó que la ruta dinámica de DataManager pudiera leerlos desde el contexto que actualiza la UI. Los destinos vbmeta están visibles y no se deben alterar en este arreglo.

## Cambio subido

En `878ad43`, `vendor.recovery-cpu` ahora descubre `cpuss-0-0` y mantiene un archivo regular `/tmp/nx733j-cpu-temp` actualizado cada 2 s, con reemplazo atómico, en vez de terminar después de crear un symlink a sysfs. El servicio init quedó como proceso persistente. Diagnósticos y README describen el archivo publicado. Pruebas simuladas cubren sensor inmediato/tardío, ausencia, rechazo de PMIC y error de publicación.

Pruebas locales en WSL: `test-cpu-discovery.py` (5 escenarios), `test-late-cpu-sensor.py` (3 configuraciones) y `sh -n` pasaron. PowerShell no tenía `sh`, `g++` ni GitHub CLI; por eso el tests de C++ se ejecutó en WSL.

## Build y próxima acción

Se hizo push y se despachó GitHub Actions `build-validation.yml` para el SHA `878ad4341d060f8f77555779072cb30525532c09`. Run: `37139677597`, inicialmente `in_progress`. Verifica ese run antes de iniciar otro. Cuando complete, si falla, revisa el error concreto, corrige y repite; si pasa, descarga el artefacto `.img` y comparte la ruta/enlace. No flashees el teléfono automáticamente. El usuario debe instalar el IMG y confirmar si aparece la temperatura en la barra. Si todavía queda en blanco, recoger `adb shell cat /tmp/nx733j-cpu-temp`, `adb shell twrp get tw_no_cpu_temp`, `adb shell twrp get tw_cpu_temp` y logs filtrados `nx733j-cpu` / `ReadFileToString`; evita volcar datos personales de `/data/media`.

La inferencia sobre permisos del symlink todavía no está demostrada; este cambio la evita publicando una lectura en tmpfs para TWRP. No describas la corrección como verificada en hardware hasta probar el build nuevo.
