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

# Global settings
boot_file_src_path="iso"
boot_file_src="http://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/7.2.0/amd64/iso-cd/firmware-7.2.0-amd64-netinst.iso"
boot_file="firmware-7.2.0-amd64-netinst.iso"
boot_file_src_checksum="74a675e7ed4a31c5f95c9fc21f63a5e60cc7ed607055773ffb9605e55c4de4cb"
boot_file_checksum_type="sha256"
bootstrap_cfg="bootstrap/my_preseed.cfg"
# name for the new image
output_image="${boot_file_src_path}/custom-debian-7.2.0-amd64-firmware-mbr.iso"
output_image_volid="Custom-debian-7.2.0-amd64"
# where build custom image
BUILD_DIR="debian-iso-build"

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
    if [[ -d ${BUILD_DIR} ]]; then
        # nothing to do
        printf "[INFO] ${BUILD_DIR} already exists.\n"
        return 0
    fi
    # create tmp directory for iso mount
    tmp_isomount=$(TMPDIR=. mktemp -d)
    mkdir -p "${BUILD_DIR}"
    mount -o loop "${boot_file_src_path}/${boot_file}" "${tmp_isomount}"
    rsync -v -a -H "${tmp_isomount}/" "${BUILD_DIR}/"
    umount "${tmp_isomount}"
    rm -rf "${tmp_isomount}"
}

function deploy_custom_bootstrap_cfg {
    cp -H "${bootstrap_cfg}" "${BUILD_DIR}/my_preseed.cfg"
    if ! grep -qw "my_preseed.cfg" "${BUILD_DIR}/isolinux/txt.cfg"; then
        chmod 644 "${BUILD_DIR}/isolinux/txt.cfg"
        sed -r -i "s/(append)/\1 preseed\/file=\/cdrom\/my_preseed.cfg auto=true priority=critical/" \
        "${BUILD_DIR}/isolinux/txt.cfg"
    fi
    # update md5sum.txt file - this is a good practice, not a must have
    pushd "${BUILD_DIR}"
        md5sum $(find -type f) > md5sum.txt
    popd
}

function build_mbr_hybrid {
    printf "[INFO] Making ${output_image} hybrid ISO image...\n"
    #xorriso -indev "${boot_file_src_path}/${boot_file}" 2>&1 | grep "Volume id"
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
        "${BUILD_DIR}"
    # Note: some extra/alternative options:
    #-partition_offset 16 \
    #-r -J -joliet-long -cache-inodes \
    #-isohybrid-mbr "/usr/lib/syslinux/isohdpfx.bin" \
    #-isohybrid-mbr "/usr/share/syslinux/isohdpfx.bin" \
}

function quazi_clean {
    # ugly clean up
    rm -rf "${BUILD_DIR}"
}

function clean_up {
    printf "Not implemented yet.\n"
    exit 1
}

function dependencies_check {
    printf "Not implemented yet.\n"
    exit 1
}


# MAIN
download_iso
prepare_iso_build
deploy_custom_bootstrap_cfg
build_mbr_hybrid
quazi_clean

#trap clean_up SIGHUP SIGINT SIGTERM ERR
