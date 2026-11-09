#
# Copyright (C) 2026 The OrangeFox gts8uwifi device tree contributors
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Inherit common TWRP/OrangeFox configuration
$(call inherit-product, vendor/twrp/config/common.mk)

# Inherit from the device configuration
$(call inherit-product, device/samsung/gts8uwifi/device.mk)

PRODUCT_DEVICE := gts8uwifi
PRODUCT_NAME := twrp_gts8uwifi
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-X900
PRODUCT_MANUFACTURER := samsung
PRODUCT_RELEASE_NAME := Galaxy Tab S8 Ultra Wi-Fi
