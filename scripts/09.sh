# /bin/sh

echo "Tarefa 09.01.01 - Criando o arquivo de configuração do Admin Kubernetes"
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
--load-balancer-arns ${LOAD_BALANCER_ARN} \
--output text --query 'LoadBalancers[].DNSName')
kubectl config set-cluster kubernetes-modo-dificil \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem
kubectl config set-context kubernetes-modo-dificil \
  --cluster=kubernetes-modo-dificil \
  --user=admin
kubectl config use-context kubernetes-modo-dificil

