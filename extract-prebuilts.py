#!/usr/bin/env python3
#
# Copyright (C) 2026 The OrangeFox gts8uwifi device tree contributors
# SPDX-License-Identifier: Apache-2.0
#
"""Populate this device tree's prebuilts from a stock Samsung SM-X900 firmware.

The kernel, DTB, recovery DTBO and vendor kernel modules all come from the
stock recovery image, so the recovery kernel always matches its modules.

Accepted inputs (any one):
  recovery.img                         raw stock recovery image
  recovery.img.lz4                     as found inside the AP tarball
  AP_X900....tar.md5                   Samsung AP tarball
  SAMFW...zip / any zip holding AP_*   full firmware download

Writes:
  prebuilt/kernel             uncompressed arm64 Image
  prebuilt/dtb/stock.dtb      concatenated stock DTBs (header v2 --dtb payload)
  prebuilt/recovery_dtbo      stock recovery DTBO
  recovery/root/lib/modules/  *.ko plus modules.{load.recovery,dep,alias,softdep}
  stock.mk                    firmware id, mkbootimg version args, cmdline

Requires the `lz4` command line tool for compressed inputs.
"""
import argparse
import hashlib
import io
import os
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
MOD_META = ('modules.load.recovery', 'modules.dep', 'modules.alias', 'modules.softdep',
            'modules.blocklist', 'modules.load')


def lz4_decompress(data):
    p = subprocess.run(['lz4', '-dc'], input=data, stdout=subprocess.PIPE, check=True)
    return p.stdout


def recovery_from_tar(fileobj):
    with tarfile.open(fileobj=fileobj, mode='r|') as tar:
        for m in tar:
            name = os.path.basename(m.name)
            if name in ('recovery.img.lz4', 'recovery.img'):
                data = tar.extractfile(m).read()
                return lz4_decompress(data) if name.endswith('.lz4') else data
    sys.exit('no recovery.img(.lz4) in AP tarball')


def load_recovery(path):
    if zipfile.is_zipfile(path):
        with zipfile.ZipFile(path) as z:
            ap = [n for n in z.namelist() if os.path.basename(n).startswith('AP_')]
            if not ap:
                sys.exit(f'{path}: no AP_* tarball inside')
            print(f'  reading {ap[0]} from zip (streams until recovery.img is found)')
            with z.open(ap[0]) as fh:
                return recovery_from_tar(fh)
    if path.endswith('.tar') or path.endswith('.tar.md5'):
        with open(path, 'rb') as fh:
            return recovery_from_tar(fh)
    with open(path, 'rb') as fh:
        data = fh.read()
    return lz4_decompress(data) if data[:4] in (b'\x04\x22\x4d\x18', b'\x02\x21\x4c\x18') else data


def parse_bootimg(d):
    if d[:8] != b'ANDROID!':
        sys.exit('not an Android boot image')
    ksz, kaddr, rsz, raddr, ssz, saddr, tags, page, ver, osv = struct.unpack_from('<10I', d, 8)
    if ver != 2:
        sys.exit(f'expected boot header v2, got v{ver}')
    rdo_sz, _rdo_off, _hdr = struct.unpack_from('<IQI', d, 1632)
    dtb_sz, dtb_addr = struct.unpack_from('<IQ', d, 1648)
    pages = lambda n: (n + page - 1) // page * page
    off = page
    out = {}
    for name, size in (('kernel', ksz), ('ramdisk', rsz), ('second', ssz),
                       ('recovery_dtbo', rdo_sz), ('dtb', dtb_sz)):
        out[name] = d[off:off + size]
        off += pages(size)
    out['hdr'] = dict(
        kernel_addr=kaddr, ramdisk_addr=raddr, tags_addr=tags, dtb_addr=dtb_addr, page=page,
        board=d[48:64].rstrip(b'\0').decode(),
        cmdline=(d[64:576] + d[608:1632]).rstrip(b'\0').decode(),
        os_version='%d.%d.%d' % ((osv >> 25) & 0x7f, (osv >> 18) & 0x7f, (osv >> 11) & 0x7f),
        os_patch_level='%d-%02d' % (((osv & 0x7ff) >> 4) + 2000, osv & 0xf))
    return out


def cpio_entries(data):
    """Yield (name, mode, payload) from a newc cpio archive."""
    off = 0
    while off + 110 <= len(data):
        if data[off:off + 6] not in (b'070701', b'070702'):
            raise ValueError(f'bad cpio magic at {off}')
        f = [int(data[off + 6 + i * 8: off + 14 + i * 8], 16) for i in range(13)]
        mode, filesize, namesize = f[1], f[6], f[11]
        name_start = off + 110
        name = data[name_start:name_start + namesize - 1].decode()
        off = (name_start + namesize + 3) & ~3
        payload = data[off:off + filesize]
        off = (off + filesize + 3) & ~3
        if name == 'TRAILER!!!':
            return
        yield name, mode, payload


def firmware_id(cmdline_ramdisk_props):
    m = re.search(rb'ro\.build\.PDA=(\S+)', cmdline_ramdisk_props)
    return m.group(1).decode() if m else 'unknown'


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('source', help='recovery.img, recovery.img.lz4, AP tar(.md5) or firmware zip')
    args = ap.parse_args()

    print(f'Loading {args.source}')
    img = load_recovery(args.source)
    parts = parse_bootimg(img)
    hdr = parts['hdr']
    if (hdr['kernel_addr'], hdr['ramdisk_addr'], hdr['tags_addr'], hdr['dtb_addr'], hdr['page']) != \
            (0x8000, 0x2000000, 0x1e00000, 0x1f00000, 4096):
        sys.exit(f'unexpected load addresses/page size {hdr}; update BoardConfig.mk first')

    rd = parts['ramdisk']
    if rd[:4] in (b'\x02\x21\x4c\x18', b'\x04\x22\x4d\x18'):
        rd = lz4_decompress(rd)
    elif rd[:2] == b'\x1f\x8b':
        import gzip
        rd = gzip.decompress(rd)

    pre = os.path.join(HERE, 'prebuilt')
    moddir = os.path.join(HERE, 'recovery', 'root', 'lib', 'modules')
    for p in (pre, moddir):
        shutil.rmtree(p, ignore_errors=True)
    os.makedirs(os.path.join(pre, 'dtb'))
    os.makedirs(moddir)

    def write(path, data):
        with open(path, 'wb') as o:
            o.write(data)

    write(os.path.join(pre, 'kernel'), parts['kernel'])
    write(os.path.join(pre, 'dtb', 'stock.dtb'), parts['dtb'])
    write(os.path.join(pre, 'recovery_dtbo'), parts['recovery_dtbo'])

    props = b''
    nmods = 0
    for name, mode, payload in cpio_entries(rd):
        base = os.path.basename(name)
        if name in ('prop.default', 'default.prop') and (mode & 0o170000) == 0o100000:
            props += payload
        if not name.startswith('lib/modules/') or (mode & 0o170000) != 0o100000:
            continue
        if base.endswith('.ko') or base in MOD_META:
            write(os.path.join(moddir, base), payload)
            nmods += base.endswith('.ko')
    if not os.path.exists(os.path.join(moddir, 'modules.load.recovery')):
        sys.exit('stock ramdisk has no lib/modules/modules.load.recovery')

    fw = firmware_id(props)
    kver = re.search(rb'Linux version (\S+)', parts['kernel'])
    kver = kver.group(1).decode() if kver else 'unknown'
    sha = hashlib.sha256(img).hexdigest()
    with open(os.path.join(HERE, 'stock.mk'), 'w') as o:
        o.write(f'''# Generated by extract-prebuilts.py -- do not edit by hand.
# Source: stock recovery.img of {fw} (sha256 {sha})
# Kernel: {kver}
GTS8U_STOCK_FIRMWARE := {fw}
GTS8U_STOCK_KERNEL_VERSION := {kver}
GTS8U_STOCK_BOARD := {hdr['board']}
GTS8U_STOCK_OS_VERSION := {hdr['os_version']}
GTS8U_STOCK_OS_PATCH_LEVEL := {hdr['os_patch_level']}
GTS8U_STOCK_CMDLINE := {hdr['cmdline']}
''')
    print(f'  firmware        {fw}')
    print(f'  kernel          {kver} ({len(parts["kernel"])} bytes)')
    print(f'  dtb / dtbo      {len(parts["dtb"])} / {len(parts["recovery_dtbo"])} bytes')
    print(f'  modules         {nmods} .ko')
    print(f'  header          {hdr["os_version"]} / {hdr["os_patch_level"]}  board {hdr["board"]}')
    print('Wrote prebuilt/, recovery/root/lib/modules/ and stock.mk')


if __name__ == '__main__':
    main()
