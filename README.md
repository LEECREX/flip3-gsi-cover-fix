# Flip3 GSI - Cover Display and Touch Fix

A Magisk module for the Samsung Galaxy Z Flip3 5G (SM-F711B / b2q).

## What works and how

This module combines two fixes: working cover touchscreen input and automatic recovery of a cover display that stays black after folding on the tested GSI.

The touch fix patches two instructions in `libpowermanager.so`: Samsung's touchscreen policy argument changes from `0` to `-1`, while the original screen on/off argument is preserved. Magisk overlays the patched library without overwriting the system partition.

After Android boots, a service detects the lid sensor and listens for closure events. Once per closure, it wakes the display, briefly requests device state `3`, then resets the override to the real physical state. This clears the residual black display layer seen on the tested device. It then puts the cover display to sleep; press the power button to wake it. Startup with the lid already closed is handled too. A brief flash may occur during recovery.

**Resolution, density, font size, rotation, launcher, and navigation settings are left to the user.** The module does not fix UI layout problems introduced by separate scaling adjustments.

## Tested by the maintainer

Lecrex tested the original version on their own **SM-F711B**, with **Project Infinity X 3.12 GSI (Android 16, ARM64 A/B with GApps)**, **Samsung Android 15 / One UI 7 vendor F711BXXSJJZH3**, and **Magisk 31.1**. Cover display recovery and touch input worked, including unlocking and using apps.

The English 2.0.1 package preserves the functional shell instructions and patched library from that working version; branding, messages, comments and documentation were updated.

Other devices and builds have not been tested. The same mechanism may help another matching setup, but that is an expectation, not verified compatibility. The installer deliberately rejects unrecognized libraries.

## Download and install

Download **`flip3-gsi-cover-fix-v2.0.1.zip`** from [Releases](https://github.com/LEECREX/flip3-gsi-cover-fix/releases/latest). Use that asset, rather than GitHub's automatically generated source archives.

1. Open **Magisk → Modules → Install from storage** and select the module ZIP.
2. Reboot and wait for Android to finish booting.
3. Close the phone, wait briefly, and press the power button to use the cover display.

Install from the Magisk app in Android, not from recovery. The ID remains `flip3_touch_policy`: this updates the previous module with that ID. Cancel any pending removal before updating. Do not run another cover recovery service alongside it.

Daily use requires only Magisk and the phone's existing Android tools. No PC, ADB, internet connection, separate BusyBox installation, or additional module is needed.

## Disable and troubleshoot

Disable or remove the module in Magisk, then **reboot** to stop the running service and remove the library overlay.

Optional ADB diagnostics:

```sh
adb shell "su -c 'cat /data/adb/modules/flip3_touch_policy/cover-service.log'"
adb shell "su -c 'sha256sum /system/lib64/libpowermanager.so'"
```

The original library must have SHA256 `ba4d80650124ba0bc5e97cdaf5ba69e1c22fa650648f0f9f5d6cb60fd17da6b6`. The patched library must have SHA256 `5adf98068c1eebaaa324572cd4c9eedd9946d9aa64c1d5a96f4ef006e5263a00`.

The library is 366456 bytes. Exactly eight bytes change at offsets `0x28810` and `0x298e0`: `e2 03 1f 2a` becomes `02 00 80 12` at each offset. Before mounting, a compatibility check disables the module if the base library no longer matches. This is not a bootloop detector. Recovery access to `/data` was not available on the tested setup, so recovery-based removal is not guaranteed.

## References

- [Samsung touch-policy patch documented by the Fold3 GSI project](https://github.com/jaso1000/Fold3-LineageOS/blob/master/notes/procedure.md)
- [Magisk module developer guide](https://topjohnwu.github.io/Magisk/guides.html)

This project is not affiliated with Samsung, Magisk, or Project Infinity X.
