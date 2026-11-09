#
# Copyright (C) 2026 The OrangeFox gts8uwifi device tree contributors
# SPDX-License-Identifier: Apache-2.0
#
# OrangeFox build environment for the Galaxy Tab S8 Ultra Wi-Fi (gts8uwifi).
# Sourced by build/envsetup.sh.

FDEVICE="gts8uwifi"

__gts8u_apply_patch() {
    local repo="$1" patch="$2"
    [ -f "$patch" ] && [ -d "$repo" ] || return 0
    if git -C "$repo" apply --reverse --check "$patch" >/dev/null 2>&1; then
        return 0 # already applied
    fi
    if git -C "$repo" apply --check "$patch" >/dev/null 2>&1; then
        git -C "$repo" apply "$patch" && echo "$FDEVICE: applied $(basename "$patch")"
    else
        echo "$FDEVICE: WARNING: $(basename "$patch") does not apply to $repo"
    fi
}

__gts8u_setup() {
    local top="${ANDROID_BUILD_TOP:-$(gettop 2>/dev/null)}"
    [ -n "$top" ] || top="$(pwd)"
    local dt="$top/device/samsung/$FDEVICE"
    # Apply any patches the tree carries for bootable/recovery
    local p
    for p in "$dt"/patches/*.patch; do
        [ -e "$p" ] && __gts8u_apply_patch "$top/bootable/recovery" "$p"
    done

    export FOX_BUILD_DEVICE="$FDEVICE"
    export FOX_TARGET_DEVICES="$FDEVICE"
    export TARGET_DEVICE_ALT="gts8uwifi,gts8uwifixx,SM-X900"
    export FOX_RECOVERY_INSTALL_PARTITION="/dev/block/by-name/recovery"
    export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
    export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
    export FOX_SAMSUNG_DEVICE=1
    export FOX_USE_BASH_SHELL=1
    export FOX_USE_NANO_EDITOR=1
    export FOX_USE_TAR_BINARY=1
    export FOX_USE_SED_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export FOX_ENABLE_APP_MANAGER=0
    export FOX_DELETE_AROMAFM=1
    # Double-tap to wake. The GT6936 keeps reporting touches while OrangeFox
    # powers the panel off, so OrangeFox's GUI double-tap detector works with
    # real blanking. The GUI reads this from the environment (any non-empty
    # value); "panel_off" rather than "1" avoids orangefox.mk's make-side
    # check, which assumes the panel stays lit (TW_NO_SCREEN_BLANK).
    export FOX_NO_BLANK_DT2W=panel_off
    export OF_MAINTAINER="${OF_MAINTAINER:-gts8uwifi}"
    local fw
    fw="$(sed -n 's/^GTS8U_STOCK_FIRMWARE := //p' "$dt/stock.mk" 2>/dev/null)"
    export FOX_VARIANT="${FOX_VARIANT:-${fw:-stock}}"
    export FOX_BUILD_TYPE="${FOX_BUILD_TYPE:-Unofficial}"
}

if [ "$1" = "$FDEVICE" ] || [ "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
    __gts8u_setup
fi
