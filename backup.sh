#!/bin/bash

#判断命令是否存在,不存在就退出
check_command_exist(){
    local command=$1
    IFS_SAVE="$IFS"
    IFS=":"
    local code
    for path in $PATH;do
        binPath="$path/$command"
        if [[ -f $binPath ]];then
                IFS="$IFS_SAVE"
            return 0
        fi
    done
    IFS="$IFS_SAVE"
    echo "$command not found,please install it."
    exit 1

}

#保证是在根用户下运行
need_root_priv(){
        # Make sure only root can run our script
        if [[ $EUID -ne 0 ]]; then
                echo "This script must be run as root" 1>&2
                exit 1
        fi
}

#判断系统版本
check_sys(){
	local checkType=$1
	local value=$2

	local release=''
	local systemPackage=''
	local packageSupport=''

	
	if [[ "$release" == "" ]] || [[ "$systemPackage" == "" ]] || [[ "$packageSupport" == "" ]];then

		if [[ -f /etc/redhat-release ]];then
			release="centos"
			systemPackage="yum"
			packageSupport=true

		elif cat /etc/issue | grep -q -E -i "debian";then
			release="debian"
			systemPackage="apt"
			packageSupport=true

		elif cat /etc/issue | grep -q -E -i "ubuntu";then
			release="ubuntu"
			systemPackage="apt"
			packageSupport=true

		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
			release="centos"
			systemPackage="yum"
			packageSupport=true

		elif cat /proc/version | grep -q -E -i "debian";then
			release="debian"
			systemPackage="apt"
			packageSupport=true

		elif cat /proc/version | grep -q -E -i "ubuntu";then
			release="ubuntu"
			systemPackage="apt"
			packageSupport=true

		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
			release="centos"
			systemPackage="yum"
			packageSupport=true

		else
			release="other"
			systemPackage="other"
			packageSupport=false
		fi

	fi

	if [[ $checkType == "sysRelease" ]]; then
		if [ "$value" == "$release" ];then
			return 0
		else
			return 1
		fi

	elif [[ $checkType == "packageManager" ]]; then
		if [ "$value" == "$systemPackage" ];then
			return 0
		else
			return 1
		fi

	elif [[ $checkType == "packageSupport" ]]; then
		if $packageSupport;then
			return 0
		else
			return 1
		fi
	fi
}

need_root_priv
echo "开始备份系统..."
BACKUP_PATH=./raspberrypi.img
FILE_SIZE=4000
if [ -n "$1" ]; then
	BACKUP_PATH=$1
fi
if [ -n "$2" ]; then
	FILE_SIZE=$2
fi
if check_sys  packageManager apt;then
	apt-get -y update
	apt-get install -y dosfstools dump parted kpartx
elif check_sys  packageManager yum;then
	yum -y dosfstools dump parted kpartx
fi
check_command_exist "parted"
check_command_exist "kpartx"
check_command_exist "dump"
check_command_exist "mkfs.vfat"
dd if=/dev/zero of=$BACKUP_PATH bs=1MB count=$FILE_SIZE
parted $BACKUP_PATH --script -- mklabel msdos
parted $BACKUP_PATH --script -- mkpart primary fat32 8192s 2682879s
parted $BACKUP_PATH --script -- mkpart primary ext4 2682880s -1

loopdevice=`losetup -f --show $BACKUP_PATH`
device=`kpartx -va $loopdevice | sed -E 's/.*(loop[0-15])p.*/\1/g' | head -1`
device="/dev/ram${device}"
partBoot="${device}p1"
partRoot="${device}p2"
mkfs.vfat $partBoot
mkfs.ext4 $partRoot
mount -t vfat $partBoot /media
cp -rfp /boot/* /media/
umount /media
mount -t ext4 $partRoot /media/
cd /media
dump -0uaf - / | sudo restore -rf -
cd
umount /media
kpartx -d $loopdevice
losetup -d $loopdevice

echo "系统备份完成，备份文件路径：$BACKUP_PATH!"
