#!/bin/bash
. ./vars.sh
echo ${INSTANCES[0]}
echo ${INSTANCES[1]}


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
    cfssl gencert -initca ${output}-csr.json | cfssljson -bare ${output}
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create root certificate"
        exit -1
    fi
else
    echo " skipping ${output}.pem"
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
        -profile=kubernetes ${output}-csr.json | \
        cfssljson -bare ${output}
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $output certificate"
        exit -1
    fi
else
    echo " skipping ${output}.pem"
fi


output=kube-proxy
if [ ! -f ./${output}.pem ]; then
    echo "########   Preapre $output client  ###########"
    sed s/CN_VALUE/system:${output}/ csr-template.json | \
        sed s/O_VLAUE/system:node-proxier/  > ${output}-csr.json
    cfssl gencert \
        -ca=ca.pem -ca-key=ca-key.pem \
        -config=ca-config.json \
        -profile=kubernetes ${output}-csr.json | \
        cfssljson -bare ${output}
    if [ ! -f ./${output}.pem ]; then
        echo "Failed to create $output certificate"
        exit -1
    fi
else
    echo " skipping ${output}.pem"
fi

for i in {0..1}; do
    echo $i
    output=${INSTANCES[$i]}
    if [ ! -f ./${output}.pem ]; then
        echo "########   Preapre kubelet : $output certificate ###########"
        sed s/CN_VALUE/system:node:${INSTANCES[$i]}/ csr-template.json | \
            sed s/O_VLAUE/system:nodes/  > ${output}-csr.json
        cfssl gencert \
            -ca=ca.pem \
            -ca-key=ca-key.pem \
            -config=ca-config.json \
            -hostname=${INSTANCES[$i]},${INSTANCES_IP[$i]} \
            -profile=kubernetes ${output}-csr.json | \
            cfssljson -bare ${output}
        if [ ! -f ./${output}.pem ]; then
            echo "Failed to create $ouput certificate"
            exit -1
        fi
    else
        echo " skipping ${output}.pem"
    fi
    output=kubernetes
    if [ ! -f ./${output}.pem ]; then
        echo "########   Preapre kubernetes api server $output certificate ###########"
        sed s/CN_VALUE/${output}/ csr-template.json | \
            sed s/O_VLAUE/Kubernetes/  > ${output}-csr.json
        cfssl gencert \
            -ca=ca.pem \
            -ca-key=ca-key.pem \
            -config=ca-config.json \
            -hostname=10.32.0.1,${INSTANCES_IP[0]},${INSTANCES_IP[1]},127.0.0.1,kubernetes.default \
            -profile=kubernetes ${output}-csr.json | \
            cfssljson -bare ${output}
        if [ ! -f ./${output}.pem ]; then
            echo "Failed to create $ouput certificate"
            exit -1
        fi
    else
        echo " skipping ${output}.pem"
    fi
done

if [ ! -f encryption-config.yaml ]; then
    echo "######  Generate the data encryption key   #####"
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
else
    echo " skipping encryption-config.yaml"
fi

cd ../
