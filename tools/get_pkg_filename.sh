#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
friendlywrt)
        ROMFILE=friendlywrt-images.tgz;;
friendlywrt-docker)
        ROMFILE=friendlywrt-docker-images.tgz;;
friendlycore-focal-arm64)
        ROMFILE=friendlycore-focal-arm64-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
