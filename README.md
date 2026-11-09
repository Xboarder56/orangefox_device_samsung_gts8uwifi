# OrangeFox device tree for the Samsung Galaxy Tab S8 Ultra Wi-Fi (SM-X900)

Device tree for building [OrangeFox Recovery](https://gitlab.com/OrangeFox) for the
**Galaxy Tab S8 Ultra Wi-Fi** (`SM-X900`, codename `gts8uwifi`, Qualcomm SM8450 "taro").

| | |
|---|---|
| OrangeFox branch | `fox_16.0` |
| Recovery partition | dedicated `RECOVERY` (non-A/B), 100 MiB |
| Image format | boot header v2: kernel + ramdisk + recovery DTBO + DTB, Samsung `SEANDROIDENFORCE` trailer, AVB hash footer |
| Kernel | stock Samsung GKI 5.10, from the stock recovery image |
| Kernel modules | stock vendor modules from the same image, loaded by first-stage init (`modules.load.recovery`) |
| Display | 2960×1848 landscape OLED (`msm_drm`); OrangeFox's portrait UI is rotated 90° |
| Touch | Goodix GT6936 (`goodix_ts_berlin`), rotated with the UI |

## Status

See [STATUS.md](STATUS.md) for what has been tested on hardware.

## Requirements on the tablet

- **Unlocked bootloader** (OEM unlock). This permanently trips Knox.
- Samsung's `vbmeta` chains the `recovery` partition to Samsung's key. The image is
  signed with the AOSP test key, so it boots only on an unlocked bootloader.
  Flash a `vbmeta` with verification disabled if your firmware refuses to boot it.

## Building

```sh
mkdir ~/fox_16.0 && cd ~/fox_16.0
repo init --depth=1 -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync -c -j8 --no-clone-bundle --no-tags
git clone <this repo> device/samsung/gts8uwifi

export FOX_BUILD_DEVICE=gts8uwifi
source build/envsetup.sh          # also applies patches/ to bootable/recovery
lunch twrp_gts8uwifi-bp2a-eng
mka recoveryimage
```

Outputs in `out/target/product/gts8uwifi/`: `recovery.img`, an Odin-flashable
`OrangeFox-*.tar`, and the OrangeFox installer zip.

The build host must be x86_64 Linux (the AOSP prebuilts are x86_64 only). On an
Apple Silicon Mac, an `linux/amd64` Docker container with Rosetta works.

## Updating the stock base

All prebuilts come from one stock recovery image, so the kernel always matches its
modules. To move to another firmware:

```sh
./extract-prebuilts.py SAMFW.COM_SM-X900_XAR_X900XXS9EZA3_fac.zip   # or AP_*.tar.md5, recovery.img(.lz4)
```

This rewrites `prebuilt/`, `recovery/root/lib/modules/` and `stock.mk` (firmware id,
header `os_version`/`os_patch_level`, kernel command line). The image header uses the
stock version fields so the bootloader sees what it accepts from stock.

## Flashing

Enter Download Mode (power off, hold Volume Up + Volume Down, plug in USB), then:

```sh
heimdall flash --RECOVERY recovery.img --no-reboot
# or Odin / odin4: AP slot -> OrangeFox-*.tar
```

Then hold **Power + Volume Up** right after the screen goes dark to boot into recovery
instead of the OS.

To go back, flash the stock `recovery.img` the same way.

## Patches

`patches/0001-minuitwrp-rotate-touch-with-TW_ROTATION.patch` adds an opt-in
`TW_ROTATE_TOUCH` build flag to minuitwrp. With it, touch coordinates get the inverse
of the `TW_ROTATION` drawing transform, which a landscape-native panel running the
portrait theme needs. `vendorsetup.sh` applies it.

## Credits and licensing

- Device tree: Apache-2.0 (see [LICENSE](LICENSE)).
- `prebuilt/kernel` is Samsung's GPL-2.0 kernel binary. Its source is published at
  [opensource.samsung.com](https://opensource.samsung.com/) (search `SM-X900`).
- The kernel modules and DTBs are extracted unmodified from Samsung's stock firmware.
- References: the gts8wifi OrangeFox and TWRP trees by `gts8wifi-orangefox-dev` and
  `samsung-sm8450-dev`, and afaneh92's gts8u TWRP work.
