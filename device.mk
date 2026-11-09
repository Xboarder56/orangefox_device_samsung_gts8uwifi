#
# Copyright (C) 2026 The OrangeFox gts8uwifi device tree contributors
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/samsung/gts8uwifi

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# The SM-X900 launched with Android 12 (vendor freeze level 31)
PRODUCT_SHIPPING_API_LEVEL := 31
BOARD_SHIPPING_API_LEVEL := 31

# Dynamic partitions (Samsung "super", non-A/B)
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# The recovery-only build ships a prebuilt kernel without config metadata
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# IANA tzdata for bionic. Without any tzdata file bionic prints
# "__bionic_open_tzdata: couldn't find any tzdata" on every process start
# (every adb shell command) once a timezone is set.
PRODUCT_COPY_FILES += \
    system/timezone/output_data/iana/tzdata:$(TARGET_COPY_OUT_RECOVERY)/root/system/usr/share/zoneinfo/tzdata
