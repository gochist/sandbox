#!/usr/bin/env bash

source common.rc

IMAGE_URL=https://stable.release.core-os.net/amd64-usr/current/coreos_production_qemu_image.img.bz2
IMAGE_NAME=coreos_production_qemu_image.img
LIBVIRT_IMAGE_PATH=/var/lib/libvirt/images
LOCAL_IMAGE_PATH=${LIBVIRT_IMAGE_PATH}/${IMAGE_NAME}

apt install -y cloud-utils genisoimage

if [[ ! -e "${LOCAL_IMAGE_PATH}" ]]; then
    wget ${IMAGE_URL} -O ${LOCAL_IMAGE_PATH}.bz2
    bzip2 -d ${LOCAL_IMAGE_PATH}.bz2
fi

if [[ ! -e "${IMAGE_COREOS_PATH}" ]]; then
    # Convert the compressed qcow file downloaded to a uncompressed qcow2
    cp ${LOCAL_IMAGE_PATH} ${IMAGE_COREOS_PATH}
fi

if [[ ! -e "${IMAGE_USERDATA_PATH}" ]]; then
    cat > /tmp/my-user-data <<EOF
#cloud-config
password: userpass
chpasswd: { expire: False }
ssh_pwauth: True
EOF

    ## create the disk with NoCloud data on it.
    cloud-localds ${IMAGE_USERDATA_PATH} /tmp/my-user-data

    rm /tmp/my-user-data
fi