# Script de demostración del patrón Circuit Breaker
# Demuestra cómo el circuit breaker protege el sistema de fallos en cascada

Write-Host "🔧 Demostración del patrón Circuit Breaker" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$API_URL = "http://localhost:3000"
$PAYMENT_ENDPOINT = "$API_URL/payments"
$STATUS_ENDPOINT = "$API_URL/payments/circuit-status"
$RESET_ENDPOINT = "$API_URL/payments/circuit-reset"

Write-Host "📊 Paso 1: Verificar estado inicial del Circuit Breaker" -ForegroundColor Yellow
Write-Host "--------------------------------------------------------" -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri $STATUS_ENDPOINT -Method Get
    $status | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "Estado inicial: El circuito debe estar CLOSED (funcionamiento normal)" -ForegroundColor Green
} catch {
    Write-Host "Error: No se pudo conectar al servidor. Asegúrate de que esté ejecutándose." -ForegroundColor Red
    Write-Host "Ejecuta: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host ""
Read-Host "Presiona Enter para continuar"
Write-Host ""

Write-Host "✅ Paso 2: Enviar peticiones de pago (algunas fallarán aleatoriamente)" -ForegroundColor Yellow
Write-Host "-----------------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Enviando 15 peticiones de pago..." -ForegroundColor Cyan
Write-Host ""

for ($i = 1; $i -le 15; $i++) {
    Write-Host "Petición #$i:" -ForegroundColor White
    
    $body = @{
        reservation_id = $i
        amount = 100
        payment_method = "credit_card"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $PAYMENT_ENDPOINT -Method Post -Body $body -ContentType "application/json"
        
        $status = if ($response.data.status) { $response.data.status } else { $response.success }
        $message = if ($response.message) { $response.message } else { $response.error }
        
        if ($response.data.queued) {
            Write-Host "  Estado: $status - ENCOLADO (Circuito OPEN)" -ForegroundColor Yellow
        } elseif ($status -eq "approved" -or $response.success -eq $true) {
            Write-Host "  Estado: $status - $message" -ForegroundColor Green
        } else {
            Write-Host "  Estado: $status - $message" -ForegroundColor Red
        }
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "📊 Paso 3: Verificar estado del Circuit Breaker después de los fallos" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------------" -ForegroundColor Yellow
$status = Invoke-RestMethod -Uri $STATUS_ENDPOINT -Method Get
$status | ConvertTo-Json -Depth 10

$circuitState = $status.data.state
Write-Host ""
Write-Host "Estado actual del circuito: $circuitState" -ForegroundColor $(if ($circuitState -eq "CLOSED") { "Green" } elseif ($circuitState -eq "OPEN") { "Red" } else { "Yellow" })
Write-Host "Si hubo suficientes fallos (>50% en 10s), el circuito debería estar OPEN" -ForegroundColor Cyan
Write-Host ""
Read-Host "Presiona Enter para continuar"
Write-Host ""

Write-Host "🚫 Paso 4: Intentar enviar más pagos con el circuito ABIERTO" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Estas peticiones deberían usar el fallback (encolar pagos)" -ForegroundColor Cyan
Write-Host ""

for ($i = 16; $i -le 20; $i++) {
    Write-Host "Petición #$i:" -ForegroundColor White
    
    $body = @{
        reservation_id = $i
        amount = 100
        payment_method = "credit_card"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $PAYMENT_ENDPOINT -Method Post -Body $body -ContentType "application/json"
        
        $status = if ($response.data.status) { $response.data.status } else { $response.success }
        $queued = if ($response.data.queued) { $response.data.queued } else { $false }
        $message = if ($response.message) { $response.message } else { if ($response.warning) { $response.warning } else { $response.error } }
        
        Write-Host "  Estado: $status - Encolado: $queued" -ForegroundColor $(if ($queued) { "Yellow" } else { "Green" })
        Write-Host "  Mensaje: $message" -ForegroundColor Gray
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "📊 Paso 5: Verificar estadísticas finales" -ForegroundColor Yellow
Write-Host "-----------------------------------------" -ForegroundColor Yellow
$status = Invoke-RestMethod -Uri $STATUS_ENDPOINT -Method Get
$status | ConvertTo-Json -Depth 10

$stats = $status.data.stats
Write-Host ""
Write-Host "Resumen de estadísticas:" -ForegroundColor Cyan
Write-Host "  Total de peticiones: $($stats.fires)" -ForegroundColor White
Write-Host "  Exitosas: $($stats.successes)" -ForegroundColor Green
Write-Host "  Fallidas: $($stats.failures)" -ForegroundColor Red
Write-Host "  Rechazadas (circuito abierto): $($stats.rejects)" -ForegroundColor Yellow
Write-Host "  Timeouts: $($stats.timeouts)" -ForegroundColor Red
Write-Host "  Fallbacks: $($stats.fallbacks)" -ForegroundColor Yellow
Write-Host "  Latencia promedio: $([math]::Round($stats.latencyMean, 2))ms" -ForegroundColor White
Write-Host ""

Write-Host "🔄 Paso 6: Información sobre auto-recuperación" -ForegroundColor Yellow
Write-Host "---------------------------------------------" -ForegroundColor Yellow
Write-Host "El circuito intentará cerrarse después de 60 segundos (HALF_OPEN)..." -ForegroundColor Cyan
Write-Host "Puedes resetear manualmente ejecutando:" -ForegroundColor Gray
Write-Host "  curl -X POST $RESET_ENDPOINT" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Demostración completada!" -ForegroundColor Green
Write-Host ""
Write-Host "Conclusiones del patrón Circuit Breaker:" -ForegroundColor Cyan
Write-Host "- ✅ Protege el sistema de fallos en cascada" -ForegroundColor White
Write-Host "- ⚡ Falla rápido (fail-fast) cuando el servicio externo está caído" -ForegroundColor White
Write-Host "- 🔄 Se auto-recupera probando periódicamente (HALF_OPEN → CLOSED)" -ForegroundColor White
Write-Host "- 📋 Proporciona fallback (encolar pagos) cuando el circuito está abierto" -ForegroundColor White
Write-Host "- 🛡️  Mejora la disponibilidad y resiliencia del sistema" -ForegroundColor White
Write-Host ""
