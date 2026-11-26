#!/usr/bin/env python3
"""Patch an ad-hoc IPA's declared minimum OS version down to 14.2.

TrollStore bypasses code signing, so modifying the binary does not require
re-signing. We patch:
  - LC_BUILD_VERSION.minos in every Mach-O (app + extensions + frameworks)
  - MinimumOSVersion in every Info.plist

Usage: python3 patch_minos.py <input.ipa> <output.ipa> [minos_string]
"""
import sys, os, zipfile, struct, plistlib, shutil

def encode_version(s):
    parts = s.split(".")
    while len(parts) < 3:
        parts.append("0")
    a, b, c = (int(x) for x in parts[:3])
    return (a << 16) | (b << 8) | c

def patch_macho(data, target_minos):
    if data[:4] not in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe",
                        b"\xfe\xed\xfa\xcf", b"\xfe\xed\xfa\xce"):
        return data, 0
    # Determine endianness + 64-bit
    magic = data[:4]
    is64 = magic in (b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf")
    little = magic in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe")
    endian = "<" if little else ">"
    if is64:
        hdr = 32
    else:
        hdr = 28
    ncmds = struct.unpack_from(endian + "I", data, 16)[0]
    off = hdr
    patched = 0
    for _ in range(ncmds):
        if off + 8 > len(data):
            break
        cmd, cmdsize = struct.unpack_from(endian + "II", data, off)
        if cmd == 0x32:  # LC_BUILD_VERSION
            platform = struct.unpack_from(endian + "I", data, off + 8)[0]
            if platform == 2:  # iOS
                struct.pack_into(endian + "I", data, off + 12, target_minos)
                patched += 1
        elif cmd == 0x24:  # LC_VERSION_MIN_IPHONEOS
            struct.pack_into(endian + "I", data, off + 8, target_minos)
            patched += 1
        if cmdsize < 8:
            break
        off += cmdsize
    return data, patched

def main():
    src, dst = sys.argv[1], sys.argv[2]
    minos = sys.argv[3] if len(sys.argv) > 3 else "14.2"
    target = encode_version(minos)
    tmp = dst + ".tmp"
    nmacho = nplist = 0
    with zipfile.ZipFile(src, "r") as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for info in zin.infolist():
            data = bytearray(zin.read(info.filename))
            name = info.filename
            if name.endswith("Info.plist"):
                try:
                    pl = plistlib.loads(bytes(data))
                    if "MinimumOSVersion" in pl:
                        pl["MinimumOSVersion"] = minos
                        data = bytearray(plistlib.dumps(pl, fmt=plistlib.FMT_BINARY))
                        nplist += 1
                except Exception:
                    pass
            else:
                d, n = patch_macho(bytes(data), target)
                if n:
                    data = bytearray(d)
                    nmacho += n
            zout.writestr(info, bytes(data))
    shutil.move(tmp, dst)
    print(f"patched macho={nmacho} plist={nplist} minos={minos}")

if __name__ == "__main__":
    main()
