#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 <boot dir> <img filename>"
    echo "example:"
    echo "    tar xvzf NETDISK/rk3568/rootfs/rootfs-debian-buster-desktop-arm64-20190603.tgz"
    echo "    ./build-boot-img.sh debian-buster-desktop-arm64/boot debian-buster-desktop-arm64/boot.img"
    exit 1
fi
TOPDIR=$PWD

BOOT_DIR=$1
IMG_FILE=$2

if [ ! -d ${BOOT_DIR} ]; then
    echo "path '${BOOT_DIR}' not found."
    exit 1
fi

# 64M
IMG_SIZE=67108864

TOP=$PWD
true ${MKFS:="${TOP}/tools/mke2fs"}
IMG_BLK=$((${IMG_SIZE} / 4096))
INODE_SIZE=$((`find ${BOOT_DIR} | wc -l` + 128))
${MKFS} -N ${INODE_SIZE} -0 -E android_sparse -t ext4 -L boot -M /root -b 4096 -d ${BOOT_DIR} ${IMG_FILE} ${IMG_BLK}
RET=$?

if [ $RET -eq 0 ]; then
    echo "generating ${IMG_FILE} done."
else
    echo "failed to generate ${IMG_FILE}."
fi
exit $RET

