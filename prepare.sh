#!/bin/bash

# Definir variáveis
COMPARTMENT_NAME="default"
RESERVED_IP_NAME="site-ip_01"
BUCKET_NAME="oke-free-terraform_state"
TFSTATE_FILE="terraform.tfstate"

if [ ! -f ~/.oci/config ]; then
    echo "Erro: Arquivo de configuração OCI não encontrado em ~/.oci/config"
    exit 1
fi

# Obter o OCID da tenancy do arquivo de configuração
TENANCY_OCID=$(grep tenancy ~/.oci/config | cut -d'=' -f2)

# Obter a região do arquivo de configuração
REGION=$(grep region ~/.oci/config | cut -d'=' -f2)
if [ -z "$TENANCY_OCID" ] || [ -z "$REGION" ]; then
    echo "Erro: Não foi possível obter o OCID da tenancy ou a região do arquivo de configuração."
    echo "Espera-se que o arquivo ~/.oci/config contenha as linhas:"
    echo "tenancy=ocid1.tenancy.oc1..xxxxxx"
    echo "region=sa-saopaulo-1"
    exit 1
fi

echo "Tenancy OCID encontrado no arquivo de configuração: $TENANCY_OCID"
echo "Região encontrada no arquivo de configuração: $REGION"

# CRIANDO O COMPARTMENT PADRAO PARA SALVAR RECURSOS QUE NAO DEVEM SER APAGADOS

# Verificar se o compartment já existe
EXISTING_COMPARTMENT=$(oci iam compartment list \
    --compartment-id "$TENANCY_OCID" \
    --query "data[?name=='$COMPARTMENT_NAME'].id | [0]" \
    --raw-output 2>/dev/null)

if [ -z "$EXISTING_COMPARTMENT" ] || [ "$EXISTING_COMPARTMENT" == "null" ]; then
    echo "Compartment '$COMPARTMENT_NAME' não encontrado. Criando..."
    
    # Criar o compartment
    COMPARTMENT_RESULT=$(oci iam compartment create \
        --compartment-id "$TENANCY_OCID" \
        --name "$COMPARTMENT_NAME" \
        --description "Compartment padrão criado automaticamente" \
        --query 'data.id' \
        --raw-output)
    
    if [ $? -eq 0 ]; then
        echo "Compartment '$COMPARTMENT_NAME' criado com sucesso!"
        COMPARTMENT_ID="$COMPARTMENT_RESULT"
    else
        echo "Erro ao criar compartment '$COMPARTMENT_NAME'"
        exit 1
    fi
else
    echo "Compartment '$COMPARTMENT_NAME' já existe com ID: $EXISTING_COMPARTMENT"
    COMPARTMENT_ID="$EXISTING_COMPARTMENT"
fi

echo "Usando Compartment ID: $COMPARTMENT_ID"

# CRIANDO IP RESERVADO NO COMPARTMENT DEFAULT

echo "Verificando se o IP reservado '$RESERVED_IP_NAME' já existe..."

EXISTING_IP=$(oci network public-ip list \
    --compartment-id "$COMPARTMENT_ID" \
    --scope REGION \
    --query "data[?\"display-name\"=='$RESERVED_IP_NAME'].id | [0]" \
    --raw-output 2>/dev/null)

if [ -z "$EXISTING_IP" ] || [ "$EXISTING_IP" == "null" ]; then
    echo "IP reservado '$RESERVED_IP_NAME' não encontrado. Criando..."
    
    # Criar o IP público reservado
    CREATE_RESULT=$(oci network public-ip create \
        --compartment-id "$COMPARTMENT_ID" \
        --lifetime RESERVED \
        --display-name "$RESERVED_IP_NAME" \
        --query 'data.id' \
        --raw-output)
    
    if [ $? -eq 0 ]; then
        echo "IP reservado '$RESERVED_IP_NAME' criado com sucesso!"
        echo "IP OCID: $CREATE_RESULT"
        
        # Obter o endereço IP criado
        IP_ADDRESS=$(oci network public-ip get \
            --public-ip-id "$CREATE_RESULT" \
            --query 'data."ip-address"' \
            --raw-output)
        echo "Endereço IP: $IP_ADDRESS"
    else
        echo "Erro ao criar IP reservado '$RESERVED_IP_NAME'"
        exit 1
    fi
else
    echo "IP reservado '$RESERVED_IP_NAME' já existe com ID: $EXISTING_IP"
    
    # Mostrar o endereço IP existente
    IP_ADDRESS=$(oci network public-ip get \
        --public-ip-id "$EXISTING_IP" \
        --query 'data."ip-address"' \
        --raw-output)
    echo "Endereço IP existente: $IP_ADDRESS"
fi

# CRIANDO BUCKET PARA TERRAFORM STATE

echo "Verificando se o bucket '$BUCKET_NAME' já existe..."

# Obter namespace do object storage
NAMESPACE=$(oci os ns get --query 'data' --raw-output)
echo "Object Storage Namespace: $NAMESPACE"

EXISTING_BUCKET=$(oci os bucket get \
    --namespace "$NAMESPACE" \
    --bucket-name "$BUCKET_NAME" \
    --query 'data.name' \
    --raw-output 2>/dev/null)

if [ -z "$EXISTING_BUCKET" ]; then
    echo "Bucket '$BUCKET_NAME' não encontrado. Criando..."
    
    # Criar o bucket
    oci os bucket create \
        --compartment-id "$COMPARTMENT_ID" \
        --name "$BUCKET_NAME" \
        --namespace "$NAMESPACE"
    
    if [ $? -eq 0 ]; then
        echo "Bucket '$BUCKET_NAME' criado com sucesso!"
    else
        echo "Erro ao criar bucket '$BUCKET_NAME'"
        exit 1
    fi
else
    echo "Bucket '$BUCKET_NAME' já existe"
fi

# CRIANDO ARQUIVO TERRAFORM STATE VAZIO

echo "Verificando se o arquivo '$TFSTATE_FILE' já existe no bucket..."

EXISTING_OBJECT=$(oci os object get \
    --namespace "$NAMESPACE" \
    --bucket-name "$BUCKET_NAME" \
    --name "$TFSTATE_FILE" \
    --file /dev/null 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Arquivo '$TFSTATE_FILE' não encontrado. Criando arquivo vazio..."
    
    # Criar arquivo temporário vazio
    touch /tmp/empty_tfstate.json
    echo '{}' > /tmp/empty_tfstate.json
    
    # Fazer upload do arquivo vazio
    oci os object put \
        --namespace "$NAMESPACE" \
        --bucket-name "$BUCKET_NAME" \
        --name "$TFSTATE_FILE" \
        --file /tmp/empty_tfstate.json
    
    if [ $? -eq 0 ]; then
        echo "Arquivo '$TFSTATE_FILE' criado com sucesso!"
        rm -f /tmp/empty_tfstate.json
    else
        echo "Erro ao criar arquivo '$TFSTATE_FILE'"
        rm -f /tmp/empty_tfstate.json
        exit 1
    fi
else
    echo "Arquivo '$TFSTATE_FILE' já existe no bucket"
fi

# CRIANDO PRE-AUTHENTICATED REQUEST

echo "Verificando Pre-Authenticated Requests existentes..."

# Listar PARs existentes
EXISTING_PAR=$(oci os preauth-request list \
    --namespace "$NAMESPACE" \
    --bucket-name "$BUCKET_NAME" \
    --query "data[?name=='terraform-state-par'].id | [0]" \
    --raw-output 2>/dev/null)

if [ -z "$EXISTING_PAR" ] || [ "$EXISTING_PAR" == "null" ]; then
    echo "Criando Pre-Authenticated Request para o arquivo terraform state..."
    
    # Calcular data de expiração (1 ano a partir de hoje)
    EXPIRY_DATE=$(date -d "+10 year" -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Criar PAR com permissões de leitura e escrita
    PAR_RESULT=$(oci os preauth-request create \
        --namespace "$NAMESPACE" \
        --bucket-name "$BUCKET_NAME" \
        --name "terraform-state-par" \
        --access-type ObjectReadWrite \
        --time-expires "$EXPIRY_DATE" \
        --object-name "$TFSTATE_FILE")
    
    if [ $? -eq 0 ]; then
        echo "Pre-Authenticated Request criado com sucesso!"
        echo "Data de expiração:  $EXPIRY_DATE"
        
        # Extrair a URL do PAR
        PAR_URL=$(echo "$PAR_RESULT" | jq -r '.data."access-uri"')
        FULL_URL="https://objectstorage.${REGION}.oraclecloud.com${PAR_URL}"
        
        echo "URL do Pre-Authenticated Request: $FULL_URL"
        echo ""
        echo "IMPORTANTE: Atualize seu arquivo tfstate_config.tf com a seguinte URL:"
        echo "address = \"$FULL_URL\""

        # Salvar a URL em um arquivo para uso posterior
        echo "# URL do Pre-Authenticated Request" > pre-auth_request_url.txt
        echo "# Data de expiração: $EXPIRY_DATE" >> pre-auth_request_url.txt
        echo "# Use o conteúdo abaixo no arquivo: \"tfstate_config.tf\"" >> pre-auth_request_url.txt
        echo ""                            >> pre-auth_request_url.txt
        echo "terraform {"                 >> pre-auth_request_url.txt
        echo "backend "http" {"            >> pre-auth_request_url.txt
        echo "    update_method = \"PUT\"" >> pre-auth_request_url.txt
        echo "    # Arquivo especifico:"   >> pre-auth_request_url.txt
        echo "    address = \"$FULL_URL\"" >> pre-auth_request_url.txt
        echo "    }"                       >> pre-auth_request_url.txt
        echo "}"                           >> pre-auth_request_url.txt
        echo ""                            >> pre-auth_request_url.txt

        echo "URL do Pre-Authenticated Request salva em pre-auth_request_url.txt"

    else
        echo "Erro ao criar Pre-Authenticated Request"
        exit 1
    fi
else
    echo "Pre-Authenticated Request já existe com ID: $EXISTING_PAR"
fi

echo "Script prepare.sh concluído com sucesso!"