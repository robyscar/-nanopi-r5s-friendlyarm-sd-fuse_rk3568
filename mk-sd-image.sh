#!/bin/bash
set -eu

# Copyright (C) Guangzhou FriendlyElec Computer Tech. Co., Ltd.
# (http://www.friendlyelec.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can access it online at
# http://www.gnu.org/licenses/gpl-2.0.html.
function usage() {
       echo "Usage: $0 <buildroot|friendlycore-focal-arm64|debian-buster-desktop-arm64|debian-bullseye-desktop-arm64|friendlywrt22|friendlywrt22-docker|friendlywrt21|friendlywrt21-docker|eflasher>"
       exit 0
}

if [ $# -eq 0 ]; then
    usage
fi

# ----------------------------------------------------------
# Get platform, target OS

true ${SOC:=rk3568}
true ${TARGET_OS:=${1,,}}

# ----------------------------------------------------------
# Create zero file

RK_PARAMETER_TXT=$(dirname $0)/${TARGET_OS}/parameter.txt
case ${TARGET_OS} in
buildroot*)
    RAW_SIZE_MB=7800 ;;
friendlycore-focal-arm64)
	RAW_SIZE_MB=7800 ;;
debian-*-desktop-arm64)
	RAW_SIZE_MB=7800 ;;
friendlywrt*)
	RAW_SIZE_MB=1000 ;;
eflasher)
	RAW_SIZE_MB=7800
	;;
*)
	echo "Error: Unsupported target OS: ${TARGET_OS}"
	exit -1
	;;
esac
	 
if [ $# -eq 2 ]; then
	RAW_FILE=$2
else
	case ${TARGET_OS} in
	buildroot*)
		RAW_FILE=${SOC}-sd-buildroot-5.10-arm64-$(date +%Y%m%d).img
		;;
	friendlycore-focal-arm64)
		RAW_FILE=${SOC}-sd-friendlycore-lite-focal-5.10-arm64-$(date +%Y%m%d).img
		;;
	debian-buster-desktop-arm64)
		RAW_FILE=${SOC}-sd-debian-buster-desktop-5.10-arm64-$(date +%Y%m%d).img
		;;
	debian-bullseye-desktop-arm64)
		RAW_FILE=${SOC}-sd-debian-bullseye-desktop-5.10-arm64-$(date +%Y%m%d).img
		;;
	friendlywrt22)
		RAW_FILE=${SOC}-sd-friendlywrt-22.03-arm64-$(date +%Y%m%d).img
		;;
	friendlywrt22-docker)
		RAW_FILE=${SOC}-sd-friendlywrt-22.03-docker-arm64-$(date +%Y%m%d).img
		;;
	friendlywrt21)
		RAW_FILE=${SOC}-sd-friendlywrt-21.02-arm64-$(date +%Y%m%d).img
		;;
	friendlywrt21-docker)
		RAW_FILE=${SOC}-sd-friendlywrt-21.02-docker-5.10-arm64-$(date +%Y%m%d).img
		;;
	eflasher)
		RAW_FILE=${SOC}-eflasher-$(date +%Y%m%d).img
		;;
	*)
		RAW_FILE=${SOC}-${TARGET_OS}-$(date +%Y%m%d).img
		;;
	esac
fi

# ----------------------------------------------------------
# Get target OS

if [ ! -f "${RK_PARAMETER_TXT}" ]; then
	ROMFILE=`./tools/get_pkg_filename.sh ${TARGET_OS}`
	cat << EOF
Warn: Image not found for ${1}
----------------
you may download it from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called images-for-eflasher, for example:
    tar xvzf /path/to/NETDISK/images-for-eflasher/${ROMFILE}
----------------
Do you want to download it now via http? (Y/N):
EOF

	while read -r -n 1 -t 3600 -s USER_REPLY; do
		if [[ ${USER_REPLY} = [Nn] ]]; then
			echo ${USER_REPLY}
			exit 1
		elif [[ ${USER_REPLY} = [Yy] ]]; then
			echo ${USER_REPLY}
			break;
		fi
	done

	if [ -z ${USER_REPLY} ]; then
		echo "Cancelled."
		exit 1
	fi

	./tools/get_rom.sh ${TARGET_OS} || exit 1
fi

# ----------------------------------------------------------
# Create zero file

OUT=out
if [ ! -d $OUT ]; then
	echo "path not found: $PWD/$OUT"
	exit 1
fi
RAW_FILE=${OUT}/${RAW_FILE}
if [ -f "${RAW_FILE}" ]; then
	rm -f ${RAW_FILE}
fi

BLOCK_SIZE=1024
let RAW_SIZE=(${RAW_SIZE_MB}*1000*1000)/${BLOCK_SIZE}

echo "Creating RAW image: ${RAW_FILE} (${RAW_SIZE_MB} MB)"
echo "---------------------------------"
dd if=/dev/zero of=${RAW_FILE} bs=${BLOCK_SIZE} count=0 seek=${RAW_SIZE}
if [ $? -ne 0 ]; then
	echo "Error: ${RAW_FILE}: Creating RAW file failed"
	exit 1
fi

# ----------------------------------------------------------
# Fusing all

if [ "x${TARGET_OS}" = "xeflasher" ]; then
   true ${SD_FUSING:=$(dirname $0)/fusing.sh}

	# Automatically re-run script under sudo if not root
	if [ $(id -u) -ne 0 ]; then
		echo "Re-running script under sudo..."
		sudo "$0" "$@"
		exit
	fi

	# ----------------------------------------------------------
	# Setup loop device
	LOOP_DEVICE=$(losetup -f)
	echo "Using device: ${LOOP_DEVICE}"

	if losetup ${LOOP_DEVICE} ${RAW_FILE}; then
		USE_KPARTX=1
		PART_DEVICE=/dev/mapper/`basename ${LOOP_DEVICE}`
		sleep 1
	else
		echo "Error: attaching ${LOOP_DEVICE} failed, stop now."
		rm ${RAW_FILE}
		exit 1
	fi

	RK_PARAMETER_TXT=${RK_PARAMETER_TXT} ${SD_FUSING} ${LOOP_DEVICE} ${TARGET_OS}
	RET=$?
	if [ ${RET} -ne 0 ]; then
		echo "Error: ${RAW_FILE}: Fusing image failed, cleanup"
		rm -f ${RAW_FILE}
		exit 1
	fi

	if ! command -v mkfs.exfat &> /dev/null; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			jammy)
				sudo apt-get install exfatprogs
				;;
			*)
				sudo apt-get install exfat-fuse exfat-utils
				;;
			esac
		fi
	fi
	mkfs.exfat ${LOOP_DEVICE}p1 -n FriendlyARM

	# cleanup
	losetup -d ${LOOP_DEVICE}
else
	true ${SD_UPDATE:=$(dirname $0)/tools/sd_update}

	${SD_UPDATE} -d ${RAW_FILE} -p ${RK_PARAMETER_TXT}
	if [ $? -ne 0 ]; then
		echo "Error: filesystem fusing failed, Stop."
		exit 1
	fi
fi

echo "---------------------------------"
echo "RAW image successfully created (`date +%T`)."
ls -l ${RAW_FILE}
echo "Tip: You can compress it to save disk space."

