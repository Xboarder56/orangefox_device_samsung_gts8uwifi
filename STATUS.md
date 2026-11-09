# Hardware test status

Tested 2026-11-05/06 on an SM-X900 (12 GB, board revision 5, bootloader
X900XXU9DYDC) running OrangeFox R12.0 from `fox_16.0` (Android 16 base) with the
stock X900XXS9EZA3 kernel (5.10.236) and modules.

| Feature | Status |
|---|---|
| Boots to OrangeFox | works |
| Display (msm_drm, 2960x1848, portrait UI) | works: upright with the USB port at the bottom |
| Touch (Goodix GT6936) | works: taps land where touched (owner-confirmed) |
| Screen timeout / blank | works; the touch panel is off while blanked, so wake with Power |
| Brightness | works (0-395) |
| Battery level / charging | works |
| CPU temperature | works (`cpuss-0`, thermal_zone25) |
| adb (USB) | works |
| MTP | works (adb and MTP together) |
| Mounts: system, system_ext, product, vendor, odm, vendor_dlkm (super) | works (dm-linear, read-only f2fs) |
| Mounts: metadata, cache, efs, sec_efs, persist, firmware, prism, optics | works |
| MicroSD (`mmcblk1`) | works |
| Backup (boot, dtbo, vbmeta) | works; images match the partitions byte for byte |
| Reboot to system / recovery, power off | works |
| Reboot to fastboot | option hidden from r6 on (Samsung has no bootloader fastboot; it landed in Download Mode) |
| Zip install | not yet tested |
| Restore | not yet tested |
| USB-OTG storage | not yet tested |
| Clock | RTC is read-only from an arbitrary epoch. From r7: `adb shell gts8u-time set $(date +%s)` once; the offset is kept on the cache partition and applied at boot. Untested |
| Flashlight | not enabled yet (needs the Samsung flash sysfs node) |
| Vibration | not enabled yet (`sec_vibrator` loads; haptics path to be wired) |
| Wi-Fi | not yet; needs the qca_cld3 host module from vendor_dlkm and image space |
| Power off | works, but does not clear Samsung's boot-recovery flag; with a charger attached the tablet powers back on into recovery. Use Reboot -> System first |
| Timezone | `UTC0` has no tzdata entry; to be fixed |
| /data decryption (Samsung FBE) | not supported |

Notes:
- Entering recovery with `reboot recovery` from another OS makes Samsung's bootloader
  keep choosing recovery until recovery itself reboots (Reboot -> System). A forced
  key-combo restart does not clear it.
- On devices whose USERDATA holds a Linux root filesystem, OrangeFox mounts it as
  /data and keeps its settings in `<root>/media/Fox`. Never use Format Data there.
