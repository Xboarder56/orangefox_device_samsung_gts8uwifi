#
# Copyright (C) 2026 The OrangeFox gts8uwifi device tree contributors
# SPDX-License-Identifier: Apache-2.0
#
# Samsung Galaxy Tab S8 Ultra Wi-Fi (SM-X900, "gts8uwifi")
# Qualcomm SM8450 (taro/waipio), non-A/B, dedicated RECOVERY partition,
# boot header v2 recovery image.
#

DEVICE_PATH := device/samsung/gts8uwifi

# Values extracted from the stock recovery image (see extract-prebuilts.py)
include $(DEVICE_PATH)/stock.mk

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a-branchprot
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a75

# Platform
BOARD_VENDOR := samsung
TARGET_BOARD_PLATFORM := taro
TARGET_BOOTLOADER_BOARD_NAME := taro
QCOM_BOARD_PLATFORMS += taro
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_USES_UEFI := true
AB_OTA_UPDATER := false

# Kernel: stock Samsung GKI 5.10 Image, DTB and recovery DTBO, taken from the
# stock recovery image together with its vendor modules.
BOARD_BOOT_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_CMDLINE := $(GTS8U_STOCK_CMDLINE)
BOARD_KERNEL_IMAGE_NAME := Image
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_PREBUILT_RECOVERY_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/recovery_dtbo
BOARD_RAMDISK_USE_LZ4 := true

BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --kernel_offset 0x00008000 --ramdisk_offset 0x02000000
BOARD_MKBOOTIMG_ARGS += --tags_offset 0x01e00000 --dtb_offset 0x01f00000
BOARD_MKBOOTIMG_ARGS += --board $(GTS8U_STOCK_BOARD)

# Samsung-style recovery image: payloads, "SEANDROIDENFORCE", then the AVB
# hash footer at the end of the partition (see bootimg.mk).
BOARD_CUSTOM_BOOTIMG_MK := $(DEVICE_PATH)/bootimg.mk

# Partitions (sizes from the stock PIT)
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_USES_METADATA_PARTITION := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

BOARD_SUPER_PARTITION_SIZE := 11140071424
BOARD_SUPER_PARTITION_GROUPS := samsung_dynamic_partitions
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm vendor_dlkm
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE := 11135877120 # super - 4 MiB

# Verified boot: recovery is a chained partition (rollback location 1) in
# Samsung's vbmeta. Sign with the AOSP test key; an unlocked bootloader accepts
# it in the orange state, as it does for a custom BOOT.
BOARD_AVB_ENABLE := true
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 0
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Recovery
# recovery/root (init scripts, twrp.flags, stock kernel modules). Must be a
# board variable: the recovery ramdisk recipe reads it at Makefile time.
TARGET_RECOVERY_DEVICE_DIRS += $(DEVICE_PATH)
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_USES_MKE2FS := true
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_ROOT_EXTRA_FOLDERS := carrier efs sec_efs optics prism spu keydata keyrefuge
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Android version reported in the build props. The recovery image header
# keeps the stock values from stock.mk (see bootimg.mk).
PLATFORM_VERSION := 16
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)

# TWRP: display. The 2960x1848 panel scans out landscape; the portrait theme
# is drawn rotated 270 degrees, upright with the USB port at the bottom. In
# that frame the Goodix GT6936 (portrait, 1848x2960) maps onto the UI 1:1.
# Measured on SM-X900: with rotation 90 (USB on top) the status-bar clock read
# raw (1706, 2878) and the battery (203, 2883), i.e. both axes reversed.
TW_THEME := portrait_hdpi
TW_ROTATION := 270
TW_FRAMERATE := 60
TW_BRIGHTNESS_PATH := "/sys/class/backlight/panel0-backlight/brightness"
TW_MAX_BRIGHTNESS := 395
TW_DEFAULT_BRIGHTNESS := 200
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone25/temp"
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_STATUS_ICONS_ALIGN := center

# TWRP: device features
TW_HAS_DOWNLOAD_MODE := true
# Samsung GKI 5.10 has configfs gadgets only; recovery/root/init.recovery.usb.rc
# provides adb, mtp, mtp,adb, sideload and fastboot triggers.
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_NO_REBOOT_BOOTLOADER := true
TW_USE_LEGACY_BATTERY_SERVICES := true
TW_USE_MODEL_HARDWARE_ID_FOR_DEVICE_ID := true
TW_EXCLUDE_APEX := true
TW_EXTRA_LANGUAGES := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_LPDUMP := true
TW_INCLUDE_LPTOOLS := true
TW_USE_TOOLBOX := true
TW_BACKUP_EXCLUSIONS := /data/fonts
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# Samsung userdata is FBE + Samsung keymint; decryption is not supported yet.
# Leave crypto out so recovery does not wait for HALs that are not shipped.
TW_INCLUDE_CRYPTO := false

# OrangeFox
OF_SCREEN_H := 1730
OF_STATUS_H := 80
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_USE_LEGACY_BATTERY_SERVICES := 1
OF_NO_SPLASH_CHANGE := 1
OF_FLASHLIGHT_ENABLE := 0
OF_USE_GREEN_LED := 0
OF_ENABLE_LPTOOLS := 1
OF_QUICK_BACKUP_LIST := /boot;/dtbo;/vbmeta;
OF_DEFAULT_TIMEZONE := UTC0
