# Sessão 08 - Criando os Kubernetes Worker Nodes

Neste tutorial, você inicializará três worker nodes do Kubernetes. Os seguintes componentes serão instalados em cada nó: [runc](https://github.com/opencontainers/runc), [plug-ins de rede de contêiner](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/admin/kubelet) e [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## Atividade 08.01 - Pré Requisitos

### Tarefa 08.01.01 - Comandos SSH para o acesso aos Worker Nodes

Os comandos nesta tarefa devem ser executados no seu desktop/laptop e irá gerar os comandos necessários (SSH) para que você possa acessar cada um dos worker nodes.

```
for instance in worker-0 worker-1 worker-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo ssh -i kubernetes.id_rsa ubuntu@$external_ip
done
```

## Atividade 08.02 - Configurando os Worker Nodes

> Todos os comandos a seguir deverão ser executados em cada um dos worker nodes do Kubernetes.

### Tarefa 08.02.01 - Instalando as dependências do Sistema Operacional

Após efetaur o login no worker node, instalar as dependências do Sistema Operacional:

```
sudo apt-get update
```
```
sudo apt-get -y install socat conntrack ipset
```

> O binário do socat habilita o suporte para o comando `kubectl port-forward`.

### Tarefa 08.02.02 - Desabilitar o Swap

Por padrão, o kubelet falhará ao iniciar se o [swap](https://help.ubuntu.com/community/SwapFaq) estiver ativado. É [recomendado](https://github.com/kubernetes/kubernetes/issues/7294) que o swap seja desativado para garantir que o Kubernetes possa fornecer alocação adequada de recursos e qualidade de serviço.

Verifique se o swap está ativado:

```
sudo swapon --show
```
Se a saída estiver vazia, o swap não está ativado. Se o swap estiver ativado, execute o seguinte comando para desativá-lo imediatamente:

```
sudo swapoff -a
```

> Para que o swap permaneça desabilitado após o reboot consulte a documentação da sua distribuição Linux.

### Tarefa 08.02.03 - Download e Instalação do Binários do Worker Node

Faça o download dos binários oficiais do Kubernetes:

```
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.17.0/crictl-v1.17.0-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-the-hard-way/runsc \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc10/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz \
  https://github.com/containerd/containerd/releases/download/v1.3.2/containerd-1.3.2.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/linux/amd64/kubelet
```

Criar os diretórios de instalação:

```
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Instalar os binário do worker node:

```
chmod +x kubectl kube-proxy kubelet runc.amd64 runsc
```
```
sudo mv runc.amd64 runc
```
```
sudo mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/
```
```
sudo tar -xvf crictl-v1.17.0-linux-amd64.tar.gz -C /usr/local/bin/
```
```
sudo tar -xvf cni-plugins-linux-amd64-v0.8.5.tgz -C /opt/cni/bin/
```
```
sudo tar -xvf containerd-1.3.2.linux-amd64.tar.gz -C /
```

### Tarefa 08.02.04 - Configurar a rede CNI

Recupere o intervalo do CIDR do Pod para a instância computacional atual:

```
POD_CIDR=$(curl -s http://169.254.169.254/latest/user-data/ \
  | tr "|" "\n" | grep "^pod-cidr" | cut -d"=" -f2)
```
```
echo "${POD_CIDR}"
```

Criar o arquivo de configuração da rede `bridge`:

```
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

Criar o arquivo de configuração da rede `loopback`:

```
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
```

### Tarefa 08.02.05 - Configurar o containerd

Criar o arquivo de configuração do `containerd`:

```
sudo mkdir -p /etc/containerd/
```

```
cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
EOF
```

Criar o arquivo systemd unit `containerd.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 08.02.06 - Configurar o Kubelet

```
WORKER_NAME=$(curl -s http://169.254.169.254/latest/user-data/ \
| tr "|" "\n" | grep "^name" | cut -d"=" -f2)
```
```
echo "${WORKER_NAME}"
```
```
sudo mv ${WORKER_NAME}-key.pem ${WORKER_NAME}.pem /var/lib/kubelet/
```
```
sudo mv ${WORKER_NAME}.kubeconfig /var/lib/kubelet/kubeconfig
```
```
sudo mv ca.pem /var/lib/kubernetes/
```

Criar o arquivo de configuração `kubelet-config.yaml`:

```
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${WORKER_NAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${WORKER_NAME}-key.pem"
resolvConf: "/run/systemd/resolve/resolv.conf"
EOF
```

> A configuração `resolvConf` é usada para evitar loops ao usar o CoreDNS para descoberta de serviço em sistemas executando` systemd-resolved`.

Criar o arquivo systemd unit `kubelet.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 08.02.07 - Configurar o Kubernetes Proxy

```
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Criar o arquivo de configuração `kube-proxy-config.yaml`:

```
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
```

Criar o arquivo systemd unit `kube-proxy.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 08.02.08 - Inicializar o serviços do Worker Node

```
sudo systemctl daemon-reload
```
```
sudo systemctl enable containerd kubelet kube-proxy
```
```
sudo systemctl start containerd kubelet kube-proxy
```

> Lembrar de executar os comandos anteriores em cada um dos worker nodes: `worker-0`, `worker-1`, and `worker-2`.

## Atividade 08.03 - Testes

### Tarefa 08.03.01 - Verificação do Worker Node

> As instâncias computacionais criadas neste tutorial não terão permissão para concluir esta seção. Execute os seguintes comandos na mesma máquina usada para criar as instâncias computacionais.

Liste os nós do cluster Kubernetes:


```
external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=controller-0" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
```
```
ssh -i kubernetes.id_rsa ubuntu@${external_ip}
```
```
kubectl get nodes --kubeconfig admin.kubeconfig
```

> saída

```
NAME             STATUS   ROLES    AGE   VERSION
ip-10-0-1-20   Ready    <none>   51s   v1.17.2
ip-10-0-1-21   Ready    <none>   51s   v1.17.2
ip-10-0-1-22   Ready    <none>   51s   v1.17.2
```

Próximo: [Configurando o kubectl para o acesso remoto](09-configuring-kubectl.md)
