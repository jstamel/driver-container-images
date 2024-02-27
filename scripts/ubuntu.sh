#!/bin/sh

[ ${DEBUG} ] && set -vx
set -eu

# set environment
KERNEL_VERSION=$(uname -r)

# install dependencies
apt update
apt install -y gcc git linux-headers-${KERNEL_VERSION} linux-modules-extra-${KERNEL_VERSION} make pciutils

# clone linux-dfl-backport, build and load kernel modules
git clone https://github.com/jstamel/linux-dfl-backport --branch ${1:-intel/fpga-ofs-dev-6.6-lts} --depth 1
make -C linux-dfl-backport -j
make -C linux-dfl-backport reload
rm -rf linux-dfl-backport

# create VFs for Bittware ia420f, ia840f and PAC A10, S10 cards
$(dirname $0)/create_vf.sh 12ba:0070 12ba:0071 8086:09c4 8086:0b2b
