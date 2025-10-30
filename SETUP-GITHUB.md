# 🔧 Configuração do GitHub Actions

Guia para configurar o deploy automático do MinIO via GitHub Actions.

## 📋 Pré-requisitos

1. Self-hosted runner configurado no servidor
2. Docker e Docker Compose instalados
3. Rede Docker `nginx_proxy` criada
4. Nginx Proxy Manager (NPM) configurado

## 🔐 Secrets Necessários

Vá em **Settings** → **Secrets and variables** → **Actions** → **Secrets**

### Secrets Obrigatórios:

| Nome do Secret | Descrição | Exemplo |
|----------------|-----------|---------|
| `MINIO_ROOT_USER` | Usuário admin do MinIO | `admin` ou `minioadmin` |
| `MINIO_ROOT_PASSWORD` | Senha admin do MinIO | `SuperSecretPassword123!` |
| `MINIO_SERVER_URL` | URL pública da API S3 | `https://api-minio.labtecs.com.br` |
| `MINIO_BROWSER_REDIRECT_URL` | URL pública do Console | `https://minio.labtecs.com.br` |
| `MINIO_REGION_NAME` | Região do MinIO | `us-east-1` |

### Configurar via GitHub CLI:

```bash
# Login
gh auth login

# Configurar secrets
gh secret set MINIO_ROOT_USER -b "admin"
gh secret set MINIO_ROOT_PASSWORD -b "$(openssl rand -base64 32)"
gh secret set MINIO_SERVER_URL -b "https://api-minio.labtecs.com.br"
gh secret set MINIO_BROWSER_REDIRECT_URL -b "https://minio.labtecs.com.br"
gh secret set MINIO_REGION_NAME -b "us-east-1"

# Verificar
gh secret list
```

### Configurar via Interface Web:

1. Acesse: `https://github.com/USER/infra-minio/settings/secrets/actions`
2. Clique em "New repository secret"
3. Adicione cada secret acima
4. Clique em "Add secret"

## 🏃 Self-Hosted Runner

O runner já deve estar configurado no servidor (mesmo usado pelas APIs).

### Verificar Runner:

```bash
# No servidor
sudo systemctl status actions.runner.*.service
```

Se não estiver configurado, siga: `api-sgpi/SETUP-SELF-HOSTED-RUNNER.md`

## 🌐 Configurar Nginx Proxy Manager (NPM)

### 1. API S3 (porta 9000)

**Proxy Host:**
- **Domain Names:** `api-minio.labtecs.com.br`
- **Scheme:** `http`
- **Forward Hostname/IP:** `localhost` ou IP do servidor
- **Forward Port:** `9000`
- **Cache Assets:** ❌ Desabilitado
- **Block Common Exploits:** ✅ Habilitado
- **Websockets Support:** ✅ Habilitado

**SSL:**
- **SSL Certificate:** Let's Encrypt ou Custom
- **Force SSL:** ✅ Habilitado
- **HTTP/2 Support:** ✅ Habilitado
- **HSTS Enabled:** ✅ Habilitado

**Advanced:**
```nginx
# Aumentar limite de upload
client_max_body_size 500M;
client_body_timeout 300s;

# Headers adicionais
proxy_set_header X-Forwarded-Host $server_name;
proxy_buffering off;
proxy_request_buffering off;
```

### 2. Console Web (porta 9001)

**Proxy Host:**
- **Domain Names:** `minio.labtecs.com.br`
- **Scheme:** `http`
- **Forward Hostname/IP:** `localhost` ou IP do servidor
- **Forward Port:** `9001`
- **Cache Assets:** ❌ Desabilitado
- **Block Common Exploits:** ✅ Habilitado
- **Websockets Support:** ✅ Habilitado (essencial!)

**SSL:**
- **SSL Certificate:** Let's Encrypt ou Custom
- **Force SSL:** ✅ Habilitado
- **HTTP/2 Support:** ✅ Habilitado
- **HSTS Enabled:** ✅ Habilitado

**Advanced:**
```nginx
client_max_body_size 500M;
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## 🚀 Como Funciona o Deploy

### Workflow Automático:

```
Push para main → GitHub Actions → Deploy no Servidor
```

**O workflow:**
1. Faz checkout do código
2. Cria arquivo `.env` com os secrets
3. Para o MinIO antigo (se existir)
4. Inicia novo MinIO
5. Verifica saúde
6. Mostra status

### Fazer Deploy:

```bash
# Fazer alteração
git add .
git commit -m "feat: atualizar configuração"
git push origin main

# Acompanhar em: github.com/USER/infra-minio/actions
```

### Deploy Manual (se necessário):

Via GitHub:
- Vá em **Actions** → **Deploy MinIO** → **Run workflow**

Via servidor:
```bash
cd /path/to/infra-minio
docker-compose down
docker-compose up -d
```

## 📊 Monitoramento

### Verificar Status:

```bash
# Container rodando?
docker ps | grep minio

# Logs
docker logs -f minio

# Health check
curl http://localhost:9000/minio/health/live
```

### Acessar Console:

**Local:**
- Console: http://localhost:9001
- API: http://localhost:9000

**Produção (via NPM):**
- Console: https://minio.labtecs.com.br
- API: https://api-minio.labtecs.com.br

## 🔒 Segurança

### Credenciais Fortes:

```bash
# Gerar senha forte
openssl rand -base64 32

# Atualizar secret
gh secret set MINIO_ROOT_PASSWORD -b "$(openssl rand -base64 32)"
```

### Firewall:

```bash
# Permitir apenas localhost (NPM faz o proxy)
sudo ufw allow from 127.0.0.1 to any port 9000
sudo ufw allow from 127.0.0.1 to any port 9001
```

### Portas Expostas:

- ✅ Apenas `127.0.0.1` (localhost)
- ✅ Acesso externo via NPM com SSL
- ✅ Certificados Let's Encrypt

## 🪣 Criar Buckets

### Via Console Web:

1. Acesse: https://minio.labtecs.com.br
2. Login com credenciais
3. **Buckets** → **Create Bucket**

### Via Script:

```bash
./scripts/create-buckets.sh
```

### Via MinIO Client (mc):

```bash
# Configurar
mc alias set myminio https://api-minio.labtecs.com.br admin <password>

# Criar bucket
mc mb myminio/sgpi-files

# Listar
mc ls myminio
```

## 🐛 Troubleshooting

### Container não inicia:

```bash
# Ver logs
docker logs minio

# Verificar permissões
sudo chown -R 1000:1000 data/

# Verificar rede
docker network inspect nginx_proxy
```

### Não consegue acessar via NPM:

```bash
# Testar localmente
curl http://localhost:9000/minio/health/live
curl http://localhost:9001

# Verificar NPM
docker logs nginx-proxy-manager
```

### Erro de SSL:

- Verificar certificado no NPM
- Verificar se as URLs no `.env` correspondem aos domínios
- Tentar desabilitar Force SSL temporariamente para testar

## 📝 Notas Importantes

1. **Rede Docker**: O container deve estar na rede `nginx_proxy`
2. **Portas**: Expostas apenas para localhost
3. **SSL**: Gerenciado pelo NPM, não pelo MinIO
4. **Backup**: Configure backups regulares (ver README.md)
5. **Monitoramento**: Verifique logs regularmente

## ✅ Checklist de Configuração

- [ ] Self-hosted runner rodando
- [ ] Secrets configurados no GitHub
- [ ] Rede `nginx_proxy` criada
- [ ] NPM configurado para ambos os domínios
- [ ] Certificados SSL ativos
- [ ] Primeiro deploy realizado
- [ ] Buckets criados
- [ ] Teste de upload funcionando
- [ ] Backup configurado

## 🎯 Próximos Passos

Após configuração:

1. ✅ Fazer push para `main` para testar deploy
2. ✅ Acessar console e criar buckets
3. ✅ Configurar backup automático
4. ✅ Atualizar secrets nas APIs (`api-sgpi`, etc.)

## 📚 Referências

- [README.md](./README.md) - Documentação completa
- [MinIO Docs](https://min.io/docs/)
- [NPM Docs](https://nginxproxymanager.com/guide/)

---

**Última atualização**: Outubro 30, 2025  
**CI/CD**: GitHub Actions com self-hosted runner  
**Proxy**: Nginx Proxy Manager

