#!/bin/bash

mkdir -p temp
cd temp
echo "####  download  and move binaries ####"
if [ ! -f downloaded ]; then
    wget -q --show-progress --https-only --timestamping \
        https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
        https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    wget https://github.com/coreos/etcd/releases/download/v3.2.11/etcd-v3.2.11-linux-amd64.tar.gz && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-apiserver && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-controller-manager && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-scheduler && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubelet && \
        wget https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz && \
        wget https://github.com/kubernetes-incubator/cri-containerd/releases/download/v1.0.0-beta.0/cri-containerd-1.0.0-beta.0.linux-amd64.tar.gz && \
        wget https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kube-proxy
fi

if [ $? -ne 0 ]; then
   echo "ERROR Failed to download binaries "
   exit -1
fi
touch downloaded

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
kube-scheduler \
kubectl \
kubelet \
kube-proxy


if [ $? -ne 0 ]; then
   echo "ERROR Failed to set permission "
   exit -1
fi

cp --preserve \
kube-apiserver \
kube-controller-manager \
kube-scheduler \
kubectl \
kubelet \
kube-proxy \
/usr/local/bin/
if [ $? -ne 0 ]; then
   echo "ERROR Failed to move binaries "
   exit -1
fi


echo "### install etcd  binaries ##"

tar xvzf etcd-v3.2.11-linux-amd64.tar.gz > /dev/null && \
mv etcd-v3.2.11-linux-amd64/etcd* /usr/local/bin/
chown root /usr/local/bin/etcd*
chgrp root /usr/local/bin/etcd*
if [ $? -ne 0 ]; then
   echo "ERROR Failed to untar and move etcd bin "
   exit -1
fi

echo "untar copy cni and cri-containerd and copy to installation path"
sudo mkdir -p \
    /etc/cni/net.d \
    /opt/cni/bin 

tar -xvzf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/
tar -xvzf cri-containerd-1.0.0-beta.0.linux-amd64.tar.gz -C /




