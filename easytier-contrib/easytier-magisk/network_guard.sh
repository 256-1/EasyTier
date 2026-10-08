#!/system/bin/sh
MODDIR=${0%/*}
EASYTIER="${MODDIR}/easytier-core"
LOG_FILE="${MODDIR}/log.log"
MIN_INTERVAL=5

get_route() {
    ip route get 8.8.8.8 2>/dev/null \
        | grep -m1 ' dev ' \
        | grep -oE '(via|dev|src) [^ ]+' \
        | sort | tr '\n' ' '
}

last="$(get_route)"
was_down=0
last_restart=0

while true; do
    sleep 2
    cur="$(get_route)"

    if [ -z "$cur" ]; then
        was_down=1
        continue
    fi

    if [ "$cur" = "$last" ] && [ "$was_down" -eq 0 ]; then
        continue
    fi

    now=$(date +%s)
    if [ $((now - last_restart)) -lt "$MIN_INTERVAL" ]; then
        last="$cur"
        was_down=0
        continue
    fi

    if ! pgrep -f "$EASYTIER" >/dev/null; then
        last="$cur"
        was_down=0
        continue
    fi

    echo "[ET] route changed ($(date))" >> "$LOG_FILE"
    echo "  old: $last" >> "$LOG_FILE"
    echo "  new: $cur" >> "$LOG_FILE"
    ip route get 8.8.8.8 2>/dev/null | grep -m1 ' dev ' >> "$LOG_FILE"
    pkill -f "$EASYTIER"
    last="$cur"
    was_down=0
    last_restart=$now
done
