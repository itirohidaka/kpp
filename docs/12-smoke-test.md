# Sessão 12 - Smoke Test

Neste tutorial, você efetuará uma série de tarefas para garantir que seu cluster Kubernetes esteja funcionando corretamente.

## Atividade 12.01 - Testando o Cluster Kubernetes

### Tarefa 12.01.01 - Testando a Criptografia de dados

Nesta tarefa, você verificará a capacidade de [criptografar dados secretos em repouso](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Crie um secret genérico:

```
kubectl create secret generic kubernetes-modo-dificil \
  --from-literal="mykey=mydata"
```
Exibir um hexdump do secret `kubernetes-modo-dificil` armazenado no etcd:

```
external_ip=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=controller-0" \
  --output text --query 'Reservations[].Instances[].PublicIpAddress')
```
```
ssh -i kubernetes.id_rsa ubuntu@${external_ip}
```

Executar o seguinte comando no controller-0:
```
sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-modo-dificil | hexdump -C
```

> saída

```
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 7b 8e 59 78 0f 59 09  |:v1:key1:{.Yx.Y.|
00000050  e2 6a ce cd f4 b6 4e ec  bc 91 aa 87 06 29 39 8d  |.j....N......)9.|
00000060  70 e8 5d c4 b1 66 69 49  60 8f c0 cc 55 d3 69 2b  |p.]..fiI`...U.i+|
00000070  49 bb 0e 7b 90 10 b0 85  5b b1 e2 c6 33 b6 b7 31  |I..{....[...3..1|
00000080  25 99 a1 60 8f 40 a9 e5  55 8c 0f 26 ae 76 dc 5b  |%..`.@..U..&.v.[|
00000090  78 35 f5 3e c1 1e bc 21  bb 30 e2 0c e3 80 1e 33  |x5.>...!.0.....3|
000000a0  90 79 46 6d 23 d8 f9 a2  d7 5d ed 4d 82 2e 9a 5e  |.yFm#....].M...^|
000000b0  5d b6 3c 34 37 51 4b 83  de 99 1a ea 0f 2f 7c 9b  |].<47QK....../|.|
000000c0  46 15 93 aa ba 72 ba b9  bd e1 a3 c0 45 90 b1 de  |F....r......E...|
000000d0  c4 2e c8 d0 94 ec 25 69  7b af 08 34 93 12 3d 1c  |......%i{..4..=.|
000000e0  fd 23 9b ba e8 d1 25 56  f4 0a                    |.#....%V..|
000000ea
```

A chave etcd deve ser prefixada com `k8s: enc: aescbc: v1: key1`, que indica que o provedor `aescbc` foi usado para criptografar os dados com a chave de criptografia `key1`.

### Tarefa 12.01.02 - Deployments do Kubernetes

Nesta tarefa, você verificará a capacidade de criar e gerenciar [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Crie um deployment para o servidor web [nginx](https://nginx.org/en/):

```
kubectl create deployment nginx --image=nginx
```

Listar o pod criado pelo deployment `nginx`:

```
kubectl get pods -l app=nginx
```

> saída

```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-554b9c67f9-vt5rn   1/1     Running   0          10s
```

### Tarefa 12.01.03 - Testando o Port Forwarding

Nesta tarefa, você verificará a capacidade de acessar aplicativos remotamente usando [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Recupere o nome completo do pod `nginx`:
```
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
```

Encaminhe a porta `8080` em sua máquina local para a porta` 80` do pod `nginx`:

```
kubectl port-forward $POD_NAME 8080:80
```

> saída:

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

Em um novo terminal faça uma chamada HTTP utilizando o endereço de encaminhamento:

```
curl --head "http://127.0.0.1:8080"
```

> saída:

```
HTTP/1.1 200 OK
Server: nginx/1.17.3
Date: Sat, 14 Sep 2019 21:10:11 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Aug 2019 08:50:00 GMT
Connection: keep-alive
ETag: "5d5279b8-264"
Accept-Ranges: bytes
```

Volte para o terminal anterior e pare o encaminhamento de portas do nginx:

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
^C
```

### Tarefa 12.01.03 - Testando os Logs

Nesta seção, você verificará a capacidade de [recuperar logs de contêineres](https://kubernetes.io/docs/concepts/cluster-administration/logging/).

Exiba os logs do pod `nginx`:
```
kubectl logs $POD_NAME
```

> saída

```
127.0.0.1 - - [14/Sep/2019:21:10:11 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.52.1" "-"
```

### Tarefa 12.01.04 - Testando a Execução de Comandos

Nesta tarefa, você verificará a capacidade de [executar comandos em um contêiner](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Exiba a versão do nginx executando o comando `nginx -v` no contêiner` nginx`:
```
kubectl exec -ti $POD_NAME -- nginx -v
```

> saída

```
nginx version: nginx/1.17.3
```

### Tarefa 12.01.05 - Testando a exposição de Serviços

Nesta tarefa, você verificará a capacidade de expor aplicativos usando um [Serviço](https://kubernetes.io/docs/concepts/services-networking/service/).

Exponha o deployment `nginx` usando um serviço [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport):
```
kubectl expose deployment nginx --port 80 --type NodePort
```

> O tipo de serviço LoadBalancer não pode ser usado porque seu cluster não está configurado com [integração de provedor de nuvem](https://kubernetes.io/docs/getting-started-guides/scratch/#cloud-provider). A configuração da integração do provedor de nuvem está fora do escopo deste tutorial.

Recupere a porta do nó atribuída ao serviço `nginx`:
```
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```
Crie uma regra de firewall que permita acesso remoto à porta do nó `nginx`:

```
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol tcp \
  --port ${NODE_PORT} \
  --cidr 0.0.0.0/0
```

Recupere o endereço de IP externo do worker node:
```
INSTANCE_NAME=worker-0
```
```
EXTERNAL_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
```

Faça uma chamada HTTP utiliznado o IP externo e o node port do `nginx`:

```
curl -I "http://${EXTERNAL_IP}:${NODE_PORT}"
```

> saída

```
HTTP/1.1 200 OK
Server: nginx/1.17.3
Date: Sat, 14 Sep 2019 21:12:35 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Aug 2019 08:50:00 GMT
Connection: keep-alive
ETag: "5d5279b8-264"
Accept-Ranges: bytes
```

Próximo: [Limpando Tudo!](13-cleanup.md)
