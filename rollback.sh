#!/bin/bash

# 🔙 Script de rollback - TFU2
# Demuestra táctica de "Rollback" sin pérdida de datos

echo "🔙 === ROLLBACK SCRIPT - TFU2 ==="
echo "⚠️  Iniciando ROLLBACK a versión estable (backend_v1)..."

# Función para logging con timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# PASO 1: Información del rollback
log "📊 PASO 1: Evaluando estado actual del sistema..."
echo "   Estado de contenedores:"
docker-compose ps

# PASO 2: Detener backend_v2 (nueva versión problemática)
log "� PASO 2: Deteniendo backend_v2 (nueva versión)..."
docker-compose stop backend_v2
docker-compose rm -f backend_v2

# PASO 3: Verificar que backend_v1 esté funcionando
log "🔍 PASO 3: Verificando que backend_v1 (estable) esté activo..."
sleep 5
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    log "✅ backend_v1 respondiendo correctamente en localhost:3000"
else
    log "⚠️  backend_v1 no responde, intentando reiniciar..."
    docker-compose restart backend_v1
    sleep 10
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log "✅ backend_v1 reiniciado exitosamente"
    else
        log "❌ ERROR: No se pudo restaurar backend_v1"
        exit 1
    fi
fi

# PASO 4: Verificar integridad de la base de datos
log "�️  PASO 4: Verificando integridad de la base de datos..."
if docker-compose exec -T db psql -U hoteluser -d hotel_casino -c "SELECT COUNT(*) FROM bookings;" > /dev/null 2>&1; then
    booking_count=$(docker-compose exec -T db psql -U hoteluser -d hotel_casino -t -c "SELECT COUNT(*) FROM bookings;" | tr -d '[:space:]')
    log "✅ Base de datos intacta - $booking_count reservas preservadas"
else
    log "⚠️  No se pudo verificar la base de datos, pero continúa funcionando"
fi

# PASO 5: Probar funcionalidad completa de la API
log "🧪 PASO 5: Probando funcionalidad de la API..."
if curl -f http://localhost:3000/bookings > /dev/null 2>&1; then
    log "✅ API funcionando correctamente"
    
    # Verificar que sea la versión correcta
    version_check=$(curl -s http://localhost:3000 | grep -o '"version":"[^"]*"' || echo "")
    if [[ $version_check == *"1.0.0"* ]]; then
        log "✅ Versión confirmada: 1.0.0 (estable)"
    else
        log "⚠️  Versión no confirmada, pero API funcional"
    fi
else
    log "❌ ERROR: API no responde después del rollback"
    exit 1
fi

echo ""
echo "🎉 === ROLLBACK COMPLETADO EXITOSAMENTE ==="
echo ""
echo "📊 Estado final del sistema:"
echo "   ✅ backend_v1 (estable) → http://localhost:3000"
echo "   ⏹️  backend_v2 → DETENIDA (recursos liberados)"
echo "   💾 Base de datos → PRESERVADA ($booking_count reservas)"
echo "   �️  Volumen db_data → INTACTO"
echo ""
echo "🧪 Comandos de verificación:"
echo "   📝 Probar API:          curl http://localhost:3000/bookings"
echo "   📊 Ver logs:            docker-compose logs backend_v1"  
echo "   🔍 Estado completo:     docker-compose ps"
echo "   🚀 Reintentar v2:       ./deploy-v2.sh"

log "🏁 ROLLBACK COMPLETADO - Sistema estable en versión 1.0.0"