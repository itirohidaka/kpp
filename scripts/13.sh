# /bin/sh

echo "Tarefa 13.01.01 - Excluindo as Instâncias Computacionais"
aws ec2 terminate-instances \
  --instance-ids \
    $(aws ec2 describe-instances \
      --filter "Name=tag:Name,Values=controller-0,controller-1,controller-2,worker-0,worker-1,worker-2" \
      --output text --query 'Reservations[].Instances[].InstanceId')
aws ec2 delete-key-pair --key-name kubernetes
aws ec2 delete-tags --resources $(aws ec2 describe-instances --filters "Name=tag:Name,Values=controller-0,controller-1,controller-2,worker-0,worker-1,worker-2" --output text --query 'Reservations[].Instances[].InstanceId')

echo "Tarefa 13.01.02 - Excluindo os componentes de Rede"
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --name kubernetes --output text --query 'LoadBalancers[].LoadBalancerArn')
aws elbv2 delete-load-balancer --load-balancer-arn "${LOAD_BALANCER_ARN}"
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --name kubernetes --output text --query 'TargetGroups[].TargetGroupArn')
aws elbv2 delete-target-group --target-group-arn "${TARGET_GROUP_ARN}"

NI=$(aws ec2 describe-network-interfaces --filters "Name=group-name,Values=kubernetes" --query "NetworkInterfaces[].Groups[].GroupName")
LNI=$(echo $NI | wc -c)

i=0
i=$((LNI))
sec=0
echo "Aguardando a exclusão das Network Interfaces..."
while [ $i -ne 3 ]
do
   NI=$(aws ec2 describe-network-interfaces --filters "Name=group-name,Values=kubernetes" --query "NetworkInterfaces[].Groups[].GroupName")
   LNI=$(echo $NI | wc -c)
   i=$((LNI))
   echo "Aguardando exclusão das NetInterfaces...$sec s $LNI"
   sleep 5
   sec=$(( $sec + 5 ))
done

echo " "
echo "Excluindo os Security Groups..."
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=kubernetes" --output text --query 'SecurityGroups[].GroupId')
aws ec2 delete-security-group --group-id "${SECURITY_GROUP_ID}"

echo "Excluindo as Route Tables..."
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=kubernetes" --output text --query 'RouteTables[].RouteTableId')
ROUTE_TABLE_ASSOCIATION_ID="$(aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --output text --query 'RouteTables[].Associations[].RouteTableAssociationId')"
aws ec2 disassociate-route-table --association-id "${ROUTE_TABLE_ASSOCIATION_ID}"
aws ec2 delete-route-table --route-table-id "${ROUTE_TABLE_ID}"

echo "Excluindo o Internet Gateway..."
INTERNET_GATEWAY_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=kubernetes" --output text --query 'InternetGateways[].InternetGatewayId')
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=kubernetes-modo-dificil" --output text --query 'Vpcs[].VpcId')
aws ec2 detach-internet-gateway \
  --internet-gateway-id "${INTERNET_GATEWAY_ID}" \
  --vpc-id "${VPC_ID}"
aws ec2 delete-internet-gateway --internet-gateway-id "${INTERNET_GATEWAY_ID}"

echo "Excluindo as Subnets..."
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=kubernetes" --output text --query 'Subnets[].SubnetId')
aws ec2 delete-subnet --subnet-id "${SUBNET_ID}"

echo "Excluindo as VPCs..."
aws ec2 delete-vpc --vpc-id "${VPC_ID}"

echo "Fim da Sessão 13 (CleanUP)"
