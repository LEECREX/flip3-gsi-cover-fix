#!/system/bin/sh
# Non-blocking boot service. Wait for Android, verify the mount, detect SW_LID.
# The instance lock in /dev is cleared on reboot. Reboot after disabling.
MODDIR=${0%/*}
LOGFILE="$MODDIR/cover-service.log"
LOCK=/dev/flip3-cover-service.lock
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
trap 'exit 0' INT TERM HUP

[ ! -f "$LOGFILE" ] || mv -f "$LOGFILE" "$LOGFILE.1"
printf '%s\n' "Waiting for Android to finish booting. Context: $(id)" > "$LOGFILE"
while [ "$(getprop sys.boot_completed)" != 1 ]; do
    [ ! -f "$MODDIR/disable" ] || exit 0
    [ ! -f "$MODDIR/remove" ] || exit 0
    sleep 2
done
[ ! -f "$MODDIR/disable" ] || exit 0
[ ! -f "$MODDIR/remove" ] || exit 0
[ ! -f "$MODDIR/skip_mount" ] || exit 0

CURRENT=$(sha256sum /system/lib64/libpowermanager.so 2>/dev/null)
CURRENT=${CURRENT%% *}
if [ "$CURRENT" != 5adf98068c1eebaaa324572cd4c9eedd9946d9aa64c1d5a96f4ef006e5263a00 ]; then
    printf '%s\n' "ERROR: patched library is not mounted: $CURRENT. Service stopped." >> "$LOGFILE"
    exit 1
fi

SELECTED=
CANDIDATE=
COUNT=0
for DEVICE in /dev/input/event*; do
    CAPS=$(getevent -lp "$DEVICE" 2>/dev/null) || continue
    case "$CAPS" in *SW_LID*) ;; *) continue ;; esac
    COUNT=$((COUNT + 1))
    CANDIDATE=$DEVICE
    NAME=$(cat "/sys/class/input/${DEVICE##*/}/device/name" 2>/dev/null)
    if [ "$NAME" = flip ]; then
        SELECTED=$DEVICE
        break
    fi
done
if [ -z "$SELECTED" ] && [ "$COUNT" = 1 ]; then
    SELECTED=$CANDIDATE
fi
if [ -z "$SELECTED" ]; then
    printf '%s\n' "ERROR: SW_LID sensor is missing or ambiguous ($COUNT candidates)." >> "$LOGFILE"
    exit 1
fi
printf '%s\n' "Patched library verified. Sensor: $SELECTED" >> "$LOGFILE"
/system/bin/sh "$MODDIR/cover-events.sh" "$SELECTED"
RESULT=$?
printf '%s\n' "Service exited: $RESULT. Reboot to start it again." >> "$LOGFILE"
exit "$RESULT"
