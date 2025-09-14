#!/bin/bash

# 🚀 Script de despliegue - TFU2: Hotel & Casino API
# Demuestra "Diferir Binding" y "Facilidad de Despliegue"

echo "🏨 === DEPLOY SCRIPT - TFU2 Análisis y Diseño de Aplicaciones II ==="
echo "� Desplegando Salto Hotel & Casino API..."

# Función para logging con timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Función para manejo de errores
error_exit() {
    log "❌ ERROR: $1"
    exit 1
}

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    log "📝 Creando archivo .env con configuración por defecto..."
    cat > .env << EOF
# TFU2 - Configuración de Base de Datos
DB_HOST=db
DB_USER=hoteluser
DB_PASSWORD=casino123
DB_DATABASE=hotel_casino
DB_PORT=5432

# TFU2 - Configuración de Aplicación
NODE_ENV=production
BOOKING_MODE=pg
EOF
fi

# Verificar Docker
log "🔍 Verificando Docker y Docker Compose..."
if ! command -v docker &> /dev/null; then
    error_exit "Docker no está instalado"
fi

if ! command -v docker-compose &> /dev/null; then
    error_exit "Docker Compose no está instalado"
fi

# Limpiar contenedores existentes
log "🧹 Limpiando contenedores existentes..."
docker-compose down --remove-orphans

# PASO 1: Iniciar base de datos
log "🗄️  PASO 1: Iniciando base de datos PostgreSQL..."
docker-compose up -d db

# PASO 2: Esperar que la DB esté lista
log "⏳ PASO 2: Esperando que la base de datos esté lista..."
timeout=60
counter=0
until docker-compose exec -T db pg_isready -U hoteluser -d hotel_casino > /dev/null 2>&1; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge $timeout ]; then
        error_exit "Timeout esperando la base de datos"
    fi
    echo -n "."
done
echo ""
log "✅ Base de datos lista!"

# PASO 3: Iniciar backend_v1 (versión estable)
log "🚀 PASO 3: Desplegando backend_v1 (versión estable)..."
docker-compose up -d backend_v1

# PASO 4: Verificar que backend_v1 responda
log "🔍 PASO 4: Verificando que backend_v1 responda..."
sleep 10
counter=0
until curl -f http://localhost:3000 > /dev/null 2>&1; do
    sleep 2
    counter=$((counter + 2))
    if [ $counter -ge 30 ]; then
        error_exit "backend_v1 no responde en http://localhost:3000"
    fi
    echo -n "."
done
echo ""

log "✅ backend_v1 desplegado exitosamente!"

echo ""
echo "🎉 === DESPLIEGUE COMPLETADO EXITOSAMENTE ==="
echo "📊 Información del despliegue:"
echo "   🌐 API v1 (estable): http://localhost:3000"
echo "   🗄️  Base de datos: localhost:5432"
echo "   🔗 Modo de binding: $(cat .env | grep BOOKING_MODE | cut -d'=' -f2)"
echo ""
echo "📋 Comandos útiles:"
echo "   🔍 Probar API:          curl http://localhost:3000"
echo "   📝 Ver reservas:        curl http://localhost:3000/bookings"
echo "   🚀 Desplegar v2:        ./deploy.sh && ./deploy-v2.sh"
echo "   📊 Ver logs:            docker-compose logs -f backend_v1"
echo "   🔄 Cambiar a mock:      Editar .env → BOOKING_MODE=mock"

log "🏁 Deploy script completado - Sistema listo!"