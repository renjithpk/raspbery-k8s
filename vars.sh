export ARCH=amd64
export MASTER_NODE=YES
export MASTER_HOSTNAME=renjith-laptop
export MASTER_IP=192.168.1.3
#export NODE_IP=$(ip -4 addr show ens3 | grep -oP "(?<=inet ).*(?=/)")
export NODE_IP=192.168.1.3
export NODE_NAME=$(hostname)
export INSTANCES=(${MASTER_HOSTNAME} worker-0)
export INSTANCES_IP=(${MASTER_IP} 192.168.1.20)
