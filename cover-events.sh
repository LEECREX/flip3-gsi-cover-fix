#!/system/bin/sh
# Event-driven cover display recovery. Preserve the tested v4 cycle and delays.
# Apply one initial cycle when starting closed; keep one bounded backup log.
# Restore any pending device-state override when the event reader exits.
MODDIR=${0%/*}
LOGFILE="$MODDIR/cover-service.log"
log() {
    if [ -f "$LOGFILE" ]; then
        SIZE=$(wc -c < "$LOGFILE")
        if [ "$SIZE" -ge 65536 ]; then
            mv -f "$LOGFILE" "$LOGFILE.1"
        fi
    fi
    printf '%s\n' "$*" >> "$LOGFILE"
}
EVENT=${1:-/dev/input/event5}
CAPS=$(getevent -lp "$EVENT" 2>&1)
if [ "$?" != 0 ]; then
    log "ERROR: could not read the capabilities of $EVENT:"
    log "$CAPS"
    exit 1
fi
case "$CAPS" in
    *SW_LID*) ;;
    *)
        log "ERROR: $EVENT does not advertise SW_LID. No recovery cycle will be applied."
        log "$CAPS"
        exit 1
        ;;
esac
log "Service: lid closure -> recover cover display -> sleep."
if [ "${FLIP3_KEEP_ON:-0}" = 1 ]; then
    log "Alternative mode: leave the cover display awake after recovery."
fi

monitor_events() {
OVERRIDE=0
cleanup() {
    trap - EXIT INT TERM HUP
    if [ "$OVERRIDE" = 1 ]; then
        cmd device_state state reset >/dev/null 2>&1
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

LAST=
log "Listening on $EVENT. Context: $(id)"

while IFS= read -r LINE; do
    case "$LINE" in
        *SW_LID*00000000*)
            LAST=open
            log "Lid opened."
            ;;
        *SW_LID*00000001*)
            [ "$LAST" != closed ] || continue
            LAST=closed
            log "Lid closure detected. Waiting for the normal display transition..."
            sleep 0.4
            STATE=$(cmd device_state print-state 2>/dev/null)
            if [ "$STATE" != 0 ]; then
                log "Skipped: current state is not CLOSE (value: $STATE)."
                continue
            fi
            input keyevent 224 || continue
            sleep 0.2
            STATE=$(cmd device_state print-state 2>/dev/null)
            if [ "$STATE" != 0 ]; then
                log "Skipped: the phone is no longer in CLOSE state."
                continue
            fi
            OVERRIDE=1
            cmd device_state state 3
            RESULT=$?
            cmd device_state state reset
            RESET_RESULT=$?
            if [ "$RESET_RESULT" = 0 ]; then OVERRIDE=0; fi
            if [ "$RESULT" != 0 ] || [ "$RESET_RESULT" != 0 ]; then
                log "ERROR applying or resetting device state. Stopping the service."
                exit 1
            fi
            log "Recovery cycle applied; physical device state restored."
            if [ "${FLIP3_KEEP_ON:-0}" != 1 ]; then
                sleep 0.5
                STATE=$(cmd device_state print-state 2>/dev/null)
                if [ "$STATE" = 0 ]; then
                    if input keyevent 223; then
                        log "Cover display ready and asleep. Press the power button to wake it."
                    else
                        log "ERROR: display recovered, but the sleep command failed."
                    fi
                else
                    log "Sleep skipped: the phone is no longer closed."
                fi
            fi
            ;;
    esac
done

log "Sensor event stream ended."
return 1
}

{
    if [ "$(cmd device_state print-state 2>/dev/null)" = 0 ]; then
        printf '%s\n' 'SW_LID 00000001'
    fi
    getevent -lt "$EVENT" 2>/dev/null
} | monitor_events
