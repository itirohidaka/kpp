# /bin/sh

echo "Tarefa 05.01.01 - Criando a chave de criptografia"
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

echo "Tarefa 05.01.02 - Criando o Arquivo de Configuraçãp da Criptografia"
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

echo "Tarefa 05.01.03 - Copiando o arquivo YAML para os Controller nodes"
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	  encryption-config.yaml ubuntu@${external_ip}:~/
done

echo "Fim da sessão 05"
