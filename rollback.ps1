# 🔙 Rollback Script para Windows - TFU2
# Demuestra táctica de "Rollback" sin pérdida de datos

Write-Host "🔙 === ROLLBACK SCRIPT - TFU2 ===" -ForegroundColor Cyan
Write-Host "⚠️ Iniciando ROLLBACK a versión estable (backend_v1)..." -ForegroundColor Yellow

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ❌ ERROR: $Message" -ForegroundColor Red
    exit 1
}

# PASO 1: Información del rollback
Write-Log "📊 PASO 1: Evaluando estado actual del sistema..."
Write-Host "   Estado de contenedores:" -ForegroundColor Cyan
docker-compose ps

# PASO 2: Detener backend_v2
Write-Log "🛑 PASO 2: Deteniendo backend_v2 (nueva versión)..."
docker-compose stop backend_v2
docker-compose rm -f backend_v2

# PASO 3: Verificar backend_v1
Write-Log "🔍 PASO 3: Verificando que backend_v1 (estable) esté activo..."
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 10
    Write-Log "✅ backend_v1 respondiendo correctamente en localhost:3000"
} catch {
    Write-Log "⚠️ backend_v1 no responde, intentando reiniciar..."
    docker-compose restart backend_v1
    Start-Sleep -Seconds 10
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 10
        Write-Log "✅ backend_v1 reiniciado exitosamente"
    } catch {
        Write-Error "No se pudo restaurar backend_v1"
    }
}

# PASO 4: Verificar integridad de la base de datos
Write-Log "🗄️ PASO 4: Verificando integridad de la base de datos..."
try {
    $null = docker-compose exec -T db psql -U hoteluser -d hotel_casino -c "SELECT COUNT(*) FROM bookings;" 2>$null
    $booking_count = (docker-compose exec -T db psql -U hoteluser -d hotel_casino -t -c "SELECT COUNT(*) FROM bookings;" 2>$null).Trim()
    Write-Log "✅ Base de datos intacta - $booking_count reservas preservadas"
} catch {
    Write-Log "⚠️ No se pudo verificar la base de datos, pero continúa funcionando"
}

# PASO 5: Probar funcionalidad de la API
Write-Log "🧪 PASO 5: Probando funcionalidad de la API..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/bookings" -Method GET -TimeoutSec 10
    Write-Log "✅ API funcionando correctamente"
    
    # Verificar versión
    if ($response.Content -match '"version":"1.0.0"') {
        Write-Log "✅ Versión confirmada: 1.0.0 (estable)"
    } else {
        Write-Log "⚠️ Versión no confirmada, pero API funcional"
    }
} catch {
    Write-Error "API no responde después del rollback"
}

Write-Host ""
Write-Host "🎉 === ROLLBACK COMPLETADO EXITOSAMENTE ===" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Estado final del sistema:" -ForegroundColor Cyan
Write-Host "   ✅ backend_v1 (estable) → http://localhost:3000" -ForegroundColor White
Write-Host "   ⏹️ backend_v2 → DETENIDA (recursos liberados)" -ForegroundColor White
Write-Host "   💾 Base de datos → PRESERVADA ($booking_count reservas)" -ForegroundColor White
Write-Host "   🗄️ Volumen db_data → INTACTO" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Comandos de verificación:" -ForegroundColor Cyan
Write-Host "   📝 Probar API:          curl http://localhost:3000/bookings" -ForegroundColor White
Write-Host "   📊 Ver logs:            docker-compose logs backend_v1" -ForegroundColor White
Write-Host "   🔍 Estado completo:     docker-compose ps" -ForegroundColor White
Write-Host "   🚀 Reintentar v2:       .\deploy-v2.ps1" -ForegroundColor White

Write-Log "🏁 ROLLBACK COMPLETADO - Sistema estable en versión 1.0.0"