mkdir -p configs
cd configs

node=192.168.1.100

echo "####### Generate kubeconfig file for the kubelets  ########"
kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${node}:6443 \
    --kubeconfig=${node}.kubeconfig
kubectl config set-credentials system:node:${node} \
    --client-certificate=${node}.pem \
    --client-key=${node}-key.pem \
    --embed-certs=true \
    --kubeconfig=${node}.kubeconfig
kubectl config set-context default \
    --cluster=kubernetes \
    --user=system:node:${node} \
    --kubeconfig=${node}.kubeconfig
kubectl config use-context default --kubeconfig=${node}.kubeconfig



echo "####### Generate the kubeconfig file for the kube-proxies  #####"
kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${node}:6443 \
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
kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://192.168.1.100:6443 \
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


echo "######  Generate the data encryption key for   #####"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > encryption-config.yaml << EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
