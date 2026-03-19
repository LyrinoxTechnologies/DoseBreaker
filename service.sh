#!/system/bin/sh

MODPATH=${0%/*}
exec 2>$MODPATH/log.txt
LOGFILE="$MODPATH/log.txt"
PIDFILE="$MODPATH/service.pid"

exec 2>$LOGFILE
set -x

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
# Detect Audio HAL (robust)
# -----------------------------
IS_AIDL=false
IS_HIDL=false

if getprop | grep -q "audio-hal-aidl"; then
    IS_AIDL=true
    log "Audio HAL: AIDL"
elif getprop | grep -q "vendor.audio-hal"; then
    IS_HIDL=true
    log "Audio HAL: HIDL (vendor)"
elif getprop | grep -q "audio-hal"; then
    IS_HIDL=true
    log "Audio HAL: HIDL (generic)"
else
    log "Audio HAL: Unknown"
fi

# -----------------------------
# Detect PSD Resampler Support
# -----------------------------
HAS_PSD=false

if getprop | grep -q "ro.audio.resampler.psd"; then
    HAS_PSD=true
    log "PSD resampler detected"
else
    log "No PSD resampler support"
fi

# -----------------------------
# Apply Audio Props (base)
# -----------------------------
if [ -f "$MODPATH/audio_props.sh" ]; then
    log "Applying base audio props..."
    sh "$MODPATH/audio_props.sh"
    log "Base props applied"
else
    log "No audio_props.sh found"
fi

# -----------------------------
# Safe Resampler Configuration
# -----------------------------
apply_resampler() {

    if [ "$HAS_PSD" = true ]; then
        log "Applying dynamic high-quality resampler"

        # Safe dynamic mode
        setprop af.resampler.quality 7

        # Conservative PSD tuning (maintainer-approved safe range)
        resetprop ro.audio.resampler.psd.enable_at_samplerate 44100
        resetprop ro.audio.resampler.psd.stopband 144
        resetprop ro.audio.resampler.psd.halflength 512
        resetprop ro.audio.resampler.psd.cutoff_percent 100
        resetprop ro.audio.resampler.psd.tbwcheat 0

    else
        log "Applying safe resampler (quality=4)"
        setprop af.resampler.quality 4
    fi
}

# -----------------------------
# Safe Volume / CSD Killer
# -----------------------------
disable_csd() {

    # --- Binder (best effort only) ---
    service call audio 102 >/dev/null 2>&1
    service call audio 198 i32 0 >/dev/null 2>&1
    service call audio 108 f 0.0 >/dev/null 2>&1

    # --- Settings layer (most reliable) ---
    settings put global audio_safe_volume_state 0 >/dev/null 2>&1
    settings put global safe_headset_volume 0 >/dev/null 2>&1

    settings put global audio_safe_csd_enabled 0 >/dev/null 2>&1
    settings put global audio_safe_csd_dose 0 >/dev/null 2>&1

    settings delete global audio_safe_csd_current_value >/dev/null 2>&1
    settings delete global audio_safe_csd_dose_records >/dev/null 2>&1
    settings delete global audio_safe_csd_next_warning >/dev/null 2>&1
    settings delete global audio_safe_media_volume_index >/dev/null 2>&1

    settings put system safe_headset_volume_index 100 >/dev/null 2>&1
}

# -----------------------------
# Initial Execution
# -----------------------------
log "Running initial configuration..."

apply_resampler
disable_csd

log "Initial setup complete"

# -----------------------------
# Enforcement Loop (adaptive)
# -----------------------------
ITERATION=0

log "Entering enforcement loop"

while true; do

    # Stop if module disabled
    if [ -f "$MODPATH/disable" ]; then
        log "Disable flag detected"
        cleanup
    fi

    ITERATION=$((ITERATION + 1))
    log "Run #$ITERATION"

    disable_csd

    # Re-apply resampler occasionally (in case system overrides)
    if [ $((ITERATION % 10)) -eq 0 ]; then
        log "Re-applying resampler config"
        apply_resampler
    fi

    # Adaptive timing:
    # Early boot = aggressive
    # Later = relaxed
    if [ "$ITERATION" -lt 10 ]; then
        SLEEP_TIME=30
    else
        SLEEP_TIME=120
    fi

    sleep "$SLEEP_TIME" &
    wait $! 2>/dev/null
done