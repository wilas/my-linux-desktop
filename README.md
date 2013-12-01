# Description

Set of various scripts to build (bootable ISO images and USB sticks):
 - custom hybrid ISO images with own preseed/kickstart file. (Useful for hands-off installation. You can use later these images to create bootable usb stick.)
 - USB stick with persistence from live-iso

# Info

Prepared for Debian 7 "Wheezy", but with small customizations
(options on the begining of scripts) should works for others GNU\Linux as well.

# Child steps

Note: All data from ```/dev/sdX``` will be removed.

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

## build usb stick from live-iso
```
    sudo ./live2usb.sh /dev/sdX
```

What next:
 - cp firmware to persistence partition (may be needed for your wifi card, etc.)
 - cp bootstrap scripts, e.g. to install CM (ansible/puppet/cfengine/chef), docker
 - cp CM code (playbooks/manifests/promises/cookbooks) - quickly and repeatable tuning the new "live system"
 - above works for non persistence as well, but some space is needed to keep data, e.g. second partition
 - without persistence you have fresh OS after each reboot (to create non-persistence live usb stick change settings in live2usb script, e.g label) 
