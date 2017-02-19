#!/usr/bin/env bash

source common.rc

CODE_NAME=xenial
IMAGE_NAME=${CODE_NAME}-server-cloudimg-amd64-disk1.img
IMAGE_URL=https://cloud-images.ubuntu.com/${CODE_NAME}/current/${CODE_NAME}-server-cloudimg-amd64-disk1.img
LIBVIRT_IMAGE_PATH=/var/lib/libvirt/images
LOCAL_IMAGE_PATH=${LIBVIRT_IMAGE_PATH}/${IMAGE_NAME}

apt install -y cloud-utils genisoimage

if [[ ! -e "${LOCAL_IMAGE_PATH}" ]]; then
    wget ${IMAGE_URL} -O ${LOCAL_IMAGE_PATH}
fi

if [[ ! -e "${IMAGE_XENIAL_PATH}" ]]; then
    # Convert the compressed qcow file downloaded to a uncompressed qcow2
    qemu-img convert -O qcow2 ${LOCAL_IMAGE_PATH} ${IMAGE_XENIAL_PATH}
    # Resize the image to 50G from original image of 2G
    qemu-img resize ${IMAGE_XENIAL_PATH} 50G
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