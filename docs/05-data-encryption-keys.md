# Sessão 05 - Gerando a chave e a configuracão para criptografia dos dados

O Kubernetes armazena uma variedade de dados, incluindo o estado do cluster, configurações de aplicativos e secrets. O Kubernetes suporta a capacidade de [criptografar](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) dados em repouso (data at rest) em cluster.

## Atividade 05.01 - A chave de criptografia

Neste tutorial, você irá gerar uma chave de criptografia e uma [configuração de criptografia](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) para criptografar os secrests do Kubernetes.

### Tarefa 05.01.01 - Criando a chave de criptografia

Criando uma chave de criptografia:

```
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

### Tarefa 05.01.02 - Criando o Arquivo de Configuraçãp da Criptografia

Criar o arquivo YAML de configuração da criptografia `encryption-config.yaml`:

```
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
```

### Tarefa 05.01.03 - Copiando o arquivo YAML para os Controller nodes

Copiar o arquivo `encryption-config.yaml` para cada controller node:
```
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i kubernetes.id_rsa encryption-config.yaml ubuntu@${external_ip}:~/
done
```

Next: [Criando o cluster ETCD](06-bootstrapping-etcd.md)
