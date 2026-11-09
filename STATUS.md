# Hardware test status

Tested 2026-11-05 to 2026-11-09 on an SM-X900 (12 GB, board revision 5, bootloader
X900XXU9DYDC) running OrangeFox R12.0 from `fox_16.0` (Android 16 base) with the
stock X900XXS9EZA3 kernel (5.10.236) and modules. Latest tested build: r14.

| Feature | Status |
|---|---|
| Boots to OrangeFox | works |
| Display (msm_drm, 2960x1848) | works: portrait UI, upright with the USB port at the bottom |
| Touch (Goodix GT6936) | works: measured 1:1 (clock tap at raw 188,82; battery at 1610,71) |
| Screen timeout / blank | works; wake with the Power key (see tap-to-wake below) |
| Brightness | works (0-395) |
| Battery level / charging | works |
| CPU temperature | works (`cpuss-0`, thermal_zone25) |
| Clock | works: Android users get the time from /persist/time/ats_2 automatically; otherwise run `adb shell gts8u-time set $(date +%s)` once and the offset is kept on the cache partition |
| Flashlight | works (led:torch_0 + led:switch_2; the driver limits the torch to 250) |
| Vibration | works (Samsung dc_vibrator through timed_output) |
| adb (USB) | works |
| MTP | works (adb and MTP together) |
| Mounts: system, system_ext, product, vendor, odm, vendor_dlkm (super) | works (dm-linear, read-only f2fs) |
| Mounts: metadata, cache, efs, sec_efs, persist, firmware, prism, optics | works |
| MicroSD (`mmcblk1`) | works |
| Backup | works; images match the partitions byte for byte |
| Restore | works (recovery partition restored, hash unchanged) |
| Zip install | works (test zip ran its update-binary) |
| Reboot to system / recovery / download | works |
| Power off | works: the next power-on boots the OS (poweroff.sh writes PON NORMALBOOT) |
| Reboot to fastboot | hidden (Samsung has no bootloader fastboot) |
| Tap to wake | works: double-tap wakes the blanked screen while the panel is truly off (owner-verified, r13) |
| USB-OTG storage | not yet tested |
| Wi-Fi | not implemented (needs the qca_cld3 host module from vendor_dlkm) |
| /data decryption (Samsung FBE) | not supported; on Android use multidisabler + Format Data. Never format on Linux-on-USERDATA setups |

Notes:
- Entering recovery with `reboot recovery` from another OS makes Samsung's bootloader
  keep choosing recovery until recovery reboots or powers off through OrangeFox. A forced
  key-combo restart does not clear it.
- On devices whose USERDATA holds a Linux root filesystem, OrangeFox mounts it as
  /data and keeps its settings in `<root>/media/Fox`. Never use Format Data there.
