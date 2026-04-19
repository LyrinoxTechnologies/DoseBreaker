#!/system/bin/sh

MODPATH=${0%/*}
LOGFILE="$MODPATH/log.txt"
PIDFILE="$MODPATH/service.pid"

# -----------------------------
# Logging
# -----------------------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOGFILE"
}

# -----------------------------
# Cleanup
# -----------------------------
cleanup() {
    log "Service stopping gracefully"
    rm -f "$PIDFILE"
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT SIGHUP

# -----------------------------
# Prevent duplicate instances
# -----------------------------
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    log "Service already running, exiting"
    exit 0
fi
echo $$ > "$PIDFILE"

# -----------------------------
# Wait for boot
# -----------------------------
log "Waiting for boot completion..."

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

log "Boot completed, waiting for system services..."
sleep 40

# Wait for settings provider
until settings get global device_provisioned >/dev/null 2>&1; do
    sleep 2
done

log "System fully ready"

# -----------------------------
# CSD / Safe Volume Killer
# -----------------------------
disable_csd() {
    cmd audio set-sound-dose-value 0.0 >/dev/null 2>&1
    cmd audio reset-sound-dose-timeout >/dev/null 2>&1
    settings put global audio_safe_volume_state 0 >/dev/null 2>&1
    settings put system safe_headset_volume_index 100 >/dev/null 2>&1
}

# -----------------------------
# Initial Execution
# -----------------------------
log "Running initial CSD reset..."
disable_csd
log "Initial setup complete"

# -----------------------------
# Enforcement Loop
# -----------------------------
log "Entering enforcement loop (interval: 300s)"

while true; do

    # Stop if module disabled
    if [ -f "$MODPATH/disable" ]; then
        log "Disable flag detected"
        cleanup
    fi

    sleep 300 &
    SLEEP_PID=$!
    wait $SLEEP_PID 2>/dev/null || true

    log "Resetting CSD accumulator"
    disable_csd

done
