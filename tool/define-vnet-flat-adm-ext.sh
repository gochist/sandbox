#!/usr/bin/env bash

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2016, Joyent, Inc.
# Copyright (c) 2016, Samsung SDS
#

#
# This script defines virtual networks(admin and external) for KVM
#
# This code is based on coal-linux-kvm-setup.sh in joyent/triton proejct.
# see https://github.com/joyent/triton
#

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

# Checks if a network exists and is active. Destroys and undefines it as needed.
#
# Argument 1: Name of the virsh network.
#
function delete_virsh_net() {
    VIRSH_NET_NAME=$1

    # GNU grep always exits with a non zero exit code if it didn't find the parttern.
    # This conflicts with out 'set -o errexit' therfor we use '|| true'.
    VIRSH_NET_ACTIVE=$(virsh net-list --all | grep ${VIRSH_NET_NAME} | grep -c '.\sactive' || true)

    if [ "${VIRSH_NET_ACTIVE}" != "0" ]; then
        echo "Network '${VIRSH_NET_NAME}' active. Destroying existing network."
        virsh net-destroy ${VIRSH_NET_NAME}
    fi

    VIRSH_NET_EXISTS=$(virsh net-list --all | grep -c ${VIRSH_NET_NAME} || true)
    if [ "${VIRSH_NET_EXISTS}" != "0" ]; then
        echo "Network '${VIRSH_NET_NAME}' was already defined. Undefining existing network."
        virsh net-undefine ${VIRSH_NET_NAME}
    fi
}

# Checks if a domain exists in virsh and deletes it if exists.
#
# Argument 1: Name of the virsh domain.
#
function delete_virsh_domain() {
    VIRSH_DOMAIN_NAME=$1

    VIRSH_DOMIN_EXISTS=$(virsh list --all | grep -c ${VIRSH_DOMAIN_NAME} || true)

    if [ "${VIRSH_DOMIN_EXISTS}" != "0" ]; then
        echo "Domain '${VIRSH_DOMAIN_NAME}' was already defined. Undefining existing domain."
        virsh undefine ${VIRSH_DOMAIN_NAME}
    fi
}

echo "Admin network:    network=\"${ADMIN_NETWORK}\", host ip=\"${ADMIN_HOST_IP}\", netmask=\"${ADMIN_NETMASK}\""
echo "External network: network=\"${EXTERNAL_NETWORK}\", host ip=\"${EXTERNAL_HOST_IP}\", netmask=\"${EXTERNAL_NETMASK}\""

# Generate a temporary XML file which we will use to configure our network with.
VIRSH_NET_ADMIN_XML=$(mktemp /tmp/virsh-net.XXXXXXXXXXX)
cat > ${VIRSH_NET_ADMIN_XML} << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<network ipv6='no'>
     <name>${ADMIN_NAME}</name>
     <bridge name="${NETWORK_PREFIX}adm" />
     <ip address="${ADMIN_HOST_IP}" netmask="${ADMIN_NETMASK}" />
</network>
EOF

VIRSH_NET_EXTERNAL_XML=$(mktemp /tmp/virsh-net.XXXXXXXXXXX)
cat > ${VIRSH_NET_EXTERNAL_XML} << EOF
<network ipv6='no'>
     <name>${EXTERNAL_NAME}</name>
     <bridge name="${NETWORK_PREFIX}ext" />
     <forward mode="nat" />
     <ip address="${EXTERNAL_HOST_IP}" netmask="${EXTERNAL_NETMASK}">
          <dhcp>
              <range start="${EXTERNAL_DHCP_START}" end="${EXTERNAL_DHCP_END}" />
          </dhcp>
     </ip>
</network>
EOF

delete_virsh_net ${ADMIN_NAME}
delete_virsh_net ${EXTERNAL_NAME}

echo "Defining networks."
virsh net-define ${VIRSH_NET_ADMIN_XML}
virsh net-define ${VIRSH_NET_EXTERNAL_XML}

echo "Deleting temporary network configuration files."
rm -f ${VIRSH_NET_ADMIN_XML} ${VIRSH_NET_EXTERNAL_XML}

echo "Starting networks."
virsh net-autostart ${ADMIN_NAME}
virsh net-autostart ${EXTERNAL_NAME}
virsh net-start ${ADMIN_NAME}
virsh net-start ${EXTERNAL_NAME}
