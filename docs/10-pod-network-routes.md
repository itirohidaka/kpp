# Sessão 10 - Provisionando as Rotas da Rede dos Pods

Os pods agendados para um nó recebem um endereço IP do intervalo do Pod CIDR do nó. Nesse momento, os pods não podem se comunicar com outros pods executando em nós diferentes devido à falta de rotas de rede.

Neste tutorial, você criará uma rota para cada worker node que mapeia o intervalo do CIDR do Pod do nó para o endereço IP interno do nó.

> Existem [outras maneiras](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) para implementar o modelo de rede Kubernetes.

## Atividade 10.01 - A tabela de Roteamento

> Nos workloads de produção, essa funcionalidade será fornecida pelos plug-ins da CNI, como flanel, calico, amazon-vpc-cni-k8s. Fazer isso manualmente facilita a compreensão do que esses plug-ins fazem nos bastidores.

### Tarefa 10.01.01 - Configuração da Tabela de Rotas

Nesta tarefa, você reunirá as informações necessárias para criar rotas na rede VPC `kubernetes-modo-dificil` e usará isso para criar entradas na tabela de rotas.

Anote o endereço IP interno e o intervalo do Pod CIDR para cada worker node e crie entradas da tabela de rotas:

```
for instance in worker-0 worker-1 worker-2; do
  instance_id_ip="$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]')"
  instance_id="$(echo "${instance_id_ip}" | cut -f1)"
  instance_ip="$(echo "${instance_id_ip}" | cut -f2)"
  pod_cidr="$(aws ec2 describe-instance-attribute \
    --instance-id "${instance_id}" \
    --attribute userData \
    --output text --query 'UserData.Value' \
    | base64 --decode | tr "|" "\n" | grep "^pod-cidr" | cut -d'=' -f2)"
  echo "${instance_ip} ${pod_cidr}"

  aws ec2 create-route \
    --route-table-id "${ROUTE_TABLE_ID}" \
    --destination-cidr-block "${pod_cidr}" \
    --instance-id "${instance_id}"
done
```

> saida

```
10.0.1.20 10.200.0.0/24
{
    "Return": true
}
10.0.1.21 10.200.1.0/24
{
    "Return": true
}
10.0.1.22 10.200.2.0/24
{
    "Return": true
}
```

## Atividade 10.02 - Testes

### Tarefa 10.02.01 - Validando as Rotas

Validar as rotas de rede para cada worker node:

```
aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --query 'RouteTables[].Routes'
```

> saida

```
[
    [
        {
            "DestinationCidrBlock": "10.200.0.0/24",
            "InstanceId": "i-0879fa49c49be1a3e",
            "InstanceOwnerId": "107995894928",
            "NetworkInterfaceId": "eni-0612e82f1247c6282",
            "Origin": "CreateRoute",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "10.200.1.0/24",
            "InstanceId": "i-0db245a70483daa43",
            "InstanceOwnerId": "107995894928",
            "NetworkInterfaceId": "eni-0db39a19f4f3970f8",
            "Origin": "CreateRoute",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "10.200.2.0/24",
            "InstanceId": "i-0b93625175de8ee43",
            "InstanceOwnerId": "107995894928",
            "NetworkInterfaceId": "eni-0cc95f34f747734d3",
            "Origin": "CreateRoute",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "10.0.0.0/16",
            "GatewayId": "local",
            "Origin": "CreateRouteTable",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "0.0.0.0/0",
            "GatewayId": "igw-00d618a99e45fa508",
            "Origin": "CreateRoute",
            "State": "active"
        }
    ]
]
```

Próximo: [Implementando o DNS](11-dns-addon.md)
