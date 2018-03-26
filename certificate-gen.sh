#!/bin/bash
node=192.168.1.100
output=ca
mkdir -p configs
cd configs
cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
} 
EOF

cat > csr-template.json << EOF
{
  "CN": "CN_VALUE",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "IN",
      "L": "Bangalore",
      "O": "O_VLAUE",
      "OU": "KubernetesTest",
      "ST": "REN Co."
    }
  ]
}
EOF


if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre ca root certificate ###########"
    sed s/CN_VALUE/Kubernetes/ csr-template.json | \
        sed s/O_VLAUE/Kubernetes/  | \
        sed s/KubernetesTest/CA/  > ${output}-csr.json
    cfssl gencert -initca ${output}-csr.json | cfssljson -bare $output
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create root certificate"
        exit -1
    fi
fi


output=admin
if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre $output client  ###########"
    sed s/CN_VALUE/admin/ csr-template.json | \
        sed s/O_VLAUE/system:masters/  > ${output}-csr.json
    cfssl gencert -initca ${output}-csr.json \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        ${output}-csr.json | cfssljson -bare $output
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $output certificate"
        exit -1
    fi
fi


output=kube-proxy
if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre $output client  ###########"
    sed s/CN_VALUE/system:${output}/ csr-template.json | \
        sed s/O_VLAUE/system:node-proxier/  > ${output}-csr.json
    cfssl gencert -initca ${output}-csr.json \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        ${output}-csr.json | cfssljson -bare $output
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $output certificate"
        exit -1
    fi
fi

output=$node
if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre kubelet $output certificate ###########"
    sed s/CN_VALUE/system:node:${node}/ csr-template.json | \
        sed s/O_VLAUE/system:nodes/  > ${output}-csr.json
    cfssl gencert -initca ${output}-csr.json \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        -hostname=${node},${node} \
        ${output}-csr.json | cfssljson -bare $output
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $ouput certificate"
        exit -1
    fi
fi



output=kubernetes
if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre kubelet $output certificate ###########"
    sed s/CN_VALUE/${output}/ csr-template.json | \
        sed s/O_VLAUE/${output}/  > ${output}-csr.json
    cfssl gencert -initca ${output}-csr.json \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes \
        -hostname=10.32.0.1,${node},127.0.0.1,kubernetes.default \
        ${output}-csr.json | cfssljson -bare $output
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $ouput certificate"
        exit -1
    fi
fi

cd ../
