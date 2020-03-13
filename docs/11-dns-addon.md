# Sessão 11 - Implementando o DNS no Cluster Kubernetes

Neste tutorial, você implantará o [DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) que fornece o serviço de Service Discovery baseado em DNS, apoiada pelo [CoreDNS](https://coredns.io/), para aplicativos em execução no cluster Kubernetes.

## Atividade 11.01 - O add-on DNS do cluster Kubernetes

### Tarefa 11.01.01 - Implementando o CoreDNS

Implemente o `coredns`:

```
kubectl apply -f https://raw.githubusercontent.com/itirohidaka/kthw_aws_ptbr/master/yaml/coredns.yaml
```

> saída

```
serviceaccount/coredns unchanged
clusterrole.rbac.authorization.k8s.io/system:coredns unchanged
clusterrolebinding.rbac.authorization.k8s.io/system:coredns unchanged
configmap/coredns unchanged
deployment.apps/coredns unchanged
service/kube-dns unchanged
```

Listar os pods criados pelo deployment `kube-dns`:

```
kubectl get pods -l k8s-app=kube-dns -n kube-system
```

> saída (exemplo)

```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-68567cdb47-7gzwf   1/1     Running   0          18h
coredns-68567cdb47-mmgk7   1/1     Running   0          18h
```

## Atividade 11.02 - Testes

### Tarefa 11.02.01 - Verificação do Service Discovery

Criar um deployment do `busybox`:

```
kubectl run --generator=run-pod/v1 busybox --image=busybox:1.28 --command -- sleep 3600
```

Listar os pods criados pelo deployment `busybox`:

```
kubectl get pods -l run=busybox
```

> saída

```
NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          3s
```

Recuperar o nome completo do pod `busybox`:

```
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
```

Executar um DNS lookup para o serviço `kubernetes` dentro do pod `busybox`:

```
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

> saída:

```
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
```

Próximo: [Smoke Test](12-smoke-test.md)
