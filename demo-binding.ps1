# 🧪 Demo de Diferir Binding - TFU3
# Demostración de cambio de implementación en runtime

Write-Host "🔗 Demo de Diferir Binding - Salto Hotel & Casino" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "🎯 Objetivo: Demostrar cambio de implementación sin recompilación" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------"

Write-Host "📚 Patrón utilizado: Factory Pattern + Configuración Externa" -ForegroundColor Green
Write-Host "🔧 Mecanismo: Variable de entorno BOOKING_MODE" -ForegroundColor Green

Write-Host ""
Write-Host "1️⃣ Estado Inicial - Modo PostgreSQL" -ForegroundColor Yellow
Write-Host "------------------------------------"

# Verificar estado actual
try {
    $currentState = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET
    Write-Host "✅ API conectada" -ForegroundColor Green
    Write-Host "   Versión: $($currentState.version)" -ForegroundColor Gray
    Write-Host "   Modo actual: $($currentState.booking_mode)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ API no disponible. Ejecuta primero: docker-compose up -d" -ForegroundColor Red
    exit 1
}

# Probar endpoint con modo actual
Write-Host ""
Write-Host "📊 Probando endpoint /bookings con implementación actual:" -ForegroundColor Cyan
try {
    $bookings1 = Invoke-RestMethod -Uri "http://localhost:3000/bookings" -Method GET
    Write-Host "✅ Respuesta recibida:" -ForegroundColor Green
    Write-Host "   Fuente de datos: $($bookings1.source)" -ForegroundColor Yellow
    Write-Host "   Total de reservas: $($bookings1.count)" -ForegroundColor Gray
    Write-Host "   Primeras reservas:" -ForegroundColor Gray
    
    if ($bookings1.data -and $bookings1.data.Count -gt 0) {
        $bookings1.data | Select-Object -First 2 | ForEach-Object {
            Write-Host "     - $($_.client_name) - Habitación $($_.room_number)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "❌ Error al obtener reservas: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "2️⃣ Cambio de Binding - Modo Mock" -ForegroundColor Yellow
Write-Host "--------------------------------"

Write-Host "🔧 Modificando configuración externa..." -ForegroundColor Cyan

# Crear/modificar archivo .env
$envContent = "BOOKING_MODE=mock"
$envContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ Archivo .env actualizado: BOOKING_MODE=mock" -ForegroundColor Green

Write-Host ""
Write-Host "🔄 Reiniciando servicio backend para aplicar cambios..." -ForegroundColor Cyan
docker-compose restart backend_v1

# Esperar a que se reinicie
Write-Host "⏳ Esperando reinicio del servicio..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Verificar que el servicio esté funcionando
$retries = 0
$maxRetries = 10
do {
    try {
        $healthCheck = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET -TimeoutSec 5
        break
    } catch {
        $retries++
        if ($retries -ge $maxRetries) {
            Write-Host "❌ Servicio no responde después del reinicio" -ForegroundColor Red
            exit 1
        }
        Write-Host "⏳ Reintentando conexión... ($retries/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
} while ($retries -lt $maxRetries)

Write-Host ""
Write-Host "3️⃣ Verificación del Cambio" -ForegroundColor Yellow
Write-Host "---------------------------"

# Verificar nuevo estado
try {
    $newState = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET
    Write-Host "✅ Servicio reiniciado exitosamente" -ForegroundColor Green
    Write-Host "   Versión: $($newState.version)" -ForegroundColor Gray
    Write-Host "   Modo nuevo: $($newState.booking_mode)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error al verificar nuevo estado" -ForegroundColor Red
}

# Probar endpoint con nueva implementación
Write-Host ""
Write-Host "📊 Probando endpoint /bookings con nueva implementación:" -ForegroundColor Cyan
try {
    $bookings2 = Invoke-RestMethod -Uri "http://localhost:3000/bookings" -Method GET
    Write-Host "✅ Respuesta recibida:" -ForegroundColor Green
    Write-Host "   Fuente de datos: $($bookings2.source)" -ForegroundColor Yellow
    Write-Host "   Total de reservas: $($bookings2.count)" -ForegroundColor Gray
    Write-Host "   Reservas simuladas:" -ForegroundColor Gray
    
    if ($bookings2.data -and $bookings2.data.Count -gt 0) {
        $bookings2.data | Select-Object -First 3 | ForEach-Object {
            Write-Host "     - $($_.client_name) - Habitación $($_.room_number)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "❌ Error al obtener reservas: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "4️⃣ Comparación de Implementaciones" -ForegroundColor Yellow
Write-Host "-----------------------------------"

Write-Host "📋 Diferencias observadas:" -ForegroundColor Cyan
Write-Host "   Modo PostgreSQL:" -ForegroundColor White
Write-Host "     • Fuente: PostgreSQL" -ForegroundColor Gray
Write-Host "     • Datos: Persistentes en base de datos" -ForegroundColor Gray
Write-Host "     • Comportamiento: CRUD real" -ForegroundColor Gray

Write-Host ""
Write-Host "   Modo Mock:" -ForegroundColor White
Write-Host "     • Fuente: Mock Service" -ForegroundColor Gray
Write-Host "     • Datos: Simulados en memoria" -ForegroundColor Gray
Write-Host "     • Comportamiento: Respuestas predefinidas" -ForegroundColor Gray

Write-Host ""
Write-Host "5️⃣ Restauración al Estado Original" -ForegroundColor Yellow
Write-Host "-----------------------------------"

Write-Host "🔄 Volviendo a modo PostgreSQL..." -ForegroundColor Cyan

# Restaurar configuración original
$envContent = "BOOKING_MODE=pg"
$envContent | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ Configuración restaurada: BOOKING_MODE=pg" -ForegroundColor Green

# Reiniciar servicio
docker-compose restart backend_v1

Write-Host "⏳ Esperando reinicio..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Verificar restauración
try {
    $restoredState = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET
    Write-Host "✅ Sistema restaurado" -ForegroundColor Green
    Write-Host "   Modo: $($restoredState.booking_mode)" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️  Advertencia: Verificar estado manualmente" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 DEMO DE DIFERIR BINDING COMPLETADA! 🎉" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Conceptos Demostrados:" -ForegroundColor Cyan
Write-Host "✅ Factory Pattern para abstracción de implementación" -ForegroundColor White
Write-Host "✅ Configuración externa mediante variables de entorno" -ForegroundColor White
Write-Host "✅ Cambio de comportamiento sin recompilación" -ForegroundColor White
Write-Host "✅ Inyección de dependencias en runtime" -ForegroundColor White

Write-Host ""
Write-Host "🏗️ Beneficios Arquitectónicos:" -ForegroundColor Cyan
Write-Host "• Flexibilidad de implementación" -ForegroundColor White
Write-Host "• Facilidad de testing (mock vs real)" -ForegroundColor White
Write-Host "• Despliegue sin downtime" -ForegroundColor White
Write-Host "• Configuración por ambiente" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Archivos involucrados:" -ForegroundColor Cyan
Write-Host "• backend/services/bookingServiceFactory.js - Factory Pattern" -ForegroundColor Gray
Write-Host "• backend/services/bookingService.pg.js - Implementación PostgreSQL" -ForegroundColor Gray
Write-Host "• backend/services/bookingService.mock.js - Implementación Mock" -ForegroundColor Gray
Write-Host "• .env - Configuración externa" -ForegroundColor Gray

Write-Host ""
Write-Host "🎓 TFU3 - Análisis y Diseño de Aplicaciones II - 2025" -ForegroundColor Magenta