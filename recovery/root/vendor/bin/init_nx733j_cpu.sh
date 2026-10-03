#!/system/bin/sh
# Probe order varies. Wait independently of ADSP and never substitute a PMIC sensor.
# Publish a regular file in tmpfs instead of a sysfs symlink: DataManager runs in
# the recovery process context, which may not be allowed to follow thermal sysfs
# links even when the init shell can read them.
report() { echo "nx733j-cpu: $*" > /dev/kmsg; }
attempt=0
sensor=
while [ "$attempt" -lt 30 ]; do
    attempt=$((attempt + 1))
    for zone in /sys/class/thermal/thermal_zone*; do
        [ -r "$zone/type" ] || continue
        [ "$(cat "$zone/type")" = cpuss-0-0 ] || continue
        [ -r "$zone/temp" ] || continue
        sensor="$zone/temp"
        break
    done
    [ -n "$sensor" ] && break
    [ "$attempt" -eq 30 ] || sleep 1
done
[ -n "$sensor" ] || { report 'CPU sensor cpuss-0-0 not available after 30 probes'; exit 1; }

report "CPU sensor available: ${sensor%/temp}"
while :; do
    if [ -r "$sensor" ]; then
        value=$(cat "$sensor" 2>/dev/null)
        case "$value" in
            ''|*[!0-9]*) ;;
            *)
                # Rename atomically so TWRP never observes a partial value.
                if printf '%s\n' "$value" > /tmp/nx733j-cpu-temp.new &&
                        mv -f /tmp/nx733j-cpu-temp.new /tmp/nx733j-cpu-temp; then
                    :
                else
                    report 'Unable to publish CPU temperature in tmpfs'
                    exit 1
                fi
                ;;
        esac
    fi
    sleep 2
done
