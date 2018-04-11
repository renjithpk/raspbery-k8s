
MASTER_IP=192.168.1.100
MASTER_HOSTNAME=sony-vaio
HOSTNAME=$(hostname)
MASTER_NODE=YES
#scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
if [ $MASTER_NODE ]; then
    echo "### prepare services for MASTER node ###"
else
    echo "### prepare services for WORKER node ###"
fi

if [ ! -f configs/services ]; then
    echo "#### Copy Node service and config files###"
    cp -P services/10-bridge.conf \
        services/99-loopback.conf \
        services/kubelet.service \
        services/kube-proxy.service configs
    if [ $MASTER_NODE ]; then
        echo "### Copy masternode services to configs###"    
        cp -p services/kube-apiserver.service \
            services/kube-controller-manager.service \
            services/kube-apiserver-to-kubelet.yaml \
            services/kube-apiserver-to-kubelet-bind.yaml \
            services/kube-scheduler.service  \
            services/etcd.service configs
        sed -i s/MASTER_HOSTNAME/${MASTER_HOSTNAME}/g configs/etcd.service
        sed -i s/MASTER_IP/${MASTER_IP}/g configs/etcd.service
        sed -i s/MASTER_IP/${MASTER_IP}/g configs/kube-apiserver.service
        sed -i s/HOSTNAME/${HOSTNAME}/g configs/kubelet.service
    else
        echo "### Skipping masternode services ###"
    fi
    touch configs/services
fi

cd configs

echo "####### Generate kubelete kubeconfig file for $HOSTNAME node ########"
rm ${HOSTNAME}.kubeconfig
kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=${HOSTNAME}.kubeconfig
kubectl config set-credentials system:node:${HOSTNAME} \
    --client-certificate=${HOSTNAME}.pem \
    --client-key=${HOSTNAME}-key.pem \
    --embed-certs=true \
    --kubeconfig=${HOSTNAME}.kubeconfig
kubectl config set-context default \
    --cluster=kubernetes \
    --user=system:node:${HOSTNAME} \
    --kubeconfig=${HOSTNAME}.kubeconfig
kubectl config use-context default --kubeconfig=${HOSTNAME}.kubeconfig


echo "####### Generate the kubeconfig file for the kube-proxies  #####"
rm kube-proxy.kubeconfig
kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default \
    --cluster=kubernetes \
    --user=kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

echo "####### Generate the kubeconfig file for the kubectl admin  #####"
rm admin-config.kubeconfig
kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=admin-config.kubeconfig
kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin-config.kubeconfig
kubectl config set-context kubernetes \
    --cluster=kubernetes --user=admin \
    --kubeconfig=admin-config.kubeconfig
kubectl config use-context kubernetes \
    --kubeconfig=admin-config.kubeconfig
