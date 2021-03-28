#!/usr/bin/env bash

source common.rc

CODE_NAME=focal
IMAGE_NAME=${CODE_NAME}-server-cloudimg-amd64.img
IMAGE_URL=https://cloud-images.ubuntu.com/${CODE_NAME}/current/${CODE_NAME}-server-cloudimg-amd64.img
IMAGE_PATH=${IMAGE_DEVSTACK_PATH}
LIBVIRT_IMAGE_PATH=/var/lib/libvirt/images
LOCAL_IMAGE_PATH=${LIBVIRT_IMAGE_PATH}/${IMAGE_NAME}

apt install -y cloud-utils genisoimage

if [[ ! -e "${LOCAL_IMAGE_PATH}" ]]; then
    wget ${IMAGE_URL} -O ${LOCAL_IMAGE_PATH}
fi

if [[ ! -e "${IMAGE_PATH}" ]]; then
    # Convert the compressed qcow file downloaded to a uncompressed qcow2
    qemu-img convert -O qcow2 ${LOCAL_IMAGE_PATH} ${IMAGE_PATH}
    # Resize the image to 50G from original image of 2G
    qemu-img resize ${IMAGE_PATH} 50G
fi

cat > /tmp/my-user-data <<EOF
#cloud-config
password: userpass
chpasswd:
  expire: false
ssh_pwauth: True
users:
- default
- name: stack
  lock_passwd: false
  sudo: ["ALL=(ALL) NOPASSWD:ALL\nDefaults:stack !requiretty"]
  shell: /bin/bash
datasource:
  NoCloud:
    user-data: |
      # ...
    meta-data:
      # ...
mounts:
- [ "10.11.11.254:/", "/opt/stack", "nfs", "defaults,_netdev", "0", "0" ]
write_files:
- content: |
    #!/bin/sh
    sudo netplan apply
    DEBIAN_FRONTEND=noninteractive sudo apt-get -qqy update || sudo yum update -qy
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -qqy git nfs-common || sudo yum install -qy git
    sudo mount -a
    sudo chown stack:stack /home/stack
    sudo chown stack:stack -R /opt/stack
    cd /opt/stack
    git clone https://git.openstack.org/openstack-dev/devstack
    cd devstack
    cp /home/stack/local.conf .
    ./stack.sh
  path: /home/stack/start.sh
  permissions: 0755
- content: |
    [[local|localrc]]
    ADMIN_PASSWORD=password
    DATABASE_PASSWORD=password
    RABBIT_PASSWORD=password
    SERVICE_PASSWORD=password

    [[post-config|\$NOVA_CONF]]
    [DEFAULT]
    instance_usage_audit=True
    instance_usage_audit_period=hour
    notify_on_state_change=vm_and_task_state
  path: /home/stack/local.conf
  permissions: 0644
- content: |
    network: {config: disabled}
  path: /etc/cloud/cloud.cfg.d/99_disable_network_config.cfg
  permissions: 0644
- content: |
    network:
      version: 2
      ethernets:
        enp0s3:
          dhcp4: false
          addresses: [10.11.22.100/24]
          gateway4: 10.11.22.2
          nameservers:
            addresses: [10.11.22.2]
        enp0s4:
          dhcp4: false
          addresses: [10.11.11.100/24]
          gateway4: 10.11.11.254
          nameservers:
            addresses: [10.11.11.254]
  path: /etc/netplan/custom-networking.yaml
  permissions: 0644
runcmd:
- su -l stack ./start.sh
EOF

## create the disk with NoCloud data on it.
cloud-localds ${DEVSTACK_IMAGE_USERDATA_PATH} /tmp/my-user-data

rm /tmp/my-user-data
