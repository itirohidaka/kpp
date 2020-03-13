# Sessão 09 - Configurando o kubectl para o acesso remoto

Neste tutorial, você irá gerar um arquivo kubeconfig para o utilitário de linha de comando `kubectl` com base nas credenciais do usuário `admin`.

## Atividade 09.01 - O Arquivo de configuração do Kubernetes

> Execute os comandos neste laboratório a partir do mesmo diretório usado para gerar os certificados do cliente administrador (seu desktop/laptop).

### Tarefa 09.01.01 - Criando o arquivo de configuração do Admin Kubernetes

Cada kubeconfig requer um servidor de API do Kubernetes para se conecte. Para oferecer suporte à alta disponibilidade, o endereço IP atribuído ao balanceador de carga externo em frente aos servidores de API do Kubernetes será usado.

Criar um arquivo kubeconfig adequado para autenticação como o usuário `admin`:
```
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --name kubernetes --output text --query 'LoadBalancers[].LoadBalancerArn')
```
```
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
--load-balancer-arns ${LOAD_BALANCER_ARN} \
--output text --query 'LoadBalancers[].DNSName')
```
```
kubectl config set-cluster kubernetes-modo-dificil \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443
```
```
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem
```
```
kubectl config set-context kubernetes-modo-dificil \
  --cluster=kubernetes-modo-dificil \
  --user=admin
```
```
kubectl config use-context kubernetes-modo-dificil
```

## Atividade 09.02 - Testes

### Tarefa 09.02.01 - Verificar a Saúde do Cluster

Verificar a saúde do cluster Kubernetes remoto:

```
kubectl get componentstatuses
```

> saída

```
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
etcd-0               Healthy   {"health":"true"}
```

Listar os nós do cluster Kubernetes remoto:

```
kubectl get nodes
```

> saída

```
NAME             STATUS   ROLES    AGE     VERSION
ip-10-0-1-20   Ready    <none>   3m35s   v1.17.2
ip-10-0-1-21   Ready    <none>   3m35s   v1.17.2
ip-10-0-1-22   Ready    <none>   3m35s   v1.17.2
```

Próximo: [Provisionando o Pod Network Routes](10-pod-network-routes.md)
