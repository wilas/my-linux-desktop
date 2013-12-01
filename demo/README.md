# Description

Build Virtualbox demo using already created custom ISOs. Demo as [vbkick](https://github.com/wilas/vbkick) definition.

# Howto

Install vbkick, creates custom images and continue with instruction below.

## changes definition (change the target of a symlink)
```
    ln -fs definition-7.2-x86_64-desktop-bios.cfg definition.cfg
```

## creates demo box
```
    vbkick help
    vbkick build       demo_box
    vbkick postinstall demo_box # run postinstall scripts, e.g. install VBox guest additions
    vbkick validate    demo_box # run validate scripts, e.g. guest additions version
    vbkick ssh         demo_box # play time: parted /dev/sda print; gdisk -l /dev/sda; fdisk -l /dev/sda; vgdisplay, lvdisplay
    vbkick destroy     demo_box
```

Note: more Debian stable/testing/unstable definitions may be find [here](https://github.com/wilas/vbkick-boxarium).
