#!/bin/bash
set -e

# Script de backup do MinIO

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "🗄️  MinIO Backup"
echo -e "==================================${NC}"
echo ""

# Configurações
BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="minio-backup-${TIMESTAMP}"
RETENTION_DAYS=${RETENTION_DAYS:-7}

# Criar diretório de backup se não existir
mkdir -p "${BACKUP_DIR}"

echo -e "${BLUE}📦 Criando backup...${NC}"

# Método 1: Backup dos dados (mais simples, requer parar o container)
if [ "${BACKUP_METHOD:-data}" == "data" ]; then
    echo "Método: Backup dos dados"
    
    # Parar container
    echo "Parando container..."
    docker-compose down
    
    # Criar backup
    echo "Compactando dados..."
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" data/
    
    # Iniciar container
    echo "Reiniciando container..."
    docker-compose up -d
    
    echo -e "${GREEN}✅ Backup criado: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
fi

# Método 2: Backup usando mc (não requer parar)
if [ "${BACKUP_METHOD}" == "mc" ]; then
    echo "Método: MinIO Client (mc)"
    
    # Verificar se mc está instalado
    if ! command -v mc &> /dev/null; then
        echo -e "${RED}❌ MinIO Client (mc) não está instalado!${NC}"
        echo "Instale com: wget https://dl.min.io/client/mc/release/linux-amd64/mc"
        exit 1
    fi
    
    # Configurar alias (se não existir)
    mc alias set local http://localhost:9000 minioadmin minioadmin 2>/dev/null || true
    
    # Criar diretório de backup
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
    mkdir -p "${BACKUP_PATH}"
    
    # Backup de cada bucket
    echo "Fazendo backup dos buckets..."
    for bucket in $(mc ls local/ | awk '{print $NF}' | tr -d '/'); do
        echo "  → Bucket: ${bucket}"
        mc mirror local/${bucket} "${BACKUP_PATH}/${bucket}"
    done
    
    # Compactar
    echo "Compactando backup..."
    tar -czf "${BACKUP_PATH}.tar.gz" -C "${BACKUP_DIR}" "${BACKUP_NAME}"
    rm -rf "${BACKUP_PATH}"
    
    echo -e "${GREEN}✅ Backup criado: ${BACKUP_PATH}.tar.gz${NC}"
fi

# Tamanho do backup
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}📊 Tamanho: ${BACKUP_SIZE}${NC}"

# Limpar backups antigos
echo ""
echo -e "${YELLOW}🧹 Limpando backups antigos (>${RETENTION_DAYS} dias)...${NC}"
find "${BACKUP_DIR}" -name "minio-backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
echo -e "${GREEN}✅ Limpeza concluída${NC}"

# Listar backups
echo ""
echo "Backups disponíveis:"
ls -lh "${BACKUP_DIR}"/minio-backup-*.tar.gz 2>/dev/null || echo "Nenhum backup encontrado"

echo ""
echo -e "${GREEN}✅ Backup concluído com sucesso!${NC}"

