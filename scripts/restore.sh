#!/bin/bash
set -e

# Script de restore do MinIO

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "🔄 MinIO Restore"
echo -e "==================================${NC}"
echo ""

# Verificar argumento
if [ -z "$1" ]; then
    echo -e "${RED}❌ Uso: $0 <arquivo-backup.tar.gz>${NC}"
    echo ""
    echo "Backups disponíveis:"
    ls -lh ./backups/minio-backup-*.tar.gz 2>/dev/null || echo "Nenhum backup encontrado"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar se arquivo existe
if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}❌ Arquivo não encontrado: ${BACKUP_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  ATENÇÃO: Esta operação irá substituir os dados atuais!${NC}"
echo "Backup: ${BACKUP_FILE}"
echo ""
read -p "Tem certeza que deseja continuar? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# Parar container
echo ""
echo -e "${BLUE}Parando container...${NC}"
docker-compose down

# Backup dos dados atuais
echo -e "${BLUE}Fazendo backup dos dados atuais...${NC}"
if [ -d "data" ]; then
    SAFETY_BACKUP="data-backup-$(date +%Y%m%d_%H%M%S)"
    mv data "${SAFETY_BACKUP}"
    echo -e "${GREEN}✅ Backup de segurança criado: ${SAFETY_BACKUP}${NC}"
fi

# Extrair backup
echo -e "${BLUE}Extraindo backup...${NC}"
tar -xzf "${BACKUP_FILE}"

# Se o backup contém apenas o diretório data
if [ ! -d "data" ] && [ -d "data-backup"* ]; then
    echo -e "${YELLOW}Ajustando estrutura...${NC}"
    mv data-backup* data/ 2>/dev/null || true
fi

# Iniciar container
echo -e "${BLUE}Iniciando container...${NC}"
docker-compose up -d

# Aguardar inicialização
echo "Aguardando MinIO inicializar..."
sleep 10

# Verificar saúde
echo -e "${BLUE}Verificando saúde...${NC}"
if curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MinIO está respondendo${NC}"
else
    echo -e "${RED}❌ MinIO não está respondendo${NC}"
    echo "Verifique os logs: docker logs minio"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Restore concluído com sucesso!${NC}"
echo ""
echo -e "${YELLOW}Nota: O backup de segurança está em: ${SAFETY_BACKUP}${NC}"
echo -e "${YELLOW}Remova-o manualmente quando confirmar que tudo está OK.${NC}"

