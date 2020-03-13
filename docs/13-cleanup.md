# Sessão 13 - Limpando Tudo!

Nesta sessão você excluirá os recursos de computação criados durante este tutorial.

> Todos os comandos deste tutorial deverão ser executados no seu desktop/laptop.

## Atividade 13.01 - Cleanup!

### Tarefa 13.01.01 - Excluindo as Instâncias Computacionais

Exclua as instâncias computacionais do controller e do worker, com os seguintes comandos:

```
aws ec2 terminate-instances \
  --instance-ids \
    $(aws ec2 describe-instances \
      --filter "Name=tag:Name,Values=controller-0,controller-1,controller-2,worker-0,worker-1,worker-2" \
      --output text --query 'Reservations[].Instances[].InstanceId')
```
```
aws ec2 delete-key-pair --key-name kubernetes
```

### Tarefa 13.01.02 - Excluindo os componentes de Rede

Exclua os recursos da rede VPC na AWS, utilizando os comandos abaixo:

```
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --name kubernetes --output text --query 'LoadBalancers[].LoadBalancerArn')
```
```
aws elbv2 delete-load-balancer --load-balancer-arn "${LOAD_BALANCER_ARN}"
```
```
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --name kubernetes --output text --query 'TargetGroups[].TargetGroupArn')
```
```
aws elbv2 delete-target-group --target-group-arn "${TARGET_GROUP_ARN}"
```
```
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=kubernetes" --output text --query 'SecurityGroups[].GroupId')
```
```
aws ec2 delete-security-group --group-id "${SECURITY_GROUP_ID}"
```
```
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=kubernetes" --output text --query 'RouteTables[].RouteTableId')
```
```
ROUTE_TABLE_ASSOCIATION_ID="$(aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --output text --query 'RouteTables[].Associations[].RouteTableAssociationId')"
```
```
aws ec2 disassociate-route-table --association-id "${ROUTE_TABLE_ASSOCIATION_ID}"
```
```
aws ec2 delete-route-table --route-table-id "${ROUTE_TABLE_ID}"
```
```
INTERNET_GATEWAY_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=kubernetes" --output text --query 'InternetGateways[].InternetGatewayId')
```
```
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=kubernetes-modo-dificil" --output text --query 'Vpcs[].VpcId')
```
```
aws ec2 detach-internet-gateway \
  --internet-gateway-id "${INTERNET_GATEWAY_ID}" \
  --vpc-id "${VPC_ID}"
```
```
aws ec2 delete-internet-gateway --internet-gateway-id "${INTERNET_GATEWAY_ID}"
```
```
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=kubernetes" --output text --query 'Subnets[].SubnetId')
```
```
aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"
```
```
aws ec2 delete-vpc --vpc-id "${VPC_ID}"
```

Parabéns você conluiu o tutorial do Kubernetes no Modo Dificil (KMD)...Fim!
