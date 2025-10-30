#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Verificando credenciais do MinIO..."
echo ""

# Verificar container
if ! docker ps --format '{{.Names}}' | grep -qi "^minio$"; then
    echo "❌ Container MinIO não está rodando!"
    exit 1
fi

echo "✅ Container MinIO está rodando"
echo ""

# Credenciais do container (variáveis de ambiente)
echo "📋 Credenciais configuradas no container:"
docker inspect minio --format '{{range .Config.Env}}{{println .}}{{end}}' | grep MINIO_ROOT || echo "  Não encontradas"
echo ""

# Extrair credenciais do container
CONTAINER_USER=$(docker inspect minio --format '{{range .Config.Env}}{{println .}}{{end}}' | grep "^MINIO_ROOT_USER=" | cut -d= -f2 || echo "")
CONTAINER_PASS=$(docker inspect minio --format '{{range .Config.Env}}{{println .}}{{end}}' | grep "^MINIO_ROOT_PASSWORD=" | cut -d= -f2 || echo "")

if [ -n "$CONTAINER_USER" ] && [ -n "$CONTAINER_PASS" ]; then
    echo "👤 User: $CONTAINER_USER"
    echo "🔑 Password: ${CONTAINER_PASS:0:8}... (primeiros 8 caracteres)"
    echo ""
    
    # Verificar se existe arquivo .env
    if [ -f ".env" ]; then
        ENV_USER=$(grep "^MINIO_ROOT_USER=" .env | cut -d= -f2 || echo "")
        ENV_PASS=$(grep "^MINIO_ROOT_PASSWORD=" .env | cut -d= -f2 || echo "")
        
        if [ -n "$ENV_USER" ] && [ -n "$ENV_PASS" ]; then
            echo "📄 Credenciais no arquivo .env:"
            echo "👤 User: $ENV_USER"
            echo "🔑 Password: ${ENV_PASS:0:8}... (primeiros 8 caracteres)"
            echo ""
            
            if [ "$CONTAINER_USER" != "$ENV_USER" ] || [ "$CONTAINER_PASS" != "$ENV_PASS" ]; then
                echo "⚠️  ATENÇÃO: Credenciais do container diferem do .env!"
                echo "   Isso pode causar problemas de login."
            fi
        fi
    else
        echo "⚠️  Arquivo .env não encontrado"
    fi
else
    echo "⚠️  Não foi possível extrair credenciais do container"
fi

echo ""
echo "📂 Verificando dados persistentes..."
if [ -d "data/.minio.sys/config" ]; then
    if [ -f "data/.minio.sys/config/config.json" ]; then
        echo "✅ Arquivo de configuração encontrado"
        # Tentar extrair credenciais do config (requer jq)
        if command -v jq &> /dev/null; then
            STORED_USER=$(jq -r '.credential.accessKey // empty' data/.minio.sys/config/config.json 2>/dev/null || echo "")
            if [ -n "$STORED_USER" ]; then
                echo "   Credencial armazenada: $STORED_USER"
            fi
        else
            echo "   (Instale 'jq' para ver credenciais armazenadas: apt-get install jq)"
        fi
    else
        echo "⚠️  Diretório existe mas arquivo config.json não encontrado"
    fi
else
    echo "⚠️  Diretório de configuração não existe (MinIO pode estar inicializando)"
fi

echo ""
echo "🧪 Testando conexão..."
if curl -sf "http://localhost:9000/minio/health/live" > /dev/null 2>&1; then
    echo "✅ MinIO está respondendo na porta 9000"
else
    echo "❌ MinIO não está respondendo na porta 9000"
fi

echo ""
echo "📝 RESUMO:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Para fazer login, tente usar as credenciais do container:"
if [ -n "$CONTAINER_USER" ] && [ -n "$CONTAINER_PASS" ]; then
    echo "  👤 Usuário: $CONTAINER_USER"
    echo "  🔑 Senha: $CONTAINER_PASS"
    echo ""
    echo "URLs de acesso:"
    echo "  🌐 Console Web (direto): http://localhost:9001"
    echo "  🌐 Console Web (NPM): https://minio.labtecs.com.br"
else
    echo "  ⚠️  Não foi possível determinar credenciais"
fi
echo ""
echo "Se ainda não funcionar, veja: RESET-CREDENTIALS.md"

