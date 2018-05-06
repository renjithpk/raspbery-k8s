#!/bin/bash

POSITIONAL=()
CLEANUP=NO
STOP=NO
STATUS=NO
SCP=NO
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--cleanup)
    CLEANUP=YES
    shift # past argument
    ;;
    -s|--stop-services)
    STOP=YES
    shift # past argument
    ;;

    --hostname)
    shift
    NEW_HOSTNAME=$1
    shift # past value
    ;;

    --status)
    STATUS=YES
    shift # past argument
    ;;

    --scp)
    SCP=YES
    shift # past argument
    ;;

    *)    # unknown option
    echo "Invalid option ${key}"
    echo "helper-tools.sh [-c|--cleanup] [-s|--stop-services] [--status] [--hostname]"
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters




set_hostname()
{
    set -x
    hostnamectl set-hostname $NEW_HOSTNAME
    #sysctl kernel.hostname
    set +x
}

scp_configs()
{
    source vars.sh
    set -x
    for ip in ${INSTANCES_IP[@]:1}; do
       cp vars.sh .vars_temp.sh
       echo $ip;
       sed -i '/export MASTER_NODE=YES/s/^/#/g' .vars_temp.sh
       sed -i 's/export NODE_IP='${NODE_IP}'/export NODE_IP='${ip}'/' .vars_temp.sh
       scp .vars_temp.sh root@$ip:/root/raspbery-k8s/vars.sh
       scp -r configs root@$ip:/root/raspbery-k8s/configs
    done
}

cleanup_files()
{
    set -x
    rm /usr/local/bin/cfssl*

    rm /usr/local/bin/etcd
    rm -r /etc/etcd /var/lib/etcd
    rm /usr/local/bin/kube-apiserver
    rm /usr/local/bin/kube-controller-manager
    rm /usr/local/bin/kube-scheduler
    rm /usr/local/bin/kubectl




    # /var/lib/kubernetes : ca.pem,ca-key.pem, kubernetes-key.pem, kubernetes.pem, encryption-config.yaml, kubeconfig
    rm /etc/systemd/system/etcd.service
    rm /etc/systemd/system/kube-apiserver.service
    rm /etc/systemd/system/kube-controller-manager.service
    rm /etc/systemd/system/kube-scheduler.service
    rm /etc/systemd/system/kubelet.service
    rm /etc/systemd/system/kube-proxy.service


    rm /etc/cni/net.d/99-loopback.conf
    rm /etc/cni/net.d/10-bridge.conf

    # /opt/cni ?? /etc/cni ??

    rm -r /etc/cni/net.d \
        /opt/cni/bin \
        /var/lib/kubelet \
        /var/lib/kube-proxy \
        /var/lib/kubernetes \
        #/var/run/kubernetes


    rm -r /opt/cri-containerd/ \
        /usr/local/sbin/runc \
        /usr/local/bin/crictl \
        /usr/local/bin/containerd \
        /usr/local/bin/containerd-stress \
        /usr/local/bin/critest \
        /usr/local/bin/containerd-release \
        /usr/local/bin/containerd-shim \
        /usr/local/bin/ctr \
        /usr/local/bin/cri-containerd \
        /etc/systemd/system/containerd.service \
        /etc/systemd/system/cri-containerd.service \
        /etc/crictl.yaml
    set +x
}


if [ $STOP == "YES" ]  ; then
    echo "Stop services"
    systemctl stop etcd kube-apiserver kube-controller-manager kube-scheduler  kube-proxy kubelet
    systemctl stop etcd containerd cri-containerd
fi

if [ $CLEANUP == "YES" ]  ; then
    echo "cleanup"
    cleanup_files
fi

if [ $STATUS == "YES" ]  ; then
    echo "Checking service status"
    for svc in etcd kube-apiserver kube-controller-manager kube-scheduler containerd cri-containerd kubelet kube-proxy
    do
        systemctl status --lines=0 --no-pager $svc
    done
fi

if [ $NEW_HOSTNAME ] ; then
    echo "set new hostname $NEW_HOSTNAME"
    set_hostname
fi

if [ $SCP == 'YES' ] ; then
    echo "scp config file to worker nodes"
    scp_configs    
fi  
