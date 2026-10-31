#!/system/bin/sh
# Installation checks and permissions. Install through the Magisk app.
[ "$BOOTMODE" = true ] || abort "Install from the Magisk app in Android, not from recovery."
[ "$ARCH" = arm64 ] || abort "This module requires ARM64."
[ -e /sys/class/sec/tsp2/input/enabled ] || abort "The expected cover touchscreen was not found."
CURRENT=$(sha256sum /system/lib64/libpowermanager.so) || abort "Could not read the current library."
CURRENT=${CURRENT%% *}
case "$CURRENT" in
  ba4d80650124ba0bc5e97cdaf5ba69e1c22fa650648f0f9f5d6cb60fd17da6b6|5adf98068c1eebaaa324572cd4c9eedd9946d9aa64c1d5a96f4ef006e5263a00) ;;
  *) abort "Unsupported library. This patch will not be installed. SHA256: $CURRENT" ;;
esac
PAYLOAD=$(sha256sum "$MODPATH/system/lib64/libpowermanager.so") || abort "Could not verify the patch."
PAYLOAD=${PAYLOAD%% *}
[ "$PAYLOAD" = 5adf98068c1eebaaa324572cd4c9eedd9946d9aa64c1d5a96f4ef006e5263a00 ] || abort "The patched library checksum does not match."
set_perm "$MODPATH/system/lib64/libpowermanager.so" 0 0 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
ui_print "Compatible library. Two instructions patched: policy 0 -> -1."
ui_print "Reboot to activate. You can disable this module in Magisk."
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/cover-events.sh" 0 0 0755
ui_print "Includes automatic cover display recovery at boot and on lid closure."
ui_print "Updates flip3_touch_policy; do not install duplicate copies of the patch."
