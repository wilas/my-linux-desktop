# Description

Simple bash scripts to build quickly various custom iso images. Tested now only with debian iso.

# Getting Started

todo

# Child steps

## build uefi custom usb stick
```
    sudo ./build_hyb_uefi.sh
    sudo dd if=iso/custom-debian-7.2.0-amd64-firmware-uefi.iso of=/dev/sdX bs=4M; sync
```

# Info

## build_hyb_uefi.sh

Helps create hybrid iso image with own preseed file. Useful for hands-off installation.
You can use later that image to create uefi bootable usb stick.

Name of preseed file: preseed/my_preseed.cfg. It may be symlink to another preseed file.

final output:
```
    ./iso/custom-debian-7.2.0-amd64-firmware-uefi.iso (final iso image)
```

in mean time it creates:
```
    ./debian-initrd-build/ #(to build custom initrd)
    ./debian-iso-build/ #(to build custom iso image)
    ./initrd.gz.custom
```

Note1: I've run this script only on ScientificLinux6, but it should work as well for other GNU/Linux.
Note2: inside script use comments to omit some steps - e.g. if you want only update preseed file (from previous build),
then comment everything, but deploy_custom_initrd and build_uefi_hybrid
