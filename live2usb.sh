#!/bin/bash

# The MIT License
#
# Copyright (c) 2013, Kamil Wilas (wilas.pl)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

# Helps build usb stick with persistence from live-iso

# secure bash
set -e -E -u -o pipefail; shopt -s failglob;

# Load custom settings
. "./live.cfg"

# Global settings
# where build usb live partition
build_live_dir="build-live-usb"
# where build usb persistence partition
build_persistence_dir="build-persistence-usb"
# lowercase os_type and OS specific configurations
os_type=$(printf "${os_type}" | tr '[:upper:]' '[:lower:]')
case "${os_type}" in
    "debian7")
        boot_options="persistence"
        boot_menu_cfg="${build_live_dir}/syslinux/live.cfg"
        persistence_label="persistence"
        #persistence_dir="/home"
        persistence_dir="/ union"
        persistence_cfg="persistence.conf"
        ;;
    *)
        printf "[ERROR] '${os_type}' is not supported.\n"
        exit 1
        ;;
esac


# functions
function download_iso {
    # check whether boot_file_src exist
    if [[ ! -d "${boot_file_src_path}" ]]; then
        mkdir -p "${boot_file_src_path}"
    fi
    local boot_file_src_file="${boot_file_src_path}/${boot_file}"
    if [[ ! -f "${boot_file_src_file}" ]]; then
        curl -Lk "${boot_file_src}" -o "${boot_file_src_file}"
    fi
    # verify boot_file_src checksum
    local get_checksum=$(openssl "${boot_file_checksum_type}" "${boot_file_src_file}" | cut -d" " -f 2)
    if [[ "${boot_file_src_checksum}" != "${get_checksum}" ]]; then
        printf "[WARNING] CHECKSUM is different then expected !\n"
        read -r -p "Do you want continue? [y/N]" ans
        if [[ ! $ans =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        printf "[INFO] CHECKSUM:${boot_file_src_checksum} is valid.\n"
    fi
}

function check_device {
    if ! sgdisk -p "${device}" > /dev/null 2>&1 && ! fdisk -l ${device} > /dev/null 2>&1; then
        printf "[ERROR] '${device}' device not found. Terminating...\n"
        exit 1
    fi
}

function umount_device {
    if ! mount | grep ${device}; then
        return 0
    fi
    # Why not automatically unmount all partitions ? 
    # For security reason: double check that device given as arg. is correct, and you are aware that all data will be removed.
    printf "[ERROR] '${device}' is still mounted -  unmount to continue, e.g. 'umount /dev/sdc1'.\n"
    exit 1
}

function make_persistent_live_usb {
    # creates partitions, filesystems, install mbr, bootloader and copy proper data
    # this will remove all partitions from device
    printf "[INFO] creating ${device}1.\n"
    parted -s "${device}" mklabel msdos
    parted -s "${device}" mkpart primary fat32 1 1536M
    printf "[INFO] creating ${device}2.\n"
    parted -s "${device}" mkpart primary ext4 1536M 100%
    parted -s "${device}" set 1 boot on
    sync

    # install mbr
    printf "[INFO] installing mbr.\n"
    if [[ -f "/usr/lib/syslinux/mbr.bin" ]]; then
        dd if="/usr/lib/syslinux/mbr.bin" of="${device}"
    elif [[ -f "/usr/share/syslinux/mbr.bin" ]]; then
        dd if="/usr/share/syslinux/mbr.bin" of="${device}"
    else
        printf "[ERROR] mbr source not found. Terminating...\n"
        exit 1
    fi
    
    # make filesystems
    printf "[INFO] making filesystems.\n"
    mkdosfs -nLive "${device}1" > /dev/null
    mkfs.ext4 -q -L"${persistence_label}" "${device}2"

    # install bootloader
    printf "[INFO] installing bootloader.\n"
    syslinux "${device}1"

    # extract data from iso
    mkdir -p "${build_live_dir}"
    mount "${device}1" ${build_live_dir}
    pushd "${build_live_dir}"
        # 7z has problem with symlinks v9.20 what is ok, 
        # as fat32 doesn't support neither symlinks nor hardlinks.
        7z x "../${boot_file_src_path}/${boot_file}"
        mv isolinux syslinux
        mv syslinux/isolinux.cfg syslinux/syslinux.cfg
    popd
    sed -i "s/\(append boot=.*\)$/\1 ${boot_options}/" "${boot_menu_cfg}"

    # prepare persistence partition with proper config
    mkdir -p "${build_persistence_dir}"
    mount "${device}2" "${build_persistence_dir}"
    printf "${persistence_dir}\n" > "${build_persistence_dir}/${persistence_cfg}"

    # umount
    umount "${build_live_dir}"
    umount "${build_persistence_dir}"
    clean_up
}

function make_persistent_live_usb_dd {
    # useful when custom live-iso was created via lb (live-build); Note: don't forget about persistence boot option.
    # steps: dd iso to $device and then creates persistence partition;
    printf "Not implemented yet."
    exit 1
}

function clean_up {
    if [[ ${clean_up_build} -eq 0 ]]; then
        return 0
    fi
    if [[ -d "${build_live_dir}" ]]; then
        if mount | grep -qw "${build_live_dir}"; then
            umount "${build_live_dir}"
        fi
        rm -rf "${build_live_dir}"
    fi
    if [[ -d "${build_persistence_dir}" ]]; then
        if mount | grep -qw "${build_persistence_dir}"; then
            umount "${build_persistence_dir}"
        fi
        rm -rf "${build_persistence_dir}"
    fi
}

function signal_clean_up {
    printf "[INFO] Signal/Error handler - cleanup before exiting...\n"
    clean_up
    exit 1
}

function dependencies_check {
    local dependencies=(
        "curl:curl"
        "parted:parted"
        "fdisk:util-linux"
        "sgdisk:gdisk"
        "7z:p7zip-plugins or p7zip-full"
        "openssl:openssl"
        "syslinux:syslinux"
        "tr:coreutils"
    )
    for depend in "${dependencies[@]}"; do
        local dep_cmd="${depend%%:*}"
        local dep_name="${depend##*:}"
        # check whether dep_name is installed - dep_cmd command exist
        if ! command -v $dep_cmd >/dev/null 2>&1; then
            printf "[ERROR] '${dep_cmd}' command doesn't exist - install '${dep_name}' to continue.\n"
            exit 1
        fi
    done
}


# MAIN
if [[ $# -ne 1 ]]; then
    printf "Usage: $0 device (e.g. /dev/sdc)\n"
    exit 1
fi
device="${1}"

# check whether we have everything to start with script
dependencies_check
# signals and error handler
trap signal_clean_up SIGHUP SIGINT SIGTERM ERR

download_iso
check_device
umount_device
make_persistent_live_usb
