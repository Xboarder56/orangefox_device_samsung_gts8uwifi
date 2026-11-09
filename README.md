# OrangeFox Recovery for the Galaxy Tab S8 Ultra Wi-Fi (SM-X900)

Unofficial [OrangeFox Recovery](https://gitlab.com/OrangeFox) for the **Samsung Galaxy Tab S8
Ultra Wi-Fi** (`SM-X900`, codename `gts8uwifi`, Snapdragon 8 Gen 1). Built from OrangeFox
`fox_16.0` (Android 16 base) with Samsung's own recovery kernel and drivers, so the screen,
touch, USB and storage behave like stock.

> Only for the **Wi-Fi model SM-X900**. Do not flash it on the 5G model (SM-X906) or any
> other tablet.

## What works

Everything you normally use a recovery for:

- Display and touch (portrait, USB port at the bottom), brightness, screen timeout, double-tap to wake
- adb and MTP over USB, microSD card
- Backup and restore, installing zips
- Mounting system, vendor, product and the other partitions inside `super`
- Reboot to system, recovery or Download Mode, and power off
- Battery, CPU temperature, flashlight, vibration, clock

Not working yet: Wi-Fi and decrypting Android's /data.
USB-OTG drives are untested. The full list is in [STATUS.md](STATUS.md).

## Before you start

- **Your bootloader must be unlocked.** Unlocking permanently trips Knox (Samsung Pass,
  Secure Folder and similar stop working for good) and wipes the tablet.
- **Back up anything you care about.** Flashing a recovery does not erase data, but the
  steps around it (unlocking, formatting) can.
- **Running Linux on the tablet?** If your Linux system lives on the userdata partition
  (for example a postmarketOS or Fedora port), OrangeFox shows it as Internal Storage.
  **Never use Format Data or Wipe Data** - it erases your Linux install.

## Download

Get the latest files from the [Releases](../../releases) page:

| File | Use it with |
|---|---|
| `OrangeFox-...-gts8uwifi.img.tar` | Odin (Windows) or odin4 |
| `OrangeFox-...-gts8uwifi.img` | Heimdall, `dd`, or flashing from an existing recovery |
| `OrangeFox-...-gts8uwifi.zip` | updating from inside OrangeFox (Menu -> Install) |

## Install

### Option A: Windows with Odin

1. Turn the tablet off. Hold **Volume Up + Volume Down** and plug in the USB cable. Press
   **Volume Up** on the warning screen to enter Download Mode.
2. Open Odin, put the `.img.tar` file in the **AP** slot, and **untick Auto Reboot**
   (Options tab).
3. Press **Start** and wait for **PASS**.
4. Boot into OrangeFox right away (see below). Otherwise stock Android may replace it with
   the stock recovery on its first boot.

### Option B: Mac or Linux with Heimdall

```sh
heimdall flash --RECOVERY OrangeFox-...-gts8uwifi.img --no-reboot
```

Then boot into OrangeFox (see below).

If Heimdall or Odin fail with "pipe stalled" or "Failed to download PIT", **try a
different USB cable** first. A bad cable causes exactly these errors.

### Option C: you already have root (Linux or rooted Android)

```sh
dd if=OrangeFox-...-gts8uwifi.img of=/dev/disk/by-partlabel/recovery bs=4M conv=fsync
```

On Android the path is `/dev/block/by-name/recovery`.

## Booting into OrangeFox

- **From power off or a reboot:** hold **Power + Volume Up** until the Samsung logo
  appears, then let go.
- **From Download Mode:** hold **Power + Volume Down** for about 7 seconds until the
  screen goes black, then immediately switch to **Power + Volume Up**.
- **From a running system:** `adb reboot recovery`.

To leave, use **Reboot -> System** or **Power Off** inside OrangeFox. Both make the next
start boot your system normally.

## Tips

- **Wrong clock?** Android users get the correct time automatically. On other setups, set
  it once from a computer while OrangeFox is running; it stays correct afterwards:

  ```sh
  adb shell gts8u-time set $(date +%s)
  ```

- **Encrypted data:** this recovery cannot decrypt Samsung's encryption. To flash ROMs on
  stock Android, the usual route is to flash multidisabler and Format Data once.
- **Reporting a problem:** `adb pull /tmp/recovery.log` while OrangeFox is running. If adb
  does not work, run `adb shell touch /cache/fox-debug/enable` once (or create that file from
  another OS); later boots then save logs to `/cache/fox-debug/`.
- **Going back to stock:** flash your firmware's stock `recovery.img` the same way you
  installed OrangeFox.

## Building (developers)

The build host must be x86_64 Linux (the AOSP prebuilts are x86_64 only) with about
100 GB of free disk. On an Apple Silicon Mac, a `linux/amd64` Docker container with
Rosetta works.

```sh
mkdir ~/fox_16.0 && cd ~/fox_16.0
repo init --depth=1 -u https://gitlab.com/OrangeFox/Manifest.git -b fox_16.0
repo sync -c -j8 --no-clone-bundle --no-tags
git clone https://github.com/Xboarder56/orangefox_device_samsung_gts8uwifi -b fox_16.0 device/samsung/gts8uwifi

export FOX_BUILD_DEVICE=gts8uwifi
source build/envsetup.sh
lunch twrp_gts8uwifi-bp2a-eng
rm -rf "$OUT/recovery"   # restage the ramdisk so rebuilt libraries are picked up
mka recoveryimage
```

Outputs land in `out/target/product/gts8uwifi/`.

### Updating the stock base

The kernel, DTB, recovery DTBO and all vendor modules come from one stock recovery image,
so they always match. To move to another firmware:

```sh
./extract-prebuilts.py SAMFW.COM_SM-X900_..._fac.zip   # or AP_*.tar.md5, recovery.img(.lz4)
```

This rewrites `prebuilt/`, `recovery/root/lib/modules/` and `stock.mk`.

### How the image is put together

| | |
|---|---|
| Recovery partition | dedicated `RECOVERY` (non-A/B), 100 MiB |
| Image format | boot header v2: kernel + ramdisk + recovery DTBO + DTB, then Samsung's `SEANDROIDENFORCE` marker and an AVB hash footer |
| Kernel and modules | stock Samsung GKI 5.10 from the stock recovery, loaded by first-stage init (`modules.load.recovery`) |
| Display | 2960x1848 panel scanned out landscape; the portrait theme is rotated 270 degrees |
| Touch | Goodix GT6936, portrait coordinates matching that UI 1:1 |
| Power off | `poweroff.sh` writes Samsung's NORMALBOOT restart reason so the next start leaves recovery |

The recovery partition is chained to Samsung's key in `vbmeta`. This image is signed with
the AOSP test key and boots on an unlocked bootloader without changing `vbmeta`; if your
firmware refuses it, flash a `vbmeta` with verification disabled.

## Credits and licensing

- Device tree: Apache-2.0 (see [LICENSE](LICENSE)).
- `prebuilt/kernel` is Samsung's GPL-2.0 kernel binary. Its source is published at
  [opensource.samsung.com](https://opensource.samsung.com/) (search `SM-X900`).
- The kernel modules and DTBs are extracted unmodified from Samsung's stock firmware.
- Thanks to the OrangeFox team, the gts8wifi OrangeFox and TWRP trees
  (`gts8wifi-orangefox-dev`, `samsung-sm8450-dev`) and afaneh92's gts8u TWRP work.
