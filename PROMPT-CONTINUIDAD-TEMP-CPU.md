# Continuidad — temperatura CPU en TWRP NX733J

Continúa el trabajo en `DrakiSama/twrp_device_nubia_nx733j`, branch `twrp-16.0`. Lee primero este resumen y revisa el commit `878ad4341d060f8f77555779072cb30525532c09`; no reviertas ni sustituyas cambios de otros agentes.

## Síntoma y diagnóstico

El teléfono está conectado en TWRP por ADB. Ejecuta `adb devices -l` y confirma el dispositivo antes de pruebas. Build instalado: `b15.1-20c8970`, slot `_b`. `tw_no_cpu_temp=0`; `/tmp/nx733j-cpu-temp` era un enlace a `/sys/class/thermal/thermal_zone27/temp`, tipo `cpuss-0-0`, con valores cercanos a 45 °C. La barra del recovery mostraba `CPU: °C`. El enlace y el sensor funcionan desde shell, pero no se confirmó que la ruta dinámica de DataManager pudiera leerlos desde el contexto que actualiza la UI. Los destinos vbmeta están visibles y no se deben alterar en este arreglo.

## Cambio subido

En `878ad43`, `vendor.recovery-cpu` ahora descubre `cpuss-0-0` y mantiene un archivo regular `/tmp/nx733j-cpu-temp` actualizado cada 2 s, con reemplazo atómico, en vez de terminar después de crear un symlink a sysfs. El servicio init quedó como proceso persistente. Diagnósticos y README describen el archivo publicado. Pruebas simuladas cubren sensor inmediato/tardío, ausencia, rechazo de PMIC y error de publicación.

Pruebas locales en WSL: `test-cpu-discovery.py` (5 escenarios), `test-late-cpu-sensor.py` (3 configuraciones) y `sh -n` pasaron. PowerShell no tenía `sh`, `g++` ni GitHub CLI; por eso el tests de C++ se ejecutó en WSL.

## Build y próxima acción

Se hizo push y se despachó GitHub Actions `build-validation.yml` para el SHA `878ad4341d060f8f77555779072cb30525532c09`. Run: `37139677597`, inicialmente `in_progress`. Verifica ese run antes de iniciar otro. Cuando complete, si falla, revisa el error concreto, corrige y repite; si pasa, descarga el artefacto `.img` y comparte la ruta/enlace. No flashees el teléfono automáticamente. El usuario debe instalar el IMG y confirmar si aparece la temperatura en la barra. Si todavía queda en blanco, recoger `adb shell cat /tmp/nx733j-cpu-temp`, `adb shell twrp get tw_no_cpu_temp`, `adb shell twrp get tw_cpu_temp` y logs filtrados `nx733j-cpu` / `ReadFileToString`; evita volcar datos personales de `/data/media`.

## Comprobación del teléfono (3 oct 2026)

El usuario aclaró que Fastboot está capado en el NX733J; no volver a intentar `fastboot boot`. El intento anterior lo sacó de TWRP temporalmente, pero ya reconectó el teléfono en TWRP. Sigue ejecutando `b15.1-20c8970`, no la nueva imagen. En la build antigua, `init.svc.vendor.recovery-cpu=stopped`, el symlink apunta a `thermal_zone30` (`cpuss-0-0`) y entrega aproximadamente 53 °C, `tw_no_cpu_temp=0` y `twrp get tw_cpu_temp` devuelve vacío. La nueva build `878ad43` aún no se prueba en el teléfono.

Esta recovery no trae `screencap` ni expone `/dev/fb0`; no se obtuvo captura visual por ADB. La lectura de `tw_cpu_temp` por CLI tampoco prueba lo que el renderer dibuja. Para verificar el arreglo en pantalla, el usuario debe instalar la imagen nueva desde TWRP y confirmar la barra. Artefacto local: `G:\Celular\twrp\compiled\878ad43\recovery-NX733J-878ad43.img`; SHA-256 `A282838C3CF6FA7F9A85C9E99A9402DBCB1442796FC3405816A7E40B8810827D`.

La inferencia sobre permisos del symlink todavía no está demostrada; este cambio la evita publicando una lectura en tmpfs para TWRP. No describas la corrección como verificada en hardware hasta probar el build nuevo.

## Diagnóstico de calentamiento en TWRP (3 oct 2026)

Usuario informa que tras >30 min en TWRP el teléfono se calienta más que en Android. ADB estaba conectado con `b15.1-20c8970`, uptime observado 21 min (por tanto esta sesión no reprodujo aún el umbral de 30 min). Tres muestras de `top` mostraron ~799–800% idle en 8 CPU y procesos de recovery esencialmente 0% CPU; no parece carga sostenida de TWRP. `policy0` y `policy6` estaban ambas en governor `performance`, con frecuencias reportadas iguales al máximo (3.532 GHz / 4.32 GHz), y no aparecían servicios de Android Power HAL ni thermal-engine en recovery. Zonas iniciales llegaron a ~74.4 °C en un sensor de cluster, `skin-msm-therm` ~40.6 °C, batería 35 °C; batería 100%, Charging, current_now variable entre -1.12 A y -0.72 A.

Prueba sólo en RAM: ambas políticas aceptaron `schedutil`. Tras ~45 s, con CPU aún ~799% idle, temperaturas cpuss muestreadas bajaron aproximadamente 5–7 °C y skin ~0.9 °C; la corriente de carga también varió, así que el resultado sugiere beneficio pero no aísla governor de carga/enfriamiento. Estado actual de la sesión: schedutil permanece aplicado a policy0 y policy6 hasta reiniciar. No se guardó ningún cambio al dispositivo ni al árbol para esta prueba. Si se implementa, agregar servicio/init de una sola ejecución que aplique `schedutil` después de que aparezcan las policies y validar en RAM; mantener los límites thermal del kernel intactos. Comparar con TWRP desenchufado/Android para distinguir corriente de carga y ambiente. No afirmar que se reprodujeron 30 min; uptime medido fue 21 min.

## Validación de build nueva (3 oct 2026, tras reinicio del usuario)

El usuario instaló `recovery-NX733J-878ad43.img`; ADB confirma `3.7.1_16-by Draki b16.1-878ad43`, uptime de 1 min en la primera consulta y servicio `vendor.recovery-cpu=running`. `/tmp/nx733j-cpu-temp` es un archivo regular; su contenido cambió de `50900` a `51300` en seis segundos. `twrp get tw_no_cpu_temp` devuelve 0 y `twrp get tw_cpu_temp` devuelve `50`, confirmando la lectura dinámica desde TWRP en hardware; la barra debería mostrar aproximadamente 50 °C. No se obtuvo imagen de pantalla: `screencap` no está disponible en esta recovery. El governor volvió a `performance` después del reinicio (policy0 3.532 GHz, policy6 4.32 GHz), por lo que la prueba RAM de `schedutil` no es persistente. Temperaturas tras ~1 min: skin 38.9 °C, batería 33 °C, cpuss 52.9/57.4/64.3 °C; CPU ~799% idle. No se puede inferir calentamiento después de >30 min de esta sesión corta.
