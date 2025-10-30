# ⚡ Quick Start - MinIO Infrastructure

Guia rápido para deploy do MinIO com GitHub Actions.

## 🚀 Setup em 3 Passos

### 1. Configurar Secrets (2 min)

```bash
gh auth login
gh secret set MINIO_ROOT_USER -b "admin"
gh secret set MINIO_ROOT_PASSWORD -b "$(openssl rand -base64 32)"
gh secret set MINIO_SERVER_URL -b "https://api-minio.labtecs.com.br"
gh secret set MINIO_BROWSER_REDIRECT_URL -b "https://minio.labtecs.com.br"
gh secret set MINIO_REGION_NAME -b "us-east-1"
```

### 2. Configurar NPM (5 min)

**API S3** (`api-minio.labtecs.com.br`):
- Forward: `localhost:9000`
- SSL: Let's Encrypt
- WebSockets: ✅

**Console** (`minio.labtecs.com.br`):
- Forward: `localhost:9001`
- SSL: Let's Encrypt
- WebSockets: ✅

### 3. Fazer Deploy (1 min)

```bash
git push origin main
```

Acompanhe em: `github.com/USER/infra-minio/actions`

---

## 🎯 Após Deploy

### Acessar Console:

```
https://minio.labtecs.com.br
```

Login com as credenciais configuradas nos secrets.

### Criar Buckets:

Via script:
```bash
./scripts/create-buckets.sh
```

Ou via console web (GUI).

### Configurar Backup:

```bash
# Backup manual
./scripts/backup.sh

# Backup automático (cron)
crontab -e
# Adicionar: 0 2 * * * /path/to/infra-minio/scripts/backup.sh
```

---

## 📊 Comandos Úteis

```bash
# Status
docker ps | grep minio

# Logs
docker logs -f minio

# Health check
curl http://localhost:9000/minio/health/live

# Reiniciar
docker-compose restart

# Parar
docker-compose down

# Iniciar
docker-compose up -d
```

---

## 🔧 Configurar nas APIs

Após o MinIO estar rodando, configure nas APIs:

### api-sgpi

Secrets já configurados (compartilhados):
- ✅ `MINIO_ACCESS_KEY` → Mesmo que `MINIO_ROOT_USER`
- ✅ `MINIO_SECRET_KEY` → Mesmo que `MINIO_ROOT_PASSWORD`
- ✅ `MINIO_ENDPOINT` → `minio:9000` (interno)
- ✅ `MINIO_PUBLIC_ENDPOINT` → `api-minio.labtecs.com.br`

Teste de conexão:
```python
from minio import Minio

client = Minio(
    "minio:9000",
    access_key="admin",
    secret_key="your-password",
    secure=False
)

# Testar
client.list_buckets()
```

---

## 🐛 Troubleshooting

### Container não inicia:
```bash
docker logs minio
sudo chown -R 1000:1000 data/
```

### Não acessa via browser:
```bash
# Testar local
curl http://localhost:9001

# Verificar NPM
docker logs nginx-proxy-manager
```

### Erro de permissão:
```bash
sudo chown -R 1000:1000 data/
docker-compose restart
```

---

## 📚 Documentação Completa

- [README.md](./README.md) - Documentação técnica
- [SETUP-GITHUB.md](./SETUP-GITHUB.md) - CI/CD e secrets

---

**Tempo total de setup**: ~10 minutos  
**Deploy automático**: ✅ Via GitHub Actions  
**Acesso**: Via Nginx Proxy Manager

