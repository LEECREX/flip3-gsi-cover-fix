#!/system/bin/sh
# Check the base library before Magisk mounts modules. Disable on mismatch.
MODDIR=${0%/*}
CURRENT=$(sha256sum /system/lib64/libpowermanager.so 2>/dev/null)
CURRENT=${CURRENT%% *}
case "$CURRENT" in
  ba4d80650124ba0bc5e97cdaf5ba69e1c22fa650648f0f9f5d6cb60fd17da6b6|5adf98068c1eebaaa324572cd4c9eedd9946d9aa64c1d5a96f4ef006e5263a00) ;;
  *)
    touch "$MODDIR/skip_mount" "$MODDIR/disable"
    echo "Incompatible library: $CURRENT. Module disabled before mounting." > "$MODDIR/compatibility.log"
    ;;
esac
