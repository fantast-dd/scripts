#!/bin/bash
# 2016/9/01 pdd
# 磁盘（小于2TB）自动分区并挂载

DISK="/dev/sdb"
FSTYPE="ext4"
storage="/storage"

function storage_fdisk() {
fdisk $DISK<<EOF
n
p
1


w
EOF
mkfs -t $FSTYPE ${DISK}1
}

function storage_mount() {
cat >>/etc/fstab<<EOF
${DISK}1        $storage                   ext4    defaults        0 0
EOF
mount -a
}

[ -d $storage ] || mkdir $storage
[ -b ${DISK}1 ] || storage_fdisk
grep -q ${DISK}1 /etc/fstab || storage_mount
