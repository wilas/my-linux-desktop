UEFI

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

Your answer: 2
Using GPT and creating fresh protective MBR.
Warning! Main partition table overlaps the first partition by 64 blocks!
You will need to delete this partition or resize it in another utility.
Disk /dev/sdc: 7819264 sectors, 3.7 GiB
Logical sector size: 512 bytes
Disk identifier (GUID): D98B7B22-DDF1-4A1E-A5D9-78D55CF615EF
Partition table holds up to 248 entries
First usable sector is 64, last usable sector is 538560
Partitions will be aligned on 8-sector boundaries
Total free space is 1 sectors (512 bytes)

Number  Start (sector)    End (sector)  Size       Code  Name
   2            5384            6279   448.0 KiB   0700  ISOHybrid1

```


Legancy BIOS
```
$ fdisl -l /dev/sdc

WARNING: GPT (GUID Partition Table) detected on '/dev/sdc'! The util fdisk doesn't support GPT. Use GNU Parted.


Disk /dev/sdc: 4003 MB, 4003463168 bytes
64 heads, 32 sectors/track, 3818 cylinders
Units = cylinders of 2048 * 512 = 1048576 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x18a84894

   Device Boot      Start         End      Blocks   Id  System
/dev/sdc1   *           1         263      269312   17  Hidden HPFS/NTFS
```
