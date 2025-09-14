#!/bin/bash

# � Script de despliegue de versión 2 - TFU2
# Demuestra táctica de "Rollback" con despliegue blue-green

echo "🔄 === DEPLOY V2 SCRIPT - TFU2 ==="
echo "� Desplegando versión 2 de Hotel & Casino API..."

# Función para logging con timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "❌ ERROR: $1"
    exit 1
}

# PASO 1: Verificar que v1 esté funcionando
log "🔍 PASO 1: Verificando que backend_v1 esté activo..."
if ! curl -f http://localhost:3000 > /dev/null 2>&1; then
    error_exit "backend_v1 no está funcionando en localhost:3000. Ejecuta ./deploy.sh primero"
fi
log "✅ backend_v1 funcionando correctamente"

# PASO 2: Desplegar backend_v2 (blue-green deployment)
log "🏗️  PASO 2: Desplegando backend_v2 (nueva versión)..."
docker-compose --profile v2 up -d backend_v2

# PASO 3: Esperar que v2 esté lista
log "⏳ PASO 3: Esperando que backend_v2 esté lista en localhost:3001..."
sleep 15
counter=0
until curl -f http://localhost:3001 > /dev/null 2>&1; do
    sleep 3
    counter=$((counter + 3))
    if [ $counter -ge 45 ]; then
        log "⚠️  backend_v2 no responde, manteniendo v1 activa"
        docker-compose stop backend_v2
        error_exit "Timeout esperando backend_v2"
    fi
    echo -n "."
done
echo ""
log "✅ backend_v2 está respondiendo!"

# PASO 4: Verificar que ambas versiones funcionen
log "🔍 PASO 4: Verificando respuestas de ambas versiones..."

v1_response=$(curl -s http://localhost:3000 | grep -o '"version":"[^"]*"' || echo "")
v2_response=$(curl -s http://localhost:3001 | grep -o '"version":"[^"]*"' || echo "")

if [[ $v1_response == *"1.0.0"* ]] && [[ $v2_response == *"2.0.0"* ]]; then
    log "✅ Ambas versiones funcionando correctamente"
else
    log "⚠️  Error en las versiones. Limpiando v2..."
    docker-compose stop backend_v2
    error_exit "Las versiones no responden correctamente"
fi

echo ""
echo "🎉 === DESPLIEGUE V2 COMPLETADO EXITOSAMENTE ==="
echo ""
echo "� Estado actual del sistema:"
echo "   🟢 v1 (estable) → http://localhost:3000"
echo "   🆕 v2 (nueva) → http://localhost:3001"  
echo "   🗄️  Base de datos compartida → localhost:5432"
echo ""
echo "🧪 Comandos de testing:"
echo "   📝 Test v1: curl http://localhost:3000/bookings"
echo "   📝 Test v2: curl http://localhost:3001/bookings"
echo "   🔄 Rollback: ./rollback.sh"
echo ""
echo "⚠️  Si hay problemas con v2, ejecuta: ./rollback.sh"

log "🏁 Deploy v2 completado - Ambas versiones activas!"