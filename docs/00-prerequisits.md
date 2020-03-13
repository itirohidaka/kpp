# Sessão 00 - Pré-requisitos para o KMD

## Amazon Web Services
Este tutorial utiliza a plataforma de núvem pública da [Amazon Web Services](https://aws.amazon.com/) para provisionar a infraestrutura de computação necessária e inicializar um cluster Kubernetes do zero (from scratch)!

> O provisionamento de recursos no ambiente AWS pode incorrer em custos, portanto utilize a [calculadora](https://calculator.s3.amazonaws.com/index.html) antes de iniciar o provisionamento de qualquer componente.

## Atividade 00.01 - Desktop/Laptop

### Tarefa 00.01 - Providenciando um Desktop/Laptop.

Para a conclusão de todas as etapas deste tutorial será necessário um desktop/laptop com Linux ou OSX. Você também poderá utilizar um bastion host na AWS para simular o papel do desktop/laptop. A maior parte dos exemplos deste tutorial foi exautivamente testado com o OSX. Caso encontre algum erro ou dificuldade, por favor, entre em contato para que possamos ajustá-lo.

## Atividade 00.02 - AWS Command Line Interface (CLI)

### Tarefa 00.02.01 - Instalando o AWS CLI (Command Line Interface) no seu desktop/laptop.

Siga a documentação oficial do [AWS CLI](https://aws.amazon.com/cli) para instalar e configurar o utilitário de linha de comando da `aws` no seu desktop/laptop.

Verificar se o AWS CLI está instalado corretamente. No terminal, utilizar o seguinte comando:

```
aws --version
```

> Saída (Exemplo)
```
aws-cli/1.16.130 Python/2.7.16 Darwin/19.3.0 botocore/1.12.120
```
OBS: No momento da elaboração deste documento eu utilizo a versão 1.16.130.
> Além da instação do AWS CLI siga a [documentação oficial](https://aws.amazon.com/cli/) para a configuração do mesmo.

### 00.02 - Definir uma Região padrão
Após definir as configurações iniciais do AWS CLI (Access Key ID e Secret Access Key), definir a região padrão através dos dois comandos abaixo. Neste exemplo considero a utilização da região `sa-east-1, ou seja South America - São Paulo.
```
AWS_REGION=sa-east-1
```
```
aws configure set default.region $AWS_REGION
```

Próximo: [Instalando os Client Tools](01-client-tools.md)
