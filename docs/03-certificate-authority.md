# Sessão 03 - Provisionando o CA e gerando os certificados TLS

Neste tutorial, você provisionará uma [Infraestrutura PKI](https://en.wikipedia.org/wiki/Public_key_infrastructure) usando o kit de ferramentas PKI da CloudFlare, [cfssl](https://github.com/cloudflare/cfssl) e em seguida irá utilizá-lo para inicializar uma Certification Authority (CA). Em seguida, você irá gerar os certificados TLS para os seguintes componentes do Kubernetes: etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet e kube-proxy.

> Todos os comandos deste tutorial deverão ser executados no seu desktop/laptop.

## Atividade 03.01 - Certificate Authority (CA)

Nesta atividade, você irá configurar uma CA que será usada para gerar certificados TLS adicionais.

## Tarefa 03.01.01 - Criando o Certificate Authority (CA)

Gerar o arquivo de configuração da CA, o certificado e a chave privada, utilizando o(s) commando(s) abaixo:

```
cat > ca-config.json <<EOF
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
```

```
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF
```

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

O resultado dos comandos acima serão os seguintes arquivos:

```
ca-config.json
ca-csr.json
ca-key.pem
ca.csr
ca.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.

## Atividade 03.02 - Certificados de Cliente e Servidor

Nesta seção, você irá gerar certificados de cliente e servidor para cada componente do Kubernetes e um certificado de cliente para o usuário `admin` do Kubernetes.


### Tarefa 03.02.01 - Criando os Certificado de Cliente para o Admin

Gerar o certificado de cliente `admin` e a chave privada, através dos seguintes comandos:

```
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
```
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

O resultado dos comandos acima serão os seguintes arquivos:

```
admin-csr.json
admin-key.pem
admin.csr
admin.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.


### Tarefa 03.02.02 - Criando os Certificados do Kubelet Client

O Kubernetes usa um [modo de autorização para fins especiais/special-purpose authorization mode](https://kubernetes.io/docs/admin/authorization/node/) chamado Node Authorizer, que autoriza especificamente solicitações de API feitas pelos [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). Para ser autorizado pelo Node Authorizer, o Kubelet deve usar uma credencial que o identifique como estando no grupo `system: nodes`, com um nome de usuário `system:node:<nodeName>`. Nesta seção, você criará um certificado para cada worker node do Kubernetes que atenda aos requisitos do Node Authorizer.

Gerar um certificado e uma chave privada para cada worker node do Kubernetes, através do comando abaixo:

```
for i in 0 1 2; do
  instance="worker-${i}"
  instance_hostname="ip-10-0-1-2${i}"
  cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance_hostname}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  internal_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PrivateIpAddress')

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${instance_hostname},${external_ip},${internal_ip} \
    -profile=kubernetes \
    worker-${i}-csr.json | cfssljson -bare worker-${i}
done
```

O resultado dos comandos acima serão os seguintes arquivos:
```
worker-0-csr.json
worker-0-key.pem
worker-0.csr
worker-0.pem

worker-1-csr.json
worker-1-key.pem
worker-1.csr
worker-1.pem

worker-2-csr.json
worker-2-key.pem
worker-2.csr
worker-2.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.


### Tarefa 03.02.03 - Criando os Certificados do Controller Manager Client

Gerar os certificados de cliente e a chave privada do `kube-controller-manager`, através dos comandos abaixo:

```
cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
```
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
```

O resultado dos comandos acima serão os seguintes arquivos:
```
kube-controller-manager-csr.json
kube-controller-manager-key.pem
kube-controller-manager.csr
kube-controller-manager.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.

### Tarefa 03.02.04 - Criando os Certificados de cliente do Kube-Proxy

Gerar o certificado de cliente e a chave privada do `kube-proxy`:

```
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
```
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

O resultado dos comandos acima serão os seguintes arquivos:
```
kube-proxy-csr.json
kube-proxy-key.pem
kube-proxy.csr
kube-proxy.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.

### Tarefa 03.02.05 - Criando os Certificados de cliente do Kube-Scheduler

Gerar o certificado de cliente do `kube-scheduler` e a chave privada:

```
cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
```
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
```

O resultado dos comandos acima serão os seguintes arquivos:
```
kube-scheduler-csr.json
kube-scheduler-key.pem
kube-scheduler.csr
kube-scheduler.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.

### Tarefa 03.02.06 - Criando os Certificados do Kubernetes API Server

O endereço IP estático do `kubernetes-mode-dificil` será adicionado na lista `subject alternative names` para o certificado do Kubernetes API Server. Isso garantirá que o certificado possa ser validado por clientes remotos.

Gere o certificado e a chave privada do servidor de API do Kubernetes:


```
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
```
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.0.1.10,10.0.1.11,10.0.1.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

> O servidor de API do Kubernetes recebe automaticamente o nome interno do DNS `kubernetes`, que será vinculado ao primeiro endereço IP (`10.32.0.1`) do intervalo de endereços (`10.32.0.0/24`) reservado para serviços do cluster interno durante o tutorial [Criando o Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md).

O resultado dos comandos acima serão os seguintes arquivos:
```
kubernetes-csr.json
kubernetes-key.pem
kubernetes.csr
kubernetes.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.


### Tarefa 03.02.07 - Criando o Par de Chaves para o Service Account

O Kubernetes Controller Manager utiliza um par de chaves para gerar e assinar tokens de contas de serviço, conforme descrito na documentação [managing service accounts](https://kubernetes.io/docs/admin/service-accounts-admin/).

Gere o certificado `service-account` e a chave privada:

```
cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
```
```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
```

O resultado dos comandos acima serão os seguintes arquivos:
```
service-account-csr.json
service-account-key.pem
service-account.csr
service-account.pem
```
Você utilizará os arquivos com extensão .pem nos tutoriais futuros.


### Tarefa 03.02.08 - Distribuindo os Certificados de cliente e dos servidores

Copie os certificados e chaves privadas para cada Worker Node:
```
for instance in worker-0 worker-1 worker-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa ca.pem ${instance}-key.pem ${instance}.pem ubuntu@${external_ip}:~/
done
```
> Caso receba a mensagem `Are you sure you want to continue connecting (yes/no)?`, responda com `yes`

Copie os certificados e chaves privadas para cada Controller Node:

```
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa \
    ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ubuntu@${external_ip}:~/
done
```
> Caso receba a mensagem `Are you sure you want to continue connecting (yes/no)?`, responda com `yes`

> Os certificados de cliente para o `kube-proxy`,` kube-controller-manager`, `kube-scheduler` e` kubelet` serão usados para gerar arquivos de configuração de autenticação de cliente no próximo tutorial.

Next: [Gerando os arquivos de configuração do Kubernetes](04-kubernetes-configuration-files.md)
