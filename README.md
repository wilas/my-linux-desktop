# Description

Simple bash scripts to build quickly custom hybrid ISO images with own preseed/kickstart file. Useful for hands-off installation.
You can use later these images to create bootable usb stick.

# Child steps

## build uefi boot custom usb stick
```
    sudo ./build_hyb_uefi.sh
    sudo dd if=iso/custom-debian-7.2.0-amd64-firmware-uefi.iso of=/dev/sdX bs=4M; sync
```

## build legancy bios boot custom usb stick
```
    sudo ./build_hyb_bios.sh
    sudo dd if=iso/custom-debian-7.2.0-amd64-firmware-bios.iso of=/dev/sdX bs=4M; sync
```

# Info

Tested on debian 7 "Wheezy", but with small customization 
(options on the begining of scripts) should works as well for others GNU\Linux (e.g. RHEL and RHEL derivatives).
