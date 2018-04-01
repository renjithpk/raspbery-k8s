#!/bin/bash
MASTER_NODE=YES
mkdir -p temp
cd temp
echo "####  download  and move binaries ####"
if [ ! -f downloaded ]; then
    if [ $MASTER_NODE ]; then
        wget -q --show-progress --https-only --timestamping \
            https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
            https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
        if [ $? -ne 0 ]; then
            echo "ERROR Failed to download binaries cfssl "
            exit -1
        fi
        wget https://github.com/coreos/etcd/releases/download/v3.2.11/etcd-v3.2.11-linux-arm64.tar.gz && \
            wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/arm64/kube-apiserver && \
            wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/arm64/kube-controller-manager && \
            wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/arm64/kube-scheduler
        if [ $? -ne 0 ]; then
            echo "ERROR Failed to download binaries kubernetes master node"
            exit -1
        fi
    fi
    wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/arm64/kubectl && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/arm64/kubelet && \
        wget https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-arm64-v0.6.0.tgz && \
        wget https://github.com/kubernetes-incubator/cri-containerd/releases/download/v1.0.0-beta.0/cri-containerd-1.0.0-beta.0.linux-arm64.tar.gz && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/arm64/kube-proxy
    if [ $? -ne 0 ]; then
        echo "ERROR Failed to download node binaries  "
        exit -1
    fi
    touch downloaded
fi


if [ $MASTER_NODE ]; then
    echo "### install cfss binaries ##"
    chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 && \
        sudo cp -P cfssl_linux-amd64 /usr/local/bin/cfssl && \
        sudo cp -P  cfssljson_linux-amd64 /usr/local/bin/cfssljson
    if [ $? -ne 0 ]; then
        echo "ERROR Failed to install cfssl tools"
        exit -1
    fi
    echo "### install kubernetes  binaries ##"
    chmod +x \
        kube-apiserver \
        kube-controller-manager \
        kube-scheduler 
    if [ $? -ne 0 ]; then
        echo "ERROR Failed to set permission "
        exit -1
    fi
    cp --preserve \
        kube-apiserver \
        kube-controller-manager \
        kube-scheduler \
        /usr/local/bin/
    if [ $? -ne 0 ]; then
        echo "ERROR Failed to move binaries "
        exit -1
    fi
    echo "### install etcd  binaries ##"

    tar xvzf etcd-v3.2.11-linux-arm64.tar.gz > /dev/null && \
        mv etcd-v3.2.11-linux-arm64/etcd* /usr/local/bin/
    chown root /usr/local/bin/etcd*
    chgrp root /usr/local/bin/etcd*
    if [ $? -ne 0 ]; then
        echo "ERROR Failed to untar and move etcd bin "
        exit -1
    fi
fi


chmod +x \
    kubelet \
    kube-proxy \
    kubectl 
if [ $? -ne 0 ]; then
    echo "ERROR Failed to set permission "
    exit -1
fi



cp --preserve \
    kubectl \
    kubelet \
    kube-proxy \
    /usr/local/bin/
if [ $? -ne 0 ]; then
    echo "ERROR Failed to move binaries "
    exit -1
fi



echo "untar copy cni and cri-containerd to installation path"
sudo mkdir -p \
    /etc/cni/net.d \
    /opt/cni/bin 

tar -xvzf cni-plugins-arm64-v0.6.0.tgz -C /opt/cni/bin/
tar -xvzf cri-containerd-1.0.0-beta.0.linux-arm64.tar.gz -C /



