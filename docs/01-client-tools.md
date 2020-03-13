# Sessão 01 - Instalando as Ferramentas de Cliente (Client Tools)

Neste tutorial, você instalará os utilitários de linha de comando necessários para conclui-lo. São eles o [cfssl](https://github.com/cloudflare/cfssl), [cfssljson](https://github.com/cloudflare/cfssl), e [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl).

> Todos os comandos deste tutorial deverão ser executados no seu desktop/laptop.

## 01.01 - Instalação do CFSSL e o CFSSLJSON

Os utilitários de linha de comando `cfssl` e `cfssljson` serão utilizados para provisionar uma [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) e gerar os certificados TLS.

Faça o download e instale `cfssl` e `cfssljson`, utilizando os comandos abaixo:

### OS X

```
curl -o cfssl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/darwin/cfssl
```
```
curl -o cfssljson https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/darwin/cfssljson
```

```
chmod +x cfssl cfssljson
```

```
sudo mv cfssl cfssljson /usr/local/bin/
```

Alguns usuários do OS X podem ter problemas ao usar os binários pré-criados. Se esse for o seu caso o [Homebrew](https://brew.sh) pode ser uma opção melhor:

```
brew install cfssl
```

### Linux

```
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssljson
```

```
chmod +x cfssl cfssljson
```

```
sudo mv cfssl cfssljson /usr/local/bin/
```

### Verificação

Verifique se as versões do `cfssl` e do `cfssljson` 1.3.4 ou superior estão instaladas, através dos comandos:

```
cfssl version
```

> Saída (Exemplo)

```
Version: 1.3.4
Revision: dev
Runtime: go1.13
```

```
cfssljson --version
```
```
Version: 1.3.4
Revision: dev
Runtime: go1.13
```

## 01.02 - Instalar o KUBECTL

O utilitário de linha de comando `kubectl` é usado para interagir com o Servidor de APIs do Kubernetes. Faça o download e instale o `kubectl` a partir dos binários oficiais:

### OS X

```
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.17.2/bin/darwin/amd64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Linux

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Verificação

Verificar se o `kubectl` version 1.15.3 ou superior está instalado, através do comando abaixo:

```
kubectl version --client
```

> output

```
Client Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.2", GitCommit:"59603c6e503c87169aea6106f57b9f242f64df89", GitTreeState:"clean", BuildDate:"2020-01-23T14:21:36Z", GoVersion:"go1.13.6", Compiler:"gc", Platform:"darwin/amd64"}
```

Próximo: [Provisionando os Recursos Computacionais](02-compute-resources.md)
