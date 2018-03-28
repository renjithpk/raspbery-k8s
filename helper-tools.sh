#rm /usr/local/bin/cfssl*

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
    /var/run/kubernetes


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




