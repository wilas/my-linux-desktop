#!/bin/bash
set -e -E -u -o pipefail; shopt -s failglob;

VBOX_VERSION="4.3.2"

# uninstall the default Virtualbox Guest Additions
service virtualbox-guest-utils stop
apt-get -y purge virtualbox-ose-guest-x11
apt-get -y purge virtualbox-guest-utils
apt-get -y install dkms
apt-get -y autoremove

# Do we have any virtualbox guest additions installed ?
if VBoxControl --version >/dev/null 2>&1; then
    version=$(VBoxControl --version | cut -f 1 -d"r") # 4.2.12r84980 -> 4.2.12
    # Expected version is installed, exit
    if [[ $version == "${VBOX_VERSION}" ]]; then
        exit 0
    fi
fi

# Installing the virtualbox guest additions
# VBoxGuestAdditions iso is attached (by vbkick) to SATA Controller port 1 device 0
if [[ -b /dev/sr1 ]]; then
    mount /dev/sr1 /mnt
elif [[ -b /dev/sr0 ]]; then
    mount /dev/sr0 /mnt
else
    exit 1
fi
# true because whene there is noX on the server additions_script return 1: "Installing the Window System drivers [FAILED]"
sh /mnt/VBoxLinuxAdditions.run || true
umount /mnt
