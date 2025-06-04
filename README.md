# Cluster Kubernetes (OKE) na Oracle OCI com Ingress + Load Balancer


Antes de tudo, gostaria de agradecar ao [@Raphael Borges](https://r11s.com.br/) que criou o repositório [oke-free](https://github.com/Rapha-Borges/oke-free).

Utilizei o projeto dele e alterei para minhas necessidades e assim como ele disponibilizou o repositório para a comunidade também venho compartilhar minhas alterações.

[Veja a versão original do projeto no repositório do Rafael.](https://github.com/Rapha-Borges/oke-free)

**>> Daqui para baixo segue o manual original com as minhas alterações. <<**


## **Criando um Cluster Kubernetes na OCI utilizando OpenTofu [#MêsDoKubernetes](https://github.com/linuxtips/MesDoKubernetes)**

Crie uma conta gratuita na Oracle Cloud, e provisione um cluster Kubernetes utilizando o Terraform de forma simples e rápida.

Acesse este [link e crie a sua conta](https://signup.cloud.oracle.com/)

#### Pontos Importantes Antes de Começar

- Devido limitações da conta gratuita, você provavelmente precisará realizar o [upgrade para uma conta](https://cloud.oracle.com/invoices-and-orders/upgrade-and-payment) `Pay As You Go` para conseguir criar o cluster utilizando as instâncias gratuitas `VM.Standard.A1.Flex`. Você não será cobrado pelo uso de recursos gratuitos mesmo após o upgrade.

- Crie um alerta na sua conta para não ser cobrado por acidente [Budget](https://cloud.oracle.com/usage/budgets).

- Não altere o shape da instância utilizada no cluster, pois a única instância gratuita compatível com o OKE é a `VM.Standard.A1.Flex`.

### Instalando o OpenTofu

- GNU/Linux

```sh
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method deb
rm install-opentofu.sh
```

- Windows

```powershell
Invoke-WebRequest -outfile "install-opentofu.ps1" -uri "https://get.opentofu.org/install-opentofu.ps1"
& .\install-opentofu.ps1 -installMethod standalone
Remove-Item install-opentofu.ps1
```

### Instalando o OCI CLI

- GNU/Linux

1. Execute o comando de instalação:

```sh
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
```

2. Quando solicitado para atualizar a variável PATH, digite `yes` e ele atualizará automaticamente o arquivo .bashrc ou .bash_profile. Se você utiliza um shell diferente, precisará informar o caminho para o OCI CLI (por exemplo, ~/zshrc).

3. Reinicie sua sessão no terminal.

4. Verifique a instalação.

```sh
oci -v
```

- Windows

1. Faça download do instalador MSI da CLI do OCI para Windows no GitHub [Releases](https://github.com/oracle/oci-cli/releases)

2. Execute o instalador e siga as instruções.

## Instalando Kubectl - Kubernetes v1.31.1

- GNU/Linux

Kubectl é quem faz a comunicação com a API Kubernetes usando CLI. Devemos usar a mesma versão que está explicita no arquivo de variáveis. Veja [variables.tf](variables.tf)

1. Baixando o binário kubectl

```
curl -LO https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubectl
```

2. Instalando o binário

```
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
3. Adicione kubectl completion bash

```
echo '
source <(kubectl completion bash)' >> ~/.bashrc
```  
4. Valide a versão

```
kubectl version --client
```

- *Note: O comando acima irá gerar um aviso:*
    "WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short."

**Você pode ignorar este aviso. Você está apenas verificando a versão do kubectl que instalou.**

- Windows

1. Baixe o binário kubectl

```
curl.exe -LO "https://dl.k8s.io/release/v1.31.1/bin/windows/amd64/kubectl.exe"
```

2. **Anexe a pasta binária kubectl à sua variável de ambiente PATH.**

3. Valide a versão

```
kubectl version --client --output=yaml
```

**🔗 [Guia de instalação para todos os ambientes](https://kubernetes.io/docs/tasks/tools/)**

## Autenticando na OCI

1. Antes de começar, clone o repositório.

```sh
git clone https://github.com/jrperin/oke-free.git
# git clone https://github.com/Rapha-Borges/oke-free.git
```

2. Crie uma `API key`

- Entre no seu perfil, acesse a aba [API Keys](https://cloud.oracle.com/identity/domains/my-profile/api-keys) e clique em `Add API Key`.

3. Selecione `Generate API key pair`, faça o download da chave privada. Em seguida, clique em `Add`.

4. Após o download, mova a chave para o diretório do `OCI CLI` e renomeie para `oci_api_key.pem`.

- GNU/Linux

```
mkdir -p ~/.oci && mv ~/Downloads/<nome_do_arquivo>.pem ~/.oci/oci_api_key.pem

cp ~/.oci/oci_api_key.pem ./ssh
```

- Windows

```
move C:\Users\<user>\Downloads\<nome_do_arquivo>.pem C:\Users\<user>\.oci\oci_api_key.pem

copy C:\Users\<user>\.oci\oci_api_key.pem ssh
```

5. Corrija as permissões da chave privada:

```
oci setup repair-file-permissions --file <caminho_da_chave_privada>
```

6. Copie o texto que apareceu na página de criação da `API KEY` para o arquivo de configuração do `OCI CLI`. Não se esqueça de substituir o valor do compo `key_file` pelo caminho da chave privada.

- GNU/Linux

```
vim ~/.oci/config
```

```
[DEFAULT]
user=ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
fingerprint=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
tenancy=ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
region=xxxxxxxx
key_file=~/.oci/oci_api_key.pem
```

- Windows

```
notepad C:\Users\<user>\.oci\config
```

```
[DEFAULT]
user=ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
fingerprint=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
tenancy=ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
region=xxxxxxxx
key_file=C:\Users\<user>\.oci\oci_api_key.pem
```

7. Crie a pasta `./ssh` e gere a chave `ssh` (No Windows, utilize o [Git Bash](https://git-scm.com/downloads) para executar o comando abaixo).

```bash
ssh-keygen -t rsa -b 4096 -f ./ssh/id_rsa
```

8. Crie o arquivo com as variáveis de ambiente, substituindo os valores das variáveis pelos valores da sua conta (o conteúdo usado no arquivo ~/.oci/config acima).

- GNU/Linux

```
vim ./env.sh
```

```
export TF_VAR_tenancy_ocid=<your tenancy ocid>
export TF_VAR_user_ocid=<your user ocid>
export TF_VAR_fingerprint=<your fingerprint>
export TF_VAR_private_key_path=$PWD/ssh/oci_api_key.pem
export TF_VAR_ssh_public_key=$(cat $PWD/ssh/id_rsa.pub)
export TF_VAR_region="<your region>"
# Optional if you want to use a different profile name change the value below
export TF_VAR_oci_profile="DEFAULT"
```

Agora rode o script para exportar as variáveis:

```
source ./env.sh
```

- Windows

No Windows, você pode criar um arquivo `env.bat` com o conteúdo abaixo e executar o arquivo para exportar as variáveis.

```
set TF_VAR_tenancy_ocid=<your tenancy ocid>
set TF_VAR_user_ocid=<your user ocid>
set TF_VAR_fingerprint=<your fingerprint>
set TF_VAR_private_key_path=C:\Users\<user>\.oci\oci_api_key.pem
set TF_VAR_ssh_public_key=C:\Users\<user>\.oci\ssh\id_rsa.pub
set TF_VAR_region="<your region>"
# Optional if you want to use a different profile name change the value below
set TF_VAR_oci_profile="DEFAULT"
```

Agora execute o arquivo para exportar as variáveis:

```
env.bat
```



## Criando o cluster

1. **Antes de criar o Cluster**

Vamos criar 3 componentes que vão facilitar o uso do nosso cluster.
  
  - Criar um `compartment` que será utilizado para salvar os recursos para não serem destruídos.
  
  - Criar um `bucket` com `arquivo` e um `pre-authenticated request` para armazenamento do estado do Terraform (Tofu).
  
  - Criar um `Public Reserved IP` que permitirá que nosso IP público não mude mesmo que o cluster seja destruído.

  - Isso será feito pelo script:
    >``` bash
    >prepare.sh
    >```
  
  - **Nota:** Ao final do `apply` do tofu o script vai copiar o Public IP do compartment `default` para o compartment `k8s` e antes do `destroy` o IP será copiado novamente para o compartment `default` para permitir a exclusao do compartment `k8s`. Os scripts que são utilizados pelo processo são `ip_restore.sh` e `ip_backup.sh` respectivamente.
  

2. **Instale os módulos**

```sh
tofu init
```

3. **Crie o cluster**

```sh
tofu apply
```

- OBS: Opicionalmente, você pode utilizar o comando `tofu plan` para visualizar as alterações que serão realizadas antes de executar o `tofu apply`. Com os seguintes comandos:

```
tofu plan -out=oci.tfplan
tofu apply -auto-approve "oci.tfplan"
```

4. **Edite o arquivo** `~/.kube/config` para adicionar a autenticação com a `API KEY` conforme exemplo abaixo

```sh
- name: user-xxxxxxxxxx
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: oci
      args:
      - ce
      - cluster
      - generate-token
      - --cluster-id
      - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      - --region
      - xxxxxxxxxxx
      - --auth            # ADICIONE ESSA LINHA
      - api_key           # ADICIONE ESSA LINHA
      - --profile         # ADICIONE ESSA LINHA
      - DEFAULT           # ADICIONE ESSA LINHA
```

5. **Acesse o cluster**

```sh
kubectl get nodes
```

## Load Balancer

**NOTA: O Load Balancer vai ser criado via Nginx Ingress via HELM**

  - Para atribuir um Reserved IP automaticamente na criação do Loadbalancer, ele passa a ser criado na instalação do Nginx Controller via Helm


### Configurando o Nginx Ingress com Network Load Balancer

#### Configurar Nginx Ingress + NLB

1. Ter o Reserved IP Criado

Como descrito anteriormente, o  `Reserved IP` deveria estar criado e nesse momento já copiado para o Compartment `k8s`.

**ATENÇÃO!** Se o Reserved IP não estiver no mesmo compartment que o cluster o Network Load Balancer instala corretamente.

  >Os scripts `ip_backup.sh` e `ip_restore.sh` são executados localmente pelo terraform para restore e backup do IP público.
  > 
  >- `ip_restore.sh` é executado localmente via terraform após a criação do compartment para permitir que o Nginx Controller possa usá-lo para criar o LoadBalancer.
  > 
  >- `ip_backupt.sh` é executado antes do deploy para mover o IP Reservado para o cluster default para nao atrapalhar o destroy.


2. Criar o Nginx Ingress via Helm

``` shell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace \
    --set controller.service.annotations.oci\\.oraclecloud\\.com/load-balancer-type=nlb \
    --set controller.service.annotations.oci-network-load-balancer\\.oraclecloud\\.com/is-preserve-source=True \
    --set controller.service.externalTrafficPolicy=Local \
    --set controller.service.loadBalancerIP="129.148.34.39"
```

3. Validar a instalação

``` shell
kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch
```

4. Configurar o Ingress com Microsserviço (com / sem Certificado)

Na pasta `./manifests/nginx_hello-world` existem os manifestos para serem utilizados

### [./manifests/README.md](./manifests/nginx_hello-world/README.md)
- Leia o passo a passo no arquivo  da pasta `manifests/nginx_helo-world`.

---
---

## Deletando o cluster

1. Para deletar o cluster bastar executar o comando:

```sh
tofu destroy
```

## Problemas conhecidos

- ### Se você tentar criar um cluster com uma conta gratuita e receber o erro abaixo

```
Error: "Out of capacity" ou "Out of host capacity"
```

As contas gratuitas tem um número limitado de instâncias disponíveis, possivelmente a região que você está tentando criar o cluster não tem mais instâncias disponíveis. Você pode esperar até que novas instâncias fiquem disponíveis ou tentar criar o cluster em outra região. Além disso, o upgrade para uma conta `Pay As You Go` pode resolver o problema, pois as contas `Pay As You Go` tem um número maior de instâncias disponíveis. Você não será cobrado pelo uso de recursos gratuitos mesmo após o upgrade.

- ### Erro `401-NotAuthenticated` ou o comando `kubectl` não funciona. Isso ocorre porque o token de autenticação expirou

Gere um novo token de autenticação e exporte para a variável de ambiente `OCI_CLI_AUTH`.

```sh
oci session authenticate --region us-ashburn-1
```

- Linux

```sh
export OCI_CLI_AUTH=security_token
```

- Windows

```sh
set OCI_CLI_AUTH=security_token
```

- ### Erros devido a falha na execução do `tofu destroy`, impossibilitando a exclusão do cluster e todos os recursos. Ou erros como o `Error Code: CompartmentAlreadyExists` que não são resolvidos com o `tofu destroy`

Para resolver esse problema, basta deletar os recursos manualmente no console da OCI. Seguindo a ordem abaixo:

- [**Kubernetes Cluster**](https://cloud.oracle.com/containers/clusters)
- [**Virtual Cloud Networks**](https://cloud.oracle.com/networking/vcns)
- [**Compartments**](https://cloud.oracle.com/identity/compartments)

Obs: Caso não apareça o Cluster ou a VPN para deletar, certifique que selecionou o Compartment certo `k8s`.

# Referências

- [**OpenTofu Documentation**](https://opentofu.org/docs/)
- [**Terrafom Essentials**](https://www.linuxtips.io/course/terraform-essentials)
- [**Free Oracle Cloud Kubernetes cluster with Terraform**](https://arnoldgalovics.com/oracle-cloud-kubernetes-terraform/)

- [**Tweaking Installation of Ingress Nginx on OKE With Helm**](https://ivan-delic.medium.com/tweaking-installation-of-ingress-nginx-on-oke-with-helm-60b6c3cdee1a)
- [**Configurando um Controlador de Entrada Nginx em um Cluster**](https://docs.oracle.com/pt-br/iaas/Content/ContEng/Tasks/contengsettingupingresscontroller.htm)
- [**Ingress NGINX Controller**](https://github.com/kubernetes/ingress-nginx)
- [**Ingress-Nginx Controller - Installation Guide**](https://kubernetes.github.io/ingress-nginx/deploy/)
- [**cert-manager site**](https://cert-manager.io/docs/)
- [**Let’s Encrypt Certificate using Cert-Manager on Kubernetes (HTTP Challenge)**](https://medium.com/@manojit123/lets-encrypt-certificate-using-cert-manager-on-kubernetes-http-challenge-687ce3718baf)

---

### Criado por [@Raphael Borges](https://r11s.com.br/)

### ALterado por [@Joao Perin](https://jrperin.com/)