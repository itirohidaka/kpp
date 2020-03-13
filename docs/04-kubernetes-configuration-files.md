# Sessão 04 - Gerando os arquivos de configuração do Kubernetes

Neste laboratório, você irá gerar os [arquivos de configuração do Kubernetes](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), também conhecido como kubeconfigs. Eles permitem que os clientes do Kubernetes localizem e se autentiquem nos servidores da API do Kubernetes.

> Todos os comandos deste tutorial deverão ser executados no seu desktop/laptop.

## Atividade 04.01 - Configuração de Autenticação dos Clientes

Nesta seção, você irá gerar arquivos kubeconfig para os clientes `controller manager`,` kubelet`, `kube-proxy` e `scheduler` e para o usuário `admin`.

### Tarefa 04.01.01 - Recuperando o IP Público do Kubernetes

Cada kubeconfig requer um servidor de API do Kubernetes para se conectar. Para oferecer suporte à alta disponibilidade, utilizaresmo o endereço IP atribuído ao balanceador de carga externo situado em frente aos servidores de API do Kubernetes.

Recupere o endereço IP estático do `kubernetes-modo-dificil` e armazene na variável de ambiente KUBERNETES_PUBLIC_ADDRESS. Utilize o comando abaixo para realizar essa tarefa.

```
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[0].DNSName')
```

### Tarefa 04.01.02 - Criando o Arquivo de Configuração do Kubelet

Ao gerar os arquivos kubeconfig para o Kubelets, devemos utilizar o certificado do cliente correspondente ao nome do nó do Kubelet. Isso garantirá que o Kubelet seja devidamente autorizados pelo Kubernetes [Node Authorizer](https://kubernetes.io/docs/admin/authorization/node/).

> Os comandos a seguir devem ser executados no mesmo diretório usado para gerar os certificados SSL durante o tutorial [Gerando certificados TLS](04-certificate-authority.md).

Gere um arquivo kubeconfig para cada worker node, utilizando o comando abaixo:

```
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
```

O resultado do comando acima será:

```
worker-0.kubeconfig
worker-1.kubeconfig
worker-2.kubeconfig
```

### Tarefa 04.01.03 - Criando o Arquivo de Configuração do kube-proxy

Criar o arquivo kubeconfig para o serviço `kube-proxy`, utilizando os comandos abaixo:


```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443 \
  --kubeconfig=kube-proxy.kubeconfig
```
```
kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
```
```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
```
```
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

O resultado do comando acima será:

```
kube-proxy.kubeconfig
```


### Tarefa 04.01.04 - Criando o Arquivo de Configuração do kube-controller-manager

Criar o arquivo kubeconfig  para o serviço `kube-controller-manager`, utilizando os comandos abaixo:

```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig
```
```
kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig
```
```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig
```
```
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
```

O resultado do comando acima será:

```
kube-controller-manager.kubeconfig
```


### Tarefa 04.01.05 - Criando o Arquivo de configuração do kube-scheduler

Criar o arquivo de kubeconfig para o serviço `kube-scheduler`, utilizando os comandos abaixo:

```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig
```
```
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig
```
```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig
```
```
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
```

O resultado do comando acima será:
```
kube-scheduler.kubeconfig
```

### Tarefa 04.01.06 - Criando o Arquivo de configuração do admin

Criar o arquivo kubeconfig para o usuário `admin`

```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig
```
```
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig
```
```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin.kubeconfig
```
```
kubectl config use-context default --kubeconfig=admin.kubeconfig
```

O resultado do comando acima será:
```
admin.kubeconfig
```


### Tarefa 04.01.07 - Distribuir os arquivos de configuração do Kubernetes

Copiar os arquivos kubeconfig do `kubelet` e do `kube-proxy` para cada worker node:

```
for instance in worker-0 worker-1 worker-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa \
    ${instance}.kubeconfig kube-proxy.kubeconfig ubuntu@${external_ip}:~/
done
```

Copiar o arquivos kubeconfig do `kube-controller-manager` e do `kube-scheduler` para cada controller node:

```
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa \
    admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ubuntu@${external_ip}:~/
done
```

Next: [Gerando a chave e a configuracão para criptografia dos dados](05-data-encryption-keys.md)
