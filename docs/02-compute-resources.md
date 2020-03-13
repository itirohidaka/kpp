# Sessão 02 - Provisionando os Recursos Computacionais na AWS

O Kubernetes requer um conjunto de máquinas para hospedar o Control Plane e os Worker Nodes nos quais os contêineres são executados. Neste tutorial, você provisionará os recursos de computação necessários para executar um cluster Kubernetes seguro e altamente disponível em uma única [Zona de Disponibilidade](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).

> Tenha certeza que vocês definiu uma região padrão como descrito no tutorial [Pré-requisitos](01-prerequisitos.md).
> Todos os comandos deste tutorial deverão ser executados no seu desktop/laptop.

## Atividade 02.01 - Rede (Networking)

O [modelo de rede do Kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) considera uma rede plana (flat network) na qual contêineres e nós (nodes) podem se comunicar. Nos casos em que isso não é desejado, as [políticas de rede](https://kubernetes.io/docs/concepts/services-networking/network-policies/) podem limitar a comunicação entre os grupos de contêineres e, também, com os endpoints de rede externos.

> A configuração das políticas de rede está fora do escopo deste tutorial.

### Tarefa 02.01.01 - Criando as Rede VPC (Virtual Private Cloud)

Nesta seção, uma rede [Virtual Private Cloud](https://aws.amazon.com/vpc/) (VPC) será configurada para hospedar o cluster Kubernetes na AWS.


Crie a rede customizada VPC chamada `kubernetes-modo-dificil`, utilizando o(s) comando(s) abaixo:

```
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId')
```
```
aws ec2 create-tags --resources ${VPC_ID} --tags Key=Name,Value=kubernetes-modo-dificil
```
```
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-support '{"Value": true}'
```
```
aws ec2 modify-vpc-attribute --vpc-id ${VPC_ID} --enable-dns-hostnames '{"Value": true}'
```

### Tarefa 02.01.02 - Criando as Subnets

Uma [sub-rede/subnet](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html) deverá ser criada com um intervalo de endereços IP grande o suficiente para atribuir um endereço IP privado a cada nó do cluster Kubernetes.

Crie a sub-rede (subnet) na rede VPC `kubernetes-modo-dificil`, utilizando o(s) comando(s) abaixo:

```
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.1.0/24 \
  --output text --query 'Subnet.SubnetId')
```
```
aws ec2 create-tags --resources ${SUBNET_ID} --tags Key=Name,Value=kubernetes
```

> O range de IPs `10.0.1.0/24` poderá ter até 253 instancias computacionais.

### Tarefa 02.01.03 - Criando o Internet Gateway

Crie um gateway de internet (internet gateway) na rede VPC `kubernetes-modo-dificil`, utilizando o(s) comando(s) abaixo:

```
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId')
```
```
aws ec2 create-tags --resources ${INTERNET_GATEWAY_ID} --tags Key=Name,Value=kubernetes
```
```
aws ec2 attach-internet-gateway --internet-gateway-id ${INTERNET_GATEWAY_ID} --vpc-id ${VPC_ID}
```

### Tarefa 02.01.04 - Criando o Route Table

Crie um route table na rede VPC `kubernetes-modo-dificil`, utilizando o(s) comando(s) abaixo:
```
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id ${VPC_ID} --output text --query 'RouteTable.RouteTableId')
```
```
aws ec2 create-tags --resources ${ROUTE_TABLE_ID} --tags Key=Name,Value=kubernetes
```
```
aws ec2 associate-route-table --route-table-id ${ROUTE_TABLE_ID} --subnet-id ${SUBNET_ID}
```
```
aws ec2 create-route --route-table-id ${ROUTE_TABLE_ID} --destination-cidr-block 0.0.0.0/0 --gateway-id ${INTERNET_GATEWAY_ID}
```

### Tarefa 02.01.05 - Criando os Security Groups

Crie os security groups na rede VPC `kubernetes-modo-dificil`, utilizando o(s) comando(s) abaixo:
```
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name kubernetes \
  --description "Kubernetes security group" \
  --vpc-id ${VPC_ID} \
  --output text --query 'GroupId')
```
```
aws ec2 create-tags --resources ${SECURITY_GROUP_ID} --tags Key=Name,Value=kubernetes
```
```
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol all --cidr 10.0.0.0/16
```
```
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol all --cidr 10.200.0.0/16
```
```
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0
```
```
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 6443 --cidr 0.0.0.0/0
```
```
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr 0.0.0.0/0
```
```
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol icmp --port -1 --cidr 0.0.0.0/0
```

### Tarefa 02.01.06 - Criando o Balanceador de Cargas

> Um [balanceador de cargas externo](https://aws.amazon.com/elasticloadbalancing/) será criado para expôr os servidores de API do Kubernetes para os clientes remotos.

Crie o Balanceador de Cargas na rede VPC `kubernetes-modo-dificil`, utilizando o(s) comando(s) abaixo:
```
LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
    --name kubernetes \
    --subnets ${SUBNET_ID} \
    --scheme internet-facing \
    --type network \
    --output text --query 'LoadBalancers[].LoadBalancerArn')
```
```
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name kubernetes \
    --protocol TCP \
    --port 6443 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --output text --query 'TargetGroups[].TargetGroupArn')
```
```
aws elbv2 register-targets --target-group-arn ${TARGET_GROUP_ARN} --targets Id=10.0.1.1{0,1,2}
```
```
aws elbv2 create-listener \
    --load-balancer-arn ${LOAD_BALANCER_ARN} \
    --protocol TCP \
    --port 443 \
    --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} \
    --output text --query 'Listeners[].ListenerArn'
```

```
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')
```

## Atividade 02.02 - Instâncias Computacionais (EC2)

As instâncias computacionais neste tutorial serão provisionadas usando o [Ubuntu Server](https://www.ubuntu.com/server) 18.04 como sistema operacional, que oferece um bom suporte para o [ContainerD container runtime](https://github.com/containerd/containerd). Cada instância computacional será provisionada com um endereço IP, privado e fixo, para simplificar o processo de inicialização do Kubernetes.

### Tarefa 02.02.01 - Definindo a Imagem das Instâncias Computacionais

Definiremos a imagem das instâncias computacionais através do comando abaixo:
```
IMAGE_ID=$(aws ec2 describe-images --owners 099720109477 \
  --filters \
  'Name=root-device-type,Values=ebs' \
  'Name=architecture,Values=x86_64' \
  'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*' \
  | jq -r '.Images|sort_by(.Name)[-1]|.ImageId')
```

### Tarefa 02.02.02 - Criando o SSH Key Pair

Um par de chaves será utilizado para o acesso seguro as Instâncias Computacionais. Para criar o SSH Key Pair utilize o(s) comando(s) abaixo:
```
aws ec2 create-key-pair --key-name kubernetes --output text --query 'KeyMaterial' > kubernetes.id_rsa
```
```
chmod 600 kubernetes.id_rsa
```

### Tarefa 02.02.03 - Criando os Controller Nodes

Criar 3 instâncias computacionais, do tipo t3.micro, utilizando o(s) comando(s) abaixo. Esses instâncias computacionais farão o papel de Kubernetes Controller Node.

```
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t3.micro \
    --private-ip-address 10.0.1.1${i} \
    --user-data "name=controller-${i}" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings='{"DeviceName": "/dev/sda1", "Ebs": { "VolumeSize": 50 }, "NoDevice": "" }' \
    --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=controller-${i}"
  echo "controller-${i} created "
done
```

### Tarefa 02.02.03 - Criando os Worker Nodes

Cada Worker Node requer uma alocação de sub-rede para os PODs no intervalo CIDR do cluster Kubernetes. A alocação de sub-rede dos PODs será usada para configurar a rede de contêineres em um tutorial posterior. Os metadados da instância `pod-cidr` serão usados para expor as alocações da sub-rede do pod para as instâncias computacionais em tempo de execução (runtime).

> O intervalo CIDR do cluster Kubernetes é definido pelo Flag `--cluster-cidr` do Controller Manager. Neste tutorial, o intervalo CIDR do cluster será definido como `10.200.0.0 / 16`, que suporta 254 sub-redes.

Crie três instâncias computacionais que hospedarão os worker nodes do Kubernetes, através do(s) comando(s) abaixo:

```
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name kubernetes \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t3.micro \
    --private-ip-address 10.0.1.2${i} \
    --user-data "name=worker-${i}|pod-cidr=10.200.${i}.0/24" \
    --subnet-id ${SUBNET_ID} \
    --block-device-mappings='{"DeviceName": "/dev/sda1", "Ebs": { "VolumeSize": 50 }, "NoDevice": "" }' \
    --output text --query 'Instances[].InstanceId')
  aws ec2 modify-instance-attribute --instance-id ${instance_id} --no-source-dest-check
  aws ec2 create-tags --resources ${instance_id} --tags "Key=Name,Value=worker-${i}"
  echo "worker-${i} created"
done
```

Próximo: [Provisionando o CA e gerando os certificados TLS](03-certificate-authority.md)
