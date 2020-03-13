# Sessão 07 - Criando o Kubernetes Control Plane

Neste tutorial, você irá inicializar o Control Plane do Kubernetes em três instâncias computacionais e configurá-los para alta disponibilidade. Você também criará um balanceador de carga externo que expõe os servidores de API do Kubernetes aos clientes remotos. Os seguintes componentes serão instalados em cada controller node: Kubernetes API Server, Scheduler e Controller Manager.

## Atividade 07.01 - Pré Requisitos

### Tarefa 07.01.01 - Comandos SSH para o acesso aos Controller Nodes

Os comandos nesta tarefa devem ser executados no seu desktop e irá gerar os comandos necessários (SSH) para que você possa acessar cada um dos controller nodes.

```
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo ssh -i kubernetes.id_rsa ubuntu@$external_ip
done
```

## Atividade 07.02 - Implementação do Kubernetes Control Plane

> Todos os comandos a seguir deverão ser executados em cada um dos controller nodes do Kubernetes.

### Tarefa 07.02.01 - Fazer o download e instalar os binários do Kubernetes Controller

Criar o diretório de configuração do Kubernetes:

```
sudo mkdir -p /etc/kubernetes/config
```

Faça o download dos binários oficiais do Kubernetes:

```
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kubectl"
```

Instalar os binários do Kubernetes:

```
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
```
```
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
```

### Tarefa 07.02.02 - Configurar o Kubernetes API Server

```
sudo mkdir -p /var/lib/kubernetes/
```
```
sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem \
  encryption-config.yaml /var/lib/kubernetes/
```

O endereço IP interno da instância será usado para anunciar o servidor da API aos membros do cluster. Recupere o endereço IP interno da instância computacional atual:

```
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
```

Criar o arquivo systemd unit `kube-apiserver.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.0.1.10:2379,https://10.0.1.11:2379,https://10.0.1.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 07.02.03 - Configurar o Kubernetes Controller Manager

Mover o arquivo kubeconfig do `kube-controller-manager`:

```
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Criar o arquivo systemd unit `kube-controller-manager.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 07.02.04 - Configurar o Kubernetes Scheduler

Mover o arquivo kubeconfig `kube-scheduler`:

```
sudo mkdir -p /etc/kubernetes/config/
```
```
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Criar o arquivo de configuração `kube-scheduler.yaml`:

```
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

Criar o arquivo systemd unit `kube-scheduler.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 07.02.05 - Inicializar os serviços do Controller

```
sudo systemctl daemon-reload
```
```
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
```
```
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

> Aguardar cerca de 30 segundo para a inicialização do Kubernetes API Server.
```
kubectl get componentstatuses
```
> Saída:
```
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
etcd-1               Healthy   {"health":"true"}
```

## Atividade 07.03 - RBAC para a autorização do Kubelet

Nesta atividade, você configurará as permissões de RBAC para permitir que o servidor de API do Kubernetes acesse a API do Kubelet em cada worker node. O acesso à API do Kubelet é necessário para recuperar métricas, logs e executar comandos em pods.

> Este tutorial define a flag do Kubelet `--authorization-mode` como `Webhook`. O modo Webhook usa a API [SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) para determinar a autorização.

> Os comandos nesta seção afetarão todo o cluster e precisam ser executados apenas uma vez a partir de um dos controller nodes.

### Tarefa 07.03.01 - Configurar o RBAC

Criar o `system: kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) com permissões para acessar a API do Kubelet e executar a maior parte das tarefas associadas ao gerenciamento de pods:

```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

O servidor de API do Kubernetes se autentica no Kubelet como o usuário `kubernetes` usando o certificado do cliente, conforme definido pela flag ` - --kubelet-client-certificate`.

Associe o ClusterRole do `system: kube-apiserver-to-kubelet` ao usuário` kubernetes`:

```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

## Atividade 07.04 - Testes

### Tarefa 07.04.01 - Verificação do Controller Node

> As instâncias computacionais criadas neste tutorial não terão permissão para concluir esta seção. ** Execute os seguintes comandos na mesma máquina usada para criar as instâncias de computação (seu desktop/laptop)**.

Recupere o endereço IP estático do `kubernetes-modo-dificil`:

```
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')
```
Faça uma chamada HTTP para obter a versão do Kubernetes:

```
curl -k --cacert ca.pem "https://${KUBERNETES_PUBLIC_ADDRESS}/version"
```

> Saída

```
{
  "major": "1",
  "minor": "17",
  "gitVersion": "v1.17.2",
  "gitCommit": "59603c6e503c87169aea6106f57b9f242f64df89",
  "gitTreeState": "clean",
  "buildDate": "2020-01-18T23:22:30Z",
  "goVersion": "go1.13.5",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

Next: [Criando o Kubernetes Worker Nodes](08-bootstrapping-kubernetes-workers.md)
