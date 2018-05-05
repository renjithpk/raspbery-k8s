#!/bin/bash
. ./vars.sh

if ! cd configs; then
    echo "configs directory not present, run create-cert.sh first"
    exit -1
fi

echo $'\n#### copy kubeconfig for kubectl ###'
if ! cp admin-config.kubeconfig ~/.kube/config; then
    echo "Failed to configure kubectl"
    exit -1
fi

if [ $MASTER_NODE ]; then
    echo $'\n#### Start ETCD service ##'
    if ETCDCTL_API=3 etcdctl member list > /dev/null; then
        echo "etcd service up and running skipping "
    else
        mkdir -p /etc/etcd /var/lib/etcd
        # cleanup if any pre existing data
        rm -r /var/lib/etcd/*
        cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
        if [ $? -ne 0 ]; then

            echo "Error Failed to copy etcd cfg file"
            exit -1
        fi

        cp -P etcd.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl start etcd
        sleep 1
        ETCDCTL_API=3 etcdctl member list
        if [ $? -eq 0 ]; then
            echo "Successfully started etcd service "
        else
            echo " Error failed to start etcd service"
            exit -1
        fi
    fi

    echo $'\n#### Start API server ####'
    systemctl status --no-pager kube-apiserver > /dev/null
    if [ $? -eq 0 ]; then
        echo "API server is alreay up, skipping..."
    else
        mkdir -p /var/lib/kubernetes
        cp -P \
            ca.pem \
            ca-key.pem \
            kubernetes-key.pem \
            kubernetes.pem \
            encryption-config.yaml \
            /var/lib/kubernetes

        cp -P kube-apiserver.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl start kube-apiserver
        sleep 1
        ps -e |grep -v grep |grep kube-apiserver > /dev/null
        if [ $? -ne 0 ]; then
            echo "Error kube-apiserver service is not up..."
            exit -1
        fi
    fi

    echo $'\n#### Start kube-controller-manager.service server ####'
    ps -e |grep -v grep |grep kube-controller > /dev/null
    if [ $? -eq 0 ]; then
        echo "kube-controller-manager service  is alreay up, skipping..."
    else
        cp -P kube-controller-manager.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl start kube-controller-manager
        sleep 1
        ps -e |grep -v grep |grep kube-controller > /dev/null
        if [ $? -ne 0 ]; then
            echo "Error kube-controller-manager service is not up..."
            exit -1
        fi

    fi


    echo $'\n#### Start kube-scheduler service ####'
    ps -e |grep -v grep |grep kube-scheduler > /dev/null
    if [ $? -eq 0 ]; then
        echo "kube-scheduler service is alreay up, skipping..."
    else
        cp -P kube-scheduler.service /etc/systemd/system/
        systemctl daemon-reload
        systemctl start kube-scheduler
        sleep 1
        ps -e |grep -v grep |grep kube-scheduler > /dev/null
        if [ $? -ne 0 ]; then
            echo "Error kube-scheduler service is not up"
            exit -1
        fi
    fi
    sleep 1
    kubectl get componentstatuses
    if [ $? -ne 0 ]; then
        echo "All kube componensts are not up"
        exit -1
    fi
    if ! kubectl get clusterroles system:kube-apiserver-to-kubelet > /dev/null; then
        kubectl create -f kube-apiserver-to-kubelet.yaml
    fi

    if ! kubectl get ClusterRoleBinding system:kube-apiserver > /dev/null; then
        kubectl create -f kube-apiserver-to-kubelet-bind.yaml
    fi

    if curl --silent --cacert ca.pem https://${NODE_IP}:6443/version|grep platform; then
        echo "I could talk Successfully to API server "
    else
        echo "ERROR could not talk to API server "
        exit -1
    fi
fi



echo $'\n#### start cni service####'
if [ -f /run/containerd/containerd.sock ]; then
    echo "containerd service is alreay up, skipping..."
else
    cp -P 10-bridge.conf /etc/cni/net.d/
    cp -P 99-loopback.conf /etc/cni/net.d/
    systemctl restart containerd cri-containerd
fi


echo $'\n#### Start kubelet service ####'
ps -e |grep -v grep |grep kubelet > /dev/null
if [ $? -eq 0 ]; then
    echo "kubelet service is alreay up, skipping..."
else
    cp -P kubelet.service /etc/systemd/system/
    mkdir -p /var/lib/kubelet
    cp -P ${NODE_NAME}-key.pem ${NODE_NAME}.pem /var/lib/kubelet
    cp -P ${NODE_NAME}.kubeconfig /var/lib/kubelet/kubeconfig
    swapoff -a
    systemctl daemon-reload
    systemctl start kubelet
    sleep 1
    ps -e |grep -v grep |grep kubelet > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error kubelet service is not up"
        exit -1
    fi

fi

echo $'\n#### Start kube-proxy service ####'
ps -e |grep -v grep |grep kube-proxy > /dev/null
if [ $? -eq 0 ]; then
    echo "kube-proxy service is alreay up, skipping..."
else
    mkdir -p /var/lib/kube-proxy/
    cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
    cp -P kube-proxy.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl start kube-proxy
    sleep 1
    ps -e |grep -v grep |grep kube-proxy > /dev/null
    if [ $? -ne 0 ]; then
        echo "Error kube-proxy service is not up"
        exit -1
    fi

fi

echo $'\n####Setup flannel for pod networking####'
kubectl get ds kube-flannel-ds -n kube-system
if [ $? -eq 0 ]; then
    echo " Flannel already deployed skipping"
else
    if [ ! -f kube-flannel.yml ]; then
        curl -o kube-flannel.yml  -sSL https://rawgit.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
        if [ $? -ne 0 ]; then
            echo "Failed to download kube-flannel.yml "
            exit -1
        fi
    fi
    kubectl  create -f  kube-flannel.yml
fi

if [ ! $MASTER_NODE ]; then
    echo $'\n#### Deploy one sample application ####'
    kubectl get deploy my-nginx
    if [ $? -eq 0 ]; then
        echo " Sample app nginx already deployed skipping####"
    else

        kubectl run my-nginx --image=nginx --replicas=2 --port=80
        kubectl expose deployment my-nginx --port=80
    fi
    kubectl get svc my-nginx
fi
