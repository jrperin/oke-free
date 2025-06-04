# Nginx Hello World

## Instalação Básica - Sem Certificado TLS

#### **1. Aplicar as configurações**

Execute os comandos:
``` bash
kubectl apply -f hello-deployment.yaml
kubectl apply -f hello-service.yaml
kubectl apply -f hello-ingress-sem-certificado.yaml
```

#### **2. Verificar a instalação**

Verificar se o deployment está rodando:

``` bash
kubectl get deployments
```

Verificar se o serviço está funcionando:

``` bash
kubectl get services
```

Verificar se o ingress foi criado:

``` bash
kubectl get ingress
```

#### **3. Acessar a aplicação**

Após alguns instantes, você poderá acessar sua aplicação usando o IP do Nginx Ingress:
``` bash
http://<MEU_IP_PUBLICO>/hello
```

Se você quiser associar um nome de domínio, configure seu DNS para apontar para o IP do Nginx Ingress Controller.

#### **4. (Opcional) Verificar logs do Ingress Controller**

``` bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --container controller
```
O Nginx Ingress Controller agora está redirecionando solicitações para `/hello` para o seu aplicativo!

---

## Instalar Certificado - Let's Encrypt

**NOTA:** Para executar essa parte, precisa ter feito a primeira parte `Instalação Básica - Sem Certificado TLS`

**ATENÇÃO!** Altere os conteúdos dentro dos arquivos para suas credenciais. Procure por "<MEU_SITE>" e "<MEU@EMAIL.COM>" nos arquivos de manifestos.

#### **1. Adicionar repositório Helm do Cert-Manager**

``` bash
helm repo add jetstack https://charts.jetstack.io
```

#### **2. Atualizar repositórios**

``` bash
helm repo update
```

#### **3. Instalar Cert-Manager com CRDs**

``` bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --wait
```

#### **4. Testar a instalacao**

``` bash
kubectl apply -f test-certmanager-resources.yaml
kubectl describe certificate -n cert-manager-test
# Limpar os recursos
kubectl delete -f test-certmanager-resources.yaml
```
**Obs.:** _Se esses passos acima foram executados sem erros, está tudo ok!_

#### **5. Aplique os arquivos para ClusterIssuer para Lets Encrypt**

``` bash
kubectl apply -f letsencrypt-issuer-staging.yaml
kubectl apply -f letsencrypt-issuer-prod.yaml

# Verifique o status dos issuers
kubectl get clusterissuer
```

#### **6. Aplique o arquivo de criação do certificado**

``` bash
kubectl apply -f hello-certificado.yaml

# Monitore o status do certificado
kubectl get certificate -n default
kubectl describe certificate <MEU_SITE>-tls -n default
```

#### **7. Aplicar o arquivo de Ingress com certificado**

``` bash
kubectl apply -f hello-ingress-com-certificado.yaml
```

#### **8. Verificar se o certificado foi emitido corretamente**

``` bash
# Verificar status do certificado
kubectl get certificate -n default

# Verificar detalhes do processo de certificação
kubectl get challenges -n default

# Verificar eventos do certificado
kubectl describe certificate <MEU_SITE>-tls -n default
```

---
## Troubleshooting


#### Verificação do status do certificado

``` bash

# Verificar se o ClusterIssuer foi criado corretamente
kubectl get clusterissuer

# Verificar detalhes do ClusterIssuer
kubectl describe clusterissuer letsencrypt-staging

# Listar certificate requests
kubectl get certificaterequest -n default

# Verificar detalhes do certificate request
kubectl describe certificaterequest -n default

# Monitorar o certificado em tempo real
kubectl get certificate <MEU_SITE>-tls -n default -w

# Verificar challenges do Let's Encrypt
kubectl get challenge -n default

# Verificar orders
kubectl get order -n default

# Logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager --tail=20

# Verificar eventos do namespace
kubectl get events -n default --sort-by='.lastTimestamp'
```

#### Verificar a resolução do DNS

``` bash
# Testar resolução DNS
nslookup <MEU_SITE>.com
nslookup www.<MEU_SITE>.com

# Testar acesso direto pelo IP
curl -H "Host: <MEU_SITE>.com" http://<MEU_IP_PUBLICO>/hello
curl -H "Host: www.<MEU_SITE>.com" http://<MEU_IP_PUBLICO>/hello

# Testar acesso pelo domínio (após propagação)
curl http://<MEU_SITE>.com/hello
curl http://www.<MEU_SITE>.com/hello
```

#### Domínio não carrega após 100% distribuído

- Validar se o domínio já foi distribuído: <https://www.whatsmydns.net>

Limpar cache DNS do sistema (Ubuntu/Debian)

``` bash
# Reiniciar o serviço de DNS local
sudo systemctl restart systemd-resolved

# Ou flush do cache DNS
sudo resolvectl flush-caches

# Verificar status
sudo resolvectl status
```


