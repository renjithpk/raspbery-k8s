#!/bin/bash
node=192.168.1.100
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
      "OU": "Kubernetes",
      "ST": "REN Co."
    }
  ]
}
EOF

output=ca

if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre ca root certificate ###########"
    sed s/Kubernetes/CA/ csr-template.json | \
        sed s/CN_VALUE/Kubernetes/ | \
        sed s/O_VLAUE/Kubernetes/ >  ${output}-csr.json
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca
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
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes admin-csr.json | \
        cfssljson -bare admin
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
    cfssl gencert \
        -ca=ca.pem -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes kube-proxy-csr.json | \
        cfssljson -bare kube-proxy
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
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname=192.168.1.100,192.168.1.100 \
        -profile=kubernetes 192.168.1.100-csr.json | \
        cfssljson -bare 192.168.1.100
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $ouput certificate"
        exit -1
    fi
fi



output=kubernetes
if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre kubelet $output certificate ###########"
    sed s/CN_VALUE/${output}/ csr-template.json | \
        sed s/O_VLAUE/Kubernetes/  > ${output}-csr.json
    cfssl gencert \
        -ca=ca.pem \
        -ca-key=ca-key.pem \
        -config=ca-config.json \
        -hostname=10.32.0.1,192.168.1.100,127.0.0.1,kubernetes.default \
        -profile=kubernetes kubernetes-csr.json | \
        cfssljson -bare kubernetes
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $ouput certificate"
        exit -1
    fi
fi

cd ../
