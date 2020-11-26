#!/bin/bash

# Writes IP address configuration so that kubelet and crio services select a valid node IP
# This only applies to VIP managing environments where the kubelet and crio IP
# address picking logic is flawed and may end up selecting an address from a
# different subnet or a deprecated address
# This will only work for IPv4 right now .... when I get an IPv6
# setup going, we will add that into the mix.

APIENDPOINT=${1}
KUBEIP=""

until [[ ! -z ${KUBEIP} ]]
do
    # Need to regenerate the list each time
    IPLISTV4=$(ip a | grep inet | grep -v \: | awk '{print $2}' | awk -F/ '{print $1}')
    for ip in ${IPLISTV4}
    do
        echo Testing ${ip} for connectivity.
        ping -I ${ip} -c 5 -q ${APIENDPOINT} > /dev/null
        if [ $? -lt 1 ]
        then
            echo the ip to register is ${ip}
            KUBEIP=${ip}
            break
        fi
    done
    sleep 5
done
# We need to put this proper IP into the overrride files
# /etc/systemd/system/kubelet.service.d/20-nodenet.conf
# and
# /etc/systemd/system/crio.service.d/20-nodenet.conf

echo updating /etc/systemd/system/crio.service.d/20-nodenet.conf
mkdir -p /etc/systemd/system/crio.service.d
cat <<EOF > /etc/systemd/system/crio.service.d/20-nodenet.conf
[Service]
Environment="CONTAINER_STREAM_ADDRESS=${KUBEIP}"
EOF

echo updating /etc/systemd/system/kubelet.service.d/20-nodenet.conf
mkdir -p /etc/systemd/system/kubelet.service.d
cat <<EOF > /etc/systemd/system/kubelet.service.d/20-nodenet.conf
[Service]
Environment="KUBELET_NODE_IP=${KUBEIP}"
EOF

echo all config files have been updated
exit 0
