#
# Copyright (C) 2026 The OrangeFox gts8uwifi device tree contributors
# SPDX-License-Identifier: Apache-2.0
#
# Build the recovery image the way Samsung lays out the stock one:
#   header v2 payloads | "SEANDROIDENFORCE" | padding | AVB vbmeta + footer
# The header carries the stock os_version/os_patch_level (stock.mk) so the
# bootloader sees the same values it accepts from the stock recovery.

GTS8U_MKBOOTIMG_VERSION_ARGS := \
    --os_version $(GTS8U_STOCK_OS_VERSION) \
    --os_patch_level $(GTS8U_STOCK_OS_PATCH_LEVEL)

$(INSTALLED_RECOVERYIMAGE_TARGET): $(recoveryimage-deps) $(RECOVERYIMAGE_EXTRA_DEPS) $(DEVICE_PATH)/stock.mk
	$(call pretty,"Target recovery image: $@")
	$(MKBOOTIMG) $(INTERNAL_RECOVERYIMAGE_ARGS) $(GTS8U_MKBOOTIMG_VERSION_ARGS) \
	    $(BOARD_RECOVERY_MKBOOTIMG_ARGS) --output $@
	$(hide) printf 'SEANDROIDENFORCE' >> $@
	$(call assert-max-image-size,$@,$(call get-hash-image-max-size,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE)))
	$(AVBTOOL) add_hash_footer --image $@ \
	    $(call get-partition-size-argument,$(BOARD_RECOVERYIMAGE_PARTITION_SIZE)) \
	    --partition_name recovery $(INTERNAL_AVB_RECOVERY_SIGNING_ARGS) \
	    $(BOARD_AVB_RECOVERY_ADD_HASH_FOOTER_ARGS)
	@echo "Made Samsung recovery image: $@"

# This tree only ships a recovery; keep a boot image rule so targets that
# reference it still resolve.
$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_FILES) $(BOOTIMAGE_EXTRA_DEPS)
	$(call pretty,"Target boot image: $@")
	$(MKBOOTIMG) $(INTERNAL_BOOTIMAGE_ARGS) $(GTS8U_MKBOOTIMG_VERSION_ARGS) \
	    $(BOARD_MKBOOTIMG_ARGS) --output $@
	$(hide) printf 'SEANDROIDENFORCE' >> $@
