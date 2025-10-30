#!/bin/bash
set -e

# Script para criar buckets iniciais no MinIO

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "🪣  MinIO - Criar Buckets"
echo -e "==================================${NC}"
echo ""

# Configurações
MINIO_ENDPOINT="${MINIO_ENDPOINT:-localhost:9000}"
MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_SECRET_KEY:-minioadmin}"
MINIO_USE_SSL="${MINIO_USE_SSL:-false}"

# Verificar se mc está instalado
if ! command -v mc &> /dev/null; then
    echo -e "${YELLOW}⚠️  MinIO Client (mc) não encontrado. Instalando...${NC}"
    
    # Detectar arquitetura
    ARCH=$(uname -m)
    if [ "$ARCH" == "x86_64" ]; then
        MC_URL="https://dl.min.io/client/mc/release/linux-amd64/mc"
    elif [ "$ARCH" == "aarch64" ]; then
        MC_URL="https://dl.min.io/client/mc/release/linux-arm64/mc"
    else
        echo -e "${RED}❌ Arquitetura não suportada: $ARCH${NC}"
        exit 1
    fi
    
    wget -q $MC_URL -O /tmp/mc
    chmod +x /tmp/mc
    sudo mv /tmp/mc /usr/local/bin/mc
    echo -e "${GREEN}✅ MinIO Client instalado${NC}"
fi

# Configurar alias
echo -e "${BLUE}Configurando conexão com MinIO...${NC}"

PROTOCOL="http"
if [ "$MINIO_USE_SSL" == "true" ]; then
    PROTOCOL="https"
fi

mc alias set myminio ${PROTOCOL}://${MINIO_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY}

# Testar conexão
if ! mc admin info myminio > /dev/null 2>&1; then
    echo -e "${RED}❌ Não foi possível conectar ao MinIO em ${MINIO_ENDPOINT}${NC}"
    echo "Verifique se o MinIO está rodando e as credenciais estão corretas."
    exit 1
fi

echo -e "${GREEN}✅ Conectado ao MinIO${NC}"
echo ""

# Função para criar bucket
create_bucket() {
    local bucket_name=$1
    local versioning=$2
    local quota=$3
    
    echo -e "${BLUE}Criando bucket: ${bucket_name}...${NC}"
    
    # Verificar se bucket já existe
    if mc ls myminio/${bucket_name} > /dev/null 2>&1; then
        echo -e "${YELLOW}  ⚠️  Bucket ${bucket_name} já existe${NC}"
        return
    fi
    
    # Criar bucket
    mc mb myminio/${bucket_name}
    echo -e "${GREEN}  ✅ Bucket criado${NC}"
    
    # Habilitar versionamento (se solicitado)
    if [ "$versioning" == "true" ]; then
        mc version enable myminio/${bucket_name}
        echo -e "${GREEN}  ✅ Versionamento habilitado${NC}"
    fi
    
    # Definir quota (se solicitado)
    if [ -n "$quota" ]; then
        mc admin bucket quota myminio/${bucket_name} --hard ${quota}
        echo -e "${GREEN}  ✅ Quota definida: ${quota}${NC}"
    fi
}

# Criar buckets para os projetos
echo "Criando buckets dos projetos..."
echo ""

# Bucket para api-sgpi (documentos de patentes)
create_bucket "sgpi-files" "true" "100GB"

# Bucket para backups (opcional)
create_bucket "backups" "false" ""

# Bucket para temporários (opcional)
create_bucket "temp" "false" "10GB"

# Listar buckets criados
echo ""
echo -e "${BLUE}Buckets disponíveis:${NC}"
mc ls myminio/

# Informações do servidor
echo ""
echo -e "${BLUE}Informações do servidor:${NC}"
mc admin info myminio

echo ""
echo -e "${GREEN}✅ Buckets criados com sucesso!${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Acesse o console: ${PROTOCOL}://${MINIO_ENDPOINT/:9000/:9001}"
echo "2. Configure políticas de acesso se necessário"
echo "3. Configure lifecycle rules para limpeza automática"
echo ""
echo "Comandos úteis:"
echo "  mc ls myminio/                     # Listar buckets"
echo "  mc ls myminio/sgpi-files/          # Listar objetos"
echo "  mc du myminio/sgpi-files/          # Ver uso de espaço"
echo "  mc admin user list myminio         # Listar usuários"

