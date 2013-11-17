# How to 

## build uefi custom usb stick
```
    sudo ./build_hyb_uefi.sh
    sudo dd if=iso/custom-debian-7.2.0-amd64-firmware-uefi.iso of=/dev/sdX bs=4M; sync
```
