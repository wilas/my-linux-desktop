```
$ gdisk -l /dev/sdc

GPT fdisk (gdisk) version 0.8.4

Partition table scan:
  MBR: MBR only
  BSD: not present
  APM: not present
  GPT: present

Found valid MBR and GPT. Which do you want to use?
 1 - MBR
 2 - GPT
 3 - Create blank GPT

Your answer: 1
Disk /dev/sdc: 7819264 sectors, 3.7 GiB
Logical sector size: 512 bytes
Disk identifier (GUID): 2641040C-18AA-40F6-AE3D-7BD145FD32AD
Partition table holds up to 128 entries
First usable sector is 34, last usable sector is 7819230
Partitions will be aligned on 8-sector boundaries
Total free space is 7818301 sectors (3.7 GiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   2          124712          125607   448.0 KiB   EF00  EFI System
```
