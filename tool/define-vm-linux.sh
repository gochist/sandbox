#!/usr/bin/env bash

# Fail on any non-zero exit code.
set -o errexit
# Fail if an application in an pipe returns a non-zero exit code.
set -o pipefail
# Fail on unset variables.
set -u
# Uncomment for debugging.
#set -x

if [ ! -e "common.rc" ]; then
    echo "error: This script requires common.rc file. see common.rc.sample "
fi
source common.rc


if [[ ! "$#" -eq 2 ]]; then
    echo "Usage: ${0} image domain_name"
    echo "ex) sudo bash ${0} xenial test"
    echo "images:"
    echo "  - devstack (ubuntu 20.04)"
    echo "  - focal  (ubuntu 20.04)"
    echo "  - bionic (ubuntu 18.04)"
    echo "  - xenial (ubuntu 16.04)"
    echo "  - coreos"
    exit 1
else
    IMAGE_NAME=${1}
    DOMAIN_NAME=${2}

    if [[ ${IMAGE_NAME} == "xenial" ]]; then
        IMAGE_SOURCE_PATH=${IMAGE_XENIAL_PATH}
    elif [[ ${IMAGE_NAME} == "bionic" ]]; then
        IMAGE_SOURCE_PATH=${IMAGE_BIONIC_PATH}
    elif [[ ${IMAGE_NAME} == "focal" ]]; then
        IMAGE_SOURCE_PATH=${IMAGE_FOCAL_PATH}
    elif [[ ${IMAGE_NAME} == "devstack" ]]; then
        IMAGE_SOURCE_PATH=${IMAGE_FOCAL_PATH}
        IMAGE_USERDATA_PATH=${DEVSTACK_IMAGE_USERDATA_PATH}
    elif [[ ${IMAGE_NAME} == "coreos" ]]; then
        IMAGE_SOURCE_PATH=${IMAGE_COREOS_PATH}
    else
        echo "error: no image"
        exit 1
    fi
fi

if [ -e "/usr/bin/qemu-kvm" ]; then
    EMULATOR=/usr/bin/qemu-kvm
elif [ -e "/usr/bin/kvm" ]; then
    EMULATOR=/usr/bin/kvm
else
    echo "KVM cannot be found. Exiting."
    exit 1
fi

NESTED_KVM_ENABLED=$(</sys/module/kvm_intel/parameters/nested)

# TODO: Add support for AMD.
if [ ! "${NESTED_KVM_ENABLED}" == "Y" ]; then
    echo "Nested KVM is not enabled. Enabling."

    rmmod kvm-intel
    echo 'options kvm-intel nested=y' >> /etc/modprobe.d/kvm-intel.conf
    modprobe kvm-intel
fi

VIRSH_IMAGE_PATH=${IMAGE_PATH}/${PREFIX}-${DOMAIN_NAME}.qcow2
cp ${IMAGE_SOURCE_PATH} ${VIRSH_IMAGE_PATH}

# Default location for VM images is: '/var/lib/libvirt/images'.
VIRSH_DOMAIN_XML=$(mktemp /tmp/virsh-vm.XXXXXXXXXXX)
cat > ${VIRSH_DOMAIN_XML} << EOF
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
    <name>${PREFIX}-${DOMAIN_NAME}</name>
    <memory unit='GB'>8</memory>
    <vcpu>2</vcpu>
    <cpu mode='host-passthrough'>
        <!--<feature policy='require' name='hyperv' />-->
    </cpu>
    <feature policy='require' name='vmx'/>
    <feature policy='require' name='acpi'/>
    <input type='keyboard' bus='usb'/>
    <os>
        <type arch='x86_64'>hvm</type>
        <boot dev='hd' />
    </os>
    <clock sync="localtime"/>
    <devices>
        <emulator>${EMULATOR}</emulator>
        <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' cache='none' io='native'/>
            <source file='${VIRSH_IMAGE_PATH}'/>
            <target dev='vda' bus='virtio' />
            <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
        </disk>
        <disk type='file' device='disk'>
          <driver name='qemu' type='raw'/>
          <source file='${IMAGE_USERDATA_PATH}'/>
          <target dev='vdb' bus='virtio'/>
          <readonly/>
          <shareable/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
        </disk>
        <interface type='network'>
            <source network='${EXTERNAL_NAME}'/>
        </interface>
        <interface type='network'>
            <source network='${ADMIN_NAME}'/>
        </interface>
        <!-- Serial ports are exposed in host OS as /dev/pts/* -->
        <serial type='pty'>
            <target port='0'/>
        </serial>
        <serial type='pty'>
            <target port='1'/>
        </serial>
    <graphics type='vnc' port='-1' autoport='yes' keymap='en-us' />
  </devices>
</domain>
EOF

virsh define ${VIRSH_DOMAIN_XML}

