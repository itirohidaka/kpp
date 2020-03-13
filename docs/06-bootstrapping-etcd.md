# Sessão 06 - Configurando o cluster etcd

Os componentes do Kubernetes são stateless e armazenam o estado do cluster no [etcd](https://github.com/etcd-io/etcd). Neste tutorial, você inicializará um cluster etcd de três nós e o configurará para alta disponibilidade e acesso remoto seguro.

## Atividade 06.01 - Pré Requisitos

### Tarefa 06.01.01 - Comandos SSH para acesso aos Controller Nodes

Os comandos nesta tarefa devem ser executados no seu desktop e irá gerar os comandos necessários (SSH) para que você possa acessar cada um dos controller nodes.

```
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo ssh -i kubernetes.id_rsa ubuntu@$external_ip
done
```
Agora poderá utilizar um utilitário de terminal (term por exemplo) para acessar cada um dos controller nodes.

## Atividade 06.02 - Implementação do Cluster ETCD

> Todos os comandos a seguir deverão ser executados em cada um dos controller nodes do Kubernetes.

### Tarefa 06.02.01 - Fazendo o download e instalando os binários do etcd

Após efetuar o login no controller node, faça o download dos binários oficiais do projeto [etcd](https://github.com/etcd-io/etcd) no GitHub, utilizando o seguinte comando:
```
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.3.18/etcd-v3.3.18-linux-amd64.tar.gz"
```
Descompactar e instalar o `etcd`server e o utilitário de linha de comando `etcdctl`:

```
tar -xvf etcd-v3.3.18-linux-amd64.tar.gz
```
```
sudo mv etcd-v3.3.18-linux-amd64/etcd* /usr/local/bin/
```

### Tarefa 06.02.02 - Configurar o servidor etcd

```
sudo mkdir -p /etc/etcd /var/lib/etcd
```
```
sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

O endereço IP interno da instância será usado para atender as solicitações de clientes e se comunicar com os pares do cluster etcd. Recupere o endereço IP interno da instância computacional atual, utilizando o seguinte comando:

```
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
```

Cada membro do etcd deve ter um nome exclusivo dentro do cluster etcd. Defina o nome etcd para corresponder ao nome do host da instância computacional atual:

```
ETCD_NAME=$(curl -s http://169.254.169.254/latest/user-data/ \
  | tr "|" "\n" | grep "^name" | cut -d"=" -f2)
```
```
echo "${ETCD_NAME}"
```

Criar o arquivo systemd unit `etcd.service`:

```
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.0.1.10:2380,controller-1=https://10.0.1.11:2380,controller-2=https://10.0.1.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Tarefa 06.02.03 - Inicializar o servidor etcd

```
sudo systemctl daemon-reload
```
```
sudo systemctl enable etcd
```
```
sudo systemctl start etcd
```

> Lembrar de executar os comando anteriores em cada um dos controller nodes: `controller-0`, `controller-1`, and `controller-2`.

## Atividade 06.03 - Testes

### Tarefa 06.03.01 - Verificação do Controller Node

Após a execução das Atividades/Tarefas anteriores em todos os controller nodes, listar os membror do cluster etcd para testar o funcionando do cluster etcd. O comando abaixo deverá ser executado em um dos controller nodes.

```
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
```

> exemplo de saída:

```
3a57933972cb5131, started, controller-2, https://10.240.0.12:2380, https://10.240.0.12:2379
f98dc20bce6225a0, started, controller-0, https://10.240.0.10:2380, https://10.240.0.10:2379
ffed16798470cab5, started, controller-1, https://10.240.0.11:2380, https://10.240.0.11:2379
```

Próximo: [Criando o Kubernetes Control Plane](07-bootstrapping-kubernetes-controllers.md)
