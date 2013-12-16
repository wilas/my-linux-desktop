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

# Helps build custom hybrid mbr iso image

# secure bash
set -e -E -u -o pipefail; shopt -s failglob;

# Load custom settings
. "./build_hyb.cfg"
output_image="${output_image//%TYPE%/bios}"

# Global settings
# useful when some part of code are commented or clean_up_build=0
tmp_isomount=""
# where build custom image
build_iso_dir="${os_type}-iso-build"
# lowercase os_type and OS specific configurations
os_type=$(printf "${os_type}" | tr '[:upper:]' '[:lower:]')
case "${os_type}" in
    "debian")
        # destination bootstrap file (kickstart/preseed) - this is relative path to build_iso_dir
        bootstrap_cfg="preseed.cfg"
        boot_options="preseed\/file=\/cdrom\/${bootstrap_cfg} auto=true priority=critical"
        boot_menu_cfg="${build_iso_dir}/isolinux/txt.cfg"
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

function prepare_iso_build {
    if [[ -d ${build_iso_dir} ]]; then
        # nothing to do
        printf "[INFO] ${build_iso_dir} already exists.\n"
        return 0
    fi
    # create tmp directory for iso mount
    tmp_isomount=$(TMPDIR=. mktemp -d)
    mkdir -p "${build_iso_dir}"
    mount -o loop "${boot_file_src_path}/${boot_file}" "${tmp_isomount}"
    # Why not 7z and extract iso to build_iso_dir ?
    # because 7z has problem with symlinks (v9.20)
    rsync -v -a -H "${tmp_isomount}/" "${build_iso_dir}/"
    umount "${tmp_isomount}"
    rm -rf "${tmp_isomount}"
}

function deploy_custom_bootstrap_cfg {
    cp -H "${bootstrap_cfg_src}" "${build_iso_dir}/${bootstrap_cfg}"
    if ! grep -qw "${boot_options}" "${boot_menu_cfg}"; then
        chmod 644 "${boot_menu_cfg}"
        sed -i "s/\(append\)/\1 ${boot_options}/" "${boot_menu_cfg}"
    fi
    # update md5sum.txt file - this is a good practice, not a must have
    pushd "${build_iso_dir}"
        find -type f -exec md5sum {} \; > md5sum.txt
    popd
}

function build_mbr_hybrid {
    printf "[INFO] Making ${output_image} hybrid ISO image...\n"
    xorriso -as mkisofs \
        -r -J \
        -V "${output_image_volid}" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -isohybrid-mbr "${boot_file_src_path}/${boot_file}" \
        -o "${output_image}" \
        "${build_iso_dir}"
}

function clean_up {
    if [[ ${clean_up_build} -eq 0 ]]; then
        return 0
    fi
    if [[ -d "${build_iso_dir}" ]]; then
        rm -rf "${build_iso_dir}"
    fi
    if [[ -d "${tmp_isomount}" ]]; then
        if mount | grep -qw "${tmp_isomount}"; then
            umount "${tmp_isomount}"
        fi
        rm -rf "${tmp_isomount}"
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
        "xorriso:xorriso"
        "rsync:rsync"
        "openssl:openssl"
        "md5sum:coreutils"
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
# check whether we have everything to start with script
dependencies_check
# signals and error handler
trap signal_clean_up SIGHUP SIGINT SIGTERM ERR

download_iso
prepare_iso_build
deploy_custom_bootstrap_cfg
build_mbr_hybrid
clean_up
