#!/system/bin/sh
# Run by OrangeFox/TWRP right before "Power Off" (TWFunc::tw_reboot,
# rb_poweroff). Make the next power-on boot the OS instead of recovery.
/system/bin/gts8u-normalboot
exit 0
