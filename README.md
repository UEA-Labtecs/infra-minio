# 🗄️ MinIO - Object Storage Infrastructure

Infraestrutura MinIO (S3-compatible) para os projetos LabTECS.

## 📋 Visão Geral

Este repositório gerencia a infraestrutura do MinIO, que é **compartilhada** entre:
- `api-sgpi` - Armazenamento de documentos de patentes
- `api-jornada-pulmonar` - (se necessário no futuro)
- Outros projetos que precisem de object storage

## 🚀 Quick Start

### Deploy Automático (Recomendado)

```bash
# 1. Configurar secrets no GitHub
gh auth login
gh secret set MINIO_ROOT_USER -b "admin"
gh secret set MINIO_ROOT_PASSWORD -b "$(openssl rand -base64 32)"
gh secret set MINIO_SERVER_URL -b "https://api-minio.labtecs.com.br"
gh secret set MINIO_BROWSER_REDIRECT_URL -b "https://minio.labtecs.com.br"
gh secret set MINIO_REGION_NAME -b "us-east-1"

# 2. Configurar NPM (Nginx Proxy Manager)
#    - api-minio.labtecs.com.br → localhost:9000
#    - minio.labtecs.com.br → localhost:9001

# 3. Fazer push para main
git push origin main

# 4. Acompanhar deploy
# github.com/USER/infra-minio/actions
```

📖 **Guia completo**: [SETUP-GITHUB.md](./SETUP-GITHUB.md)

### Deploy Manual (Local)

```bash
# 1. Clonar repositório
git clone <repo-url>
cd infra-minio

# 2. Configurar variáveis
cp env.template .env
nano .env  # Ajustar credenciais

# 3. Criar rede Docker (se não existir)
docker network create nginx_proxy

# 4. Iniciar MinIO
docker-compose up -d

# 5. Acessar console
open http://localhost:9001
```

## 📁 Estrutura

```
infra-minio/
├── .github/workflows/
│   └── deploy.yaml         # GitHub Actions CI/CD
├── docker-compose.yml      # Configuração do MinIO
├── env.template            # Template de variáveis
├── scripts/
│   ├── backup.sh           # Backup automático
│   ├── restore.sh          # Restore de backup
│   └── create-buckets.sh   # Criar buckets iniciais
├── data/                   # Dados do MinIO (gitignored)
├── backups/                # Backups (gitignored)
├── README.md               # Este arquivo
├── SETUP-GITHUB.md         # Configuração CI/CD
└── QUICK-START.md          # Guia rápido
```

## 🔧 Configuração

### 1. Variáveis de Ambiente

Copie `env.template` para `.env` e ajuste:

```bash
# Credenciais (TROCAR EM PRODUÇÃO!)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=supersecretpassword123

# URLs públicas
MINIO_SERVER_URL=https://api-minio.labtecs.com.br
MINIO_BROWSER_REDIRECT_URL=https://minio.labtecs.com.br
```

### 2. Nginx Proxy Manager (NPM)

O MinIO é exposto via **Nginx Proxy Manager** para gerenciamento fácil de SSL e domínios.

#### Configurar API S3 (porta 9000)

**Proxy Host no NPM:**
- **Domain:** `api-minio.labtecs.com.br`
- **Scheme:** `http`
- **Forward Host:** `localhost` ou IP do servidor
- **Forward Port:** `9000`
- **Websockets:** ✅ Habilitado
- **Block Exploits:** ✅ Habilitado

**SSL:**
- **Certificate:** Let's Encrypt
- **Force SSL:** ✅ Habilitado
- **HTTP/2:** ✅ Habilitado

**Custom Nginx Config (Advanced):**
```nginx
client_max_body_size 500M;
client_body_timeout 300s;
proxy_buffering off;
```

#### Configurar Console Web (porta 9001)

**Proxy Host no NPM:**
- **Domain:** `minio.labtecs.com.br`
- **Scheme:** `http`
- **Forward Host:** `localhost` ou IP do servidor
- **Forward Port:** `9001`
- **Websockets:** ✅ Habilitado (essencial!)
- **Block Exploits:** ✅ Habilitado

**SSL:**
- **Certificate:** Let's Encrypt
- **Force SSL:** ✅ Habilitado
- **HTTP/2:** ✅ Habilitado

**Custom Nginx Config (Advanced):**
```nginx
client_max_body_size 500M;
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

📖 **Guia detalhado**: [SETUP-GITHUB.md](./SETUP-GITHUB.md)

## 🚀 CI/CD com GitHub Actions

O repositório possui deploy automático via GitHub Actions.

### Workflow

```
Push para main → GitHub Actions → Deploy no Servidor
```

### O que o workflow faz:

1. Faz checkout do código
2. Cria arquivo `.env` com os secrets
3. Para o MinIO antigo (se existir)
4. Inicia novo MinIO com `docker-compose`
5. Verifica health check
6. Mostra status do container

### Fazer Deploy:

```bash
# Fazer alteração
git add .
git commit -m "feat: nova configuração"
git push origin main

# Acompanhar: github.com/USER/infra-minio/actions
```

### Deploy Manual (via Actions):

1. Vá em **Actions** → **Deploy MinIO**
2. Clique em **Run workflow**
3. Selecione branch `main`
4. Clique em **Run workflow**

### Secrets Necessários:

- `MINIO_ROOT_USER`
- `MINIO_ROOT_PASSWORD`
- `MINIO_SERVER_URL`
- `MINIO_BROWSER_REDIRECT_URL`
- `MINIO_REGION_NAME`

📖 **Configuração completa**: [SETUP-GITHUB.md](./SETUP-GITHUB.md)

## 🪣 Gerenciar Buckets

### Via Console Web
1. Acesse: https://minio.labtecs.com.br
2. Login com as credenciais do `.env`
3. Vá em "Buckets" → "Create Bucket"

### Via Script
```bash
./scripts/create-buckets.sh
```

### Via MinIO Client (mc)
```bash
# Instalar mc
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Configurar alias
mc alias set myminio http://localhost:9000 minioadmin minioadmin

# Criar bucket
mc mb myminio/sgpi-files

# Listar buckets
mc ls myminio

# Definir política pública (se necessário)
mc anonymous set download myminio/sgpi-files
```

## 💾 Backup e Restore

### Backup Automático

```bash
# Executar backup
./scripts/backup.sh

# Agendar backup diário (crontab)
crontab -e
# Adicionar: 0 2 * * * /path/to/infra-minio/scripts/backup.sh
```

### Backup Manual

```bash
# Backup dos dados
docker-compose down
tar -czf backup-$(date +%Y%m%d).tar.gz data/
docker-compose up -d

# Ou usando mc
mc mirror myminio/sgpi-files ./backups/sgpi-files-$(date +%Y%m%d)
```

### Restore

```bash
./scripts/restore.sh backup-20241030.tar.gz
```

## 📊 Monitoramento

### Health Check
```bash
# Status do container
docker ps | grep minio

# Logs
docker logs -f minio

# Health endpoint
curl http://localhost:9000/minio/health/live
```

### Uso de Disco
```bash
# Espaço usado pelo MinIO
du -sh data/

# Via mc
mc admin info myminio
```

### Métricas
MinIO expõe métricas Prometheus em:
```
http://localhost:9000/minio/v2/metrics/cluster
```

## 🔐 Segurança

### 1. Credenciais Fortes
```bash
# Gerar senha segura
openssl rand -base64 32

# Atualizar no .env
MINIO_ROOT_PASSWORD=<senha-gerada>
```

### 2. Políticas de Acesso

```bash
# Criar usuário read-only
mc admin user add myminio readonly ReadOnlyUser123

# Criar política
cat > readonly-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::sgpi-files/*", "arn:aws:s3:::sgpi-files"]
    }
  ]
}
EOF

mc admin policy add myminio readonly readonly-policy.json
mc admin policy set myminio readonly user=readonly
```

### 3. Firewall
```bash
# Permitir apenas localhost e rede interna
sudo ufw allow from 10.0.0.0/8 to any port 9000
sudo ufw allow from 127.0.0.1 to any port 9000
sudo ufw allow from 10.0.0.0/8 to any port 9001
```

### 4. CORS (se necessário)

Via Console Web ou mc:
```bash
cat > cors.json << 'EOF'
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://app.labtecs.com.br"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
EOF

mc anonymous set-json cors.json myminio/sgpi-files
```

## 🚀 Uso nos Projetos

### Python (FastAPI / api-sgpi)

```python
from minio import Minio

client = Minio(
    "minio:9000",  # Interno
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)

# Upload
client.fput_object(
    "sgpi-files",
    "patents/123/documento.pdf",
    "/path/to/file.pdf"
)

# Download
client.fget_object(
    "sgpi-files",
    "patents/123/documento.pdf",
    "/path/to/download.pdf"
)

# Presigned URL (público)
url = client.presigned_get_object(
    "sgpi-files",
    "patents/123/documento.pdf",
    expires=timedelta(hours=1)
)
```

### Node.js (NestJS / api-jornada-pulmonar)

```typescript
import * as Minio from 'minio';

const minioClient = new Minio.Client({
  endPoint: 'minio',
  port: 9000,
  useSSL: false,
  accessKey: 'minioadmin',
  secretKey: 'minioadmin',
});

// Upload
await minioClient.fPutObject(
  'sgpi-files',
  'path/to/object',
  '/path/to/file'
);

// Presigned URL
const url = await minioClient.presignedGetObject(
  'sgpi-files',
  'path/to/object',
  24 * 60 * 60 // 24 horas
);
```

## 📝 Comandos Úteis

```bash
# Iniciar
docker-compose up -d

# Parar
docker-compose down

# Ver logs
docker-compose logs -f

# Reiniciar
docker-compose restart

# Atualizar imagem
docker-compose pull
docker-compose up -d

# Ver uso de recursos
docker stats minio

# Limpar cache
mc admin config reset myminio cache

# Ver usuários
mc admin user list myminio

# Ver buckets e tamanho
mc du myminio
```

## 🔄 Atualização

```bash
# Backup antes de atualizar
./scripts/backup.sh

# Atualizar
docker-compose pull
docker-compose up -d

# Verificar
docker logs minio
```

## 🐛 Troubleshooting

### Container não inicia
```bash
# Ver logs
docker logs minio

# Verificar permissões do diretório data
sudo chown -R 1000:1000 data/

# Verificar porta em uso
sudo netstat -tlnp | grep 9000
```

### Erro de conexão
```bash
# Testar conectividade
curl http://localhost:9000/minio/health/live

# Verificar rede
docker network inspect nginx_proxy

# Verificar DNS (interno)
docker exec api-sgpi ping -c 3 minio
```

### Espaço em disco
```bash
# Verificar uso
df -h
du -sh data/

# Limpar objetos antigos (cuidado!)
mc rm --recursive --force --older-than 30d myminio/sgpi-files/temp/
```

## 📚 Documentação

- [MinIO Docs](https://min.io/docs/minio/linux/index.html)
- [MinIO Client (mc)](https://min.io/docs/minio/linux/reference/minio-mc.html)
- [Python SDK](https://min.io/docs/minio/linux/developers/python/minio-py.html)
- [Node.js SDK](https://min.io/docs/minio/linux/developers/javascript/minio-javascript.html)

## 🤝 Contribuindo

1. Faça backup antes de mudanças
2. Teste localmente primeiro
3. Documente alterações no README
4. Faça commit com mensagem clara

## 📞 Suporte

**Problemas?**
1. Verifique logs: `docker logs minio`
2. Teste health check: `curl http://localhost:9000/minio/health/live`
3. Consulte documentação oficial

## 🎯 Projetos que Usam

- ✅ **api-sgpi** - Documentos de patentes
- 🔄 **api-jornada-pulmonar** - (planejado)

## 📄 Licença

Propriedade da Universidade do Estado do Amazonas (UEA) - LabTECS

---

**Última atualização**: Outubro 30, 2025  
**Versão MinIO**: latest  
**Maintainer**: LabTECS

