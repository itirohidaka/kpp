# Kubernetes Passo a Passo (KPP)
Este tutorial tem o objetivo de implementar um cluster Kubernetes Passo a Passo. Este guia NÃO foi criado para pessoas que procuram um comando totalmente automatizado para implementar um cluster Kubernetes (K8s). O KMD foi criado para o aprendizado, ou seja, é a rota mais longa de implementação do Kubernetes, com o intuito de você aprender cada tarefa requerida para o bootstrap do cluster.

> Os resultados deste tutorial NÃO devem ser vistos como production ready!!!

## Sessões

Este tutorial assume que você tem acesso ao [Amazon Web Services (AWS)](https://aws.amazon.com). Embora a AWS seja usada para requisitos básicos de infraestrutura, as lições aprendidas neste tutorial podem ser aplicadas a outras plataformas, com algumas poucas adaptações.

* [00 - Pré-Requisitos](docs/00-prerequisits.md)
* [01 - Instalando as Client Tools](docs/01-client-tools.md)
* [02 - Provisionando os Recursos Computacionais](docs/02-compute-resources.md)
* [03 - Provisionando o CA e gerando os certificados TLS](docs/03-certificate-authority.md)
* [04 - Gerando os arquivos de configuração do Kubernetes](docs/04-kubernetes-configuration-files.md)
* [05 - Gerando a chave e a configuracão para criptografia dos dados](docs/05-data-encryption-keys.md)
* [06 - Criando o cluster ETCD](docs/06-bootstrapping-etcd.md)
* [07 - Criando o Kubernetes Control Plane](docs/07-bootstrapping-kubernetes-controllers.md)
* [08 - Criando o Kubernetes Worker Nodes](docs/08-bootstrapping-kubernetes-workers.md)
* [09 - Configurando o kubectl para o acesso remoto](docs/09-configuring-kubectl.md)
* [10 - Provisionando o Pod Network Routes](docs/10-pod-network-routes.md)
* [11 - Implementando o DNS no Cluster Kubernetes](docs/11-dns-addon.md)
* [12 - Smoke Test](docs/12-smoke-test.md)
* [13 - Limpando Tudo!](docs/13-cleanup.md)

> Este documento foi criado com base no original [KTHW](https://github.com/kelseyhightower/kubernetes-the-hard-way) mas modificado e adaptado para a utilização da plataforma de núvem pública da AWS como infraestrutura. Alguns trechos do documento também foram modificados para atender as minhas necessidades de aprendizado durante o estudo para a certificação [CKA da CNCF](https://www.cncf.io/certification/cka/).

## Detalhes do Cluster K8s
Componentes e suas respectivas versões utilizadas na construção do Kubernetes no Modo Difícil.

* [kubernetes](https://github.com/kubernetes/kubernetes) 1.17.2
* [containerd](https://github.com/containerd/containerd) 1.3.2
* [coredns](https://github.com/coredns/coredns) v1.6.2
* [cni](https://github.com/containernetworking/cni) v0.8.5
* [etcd](https://github.com/coreos/etcd) v3.3.18

## Copyright

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.

> A maior parte dos exemplos deste tutorial foi exautivamente testado com o OSX. Caso encontre algum erro ou dificuldade, por favor, entre em contato para que possamos ajustá-lo.
