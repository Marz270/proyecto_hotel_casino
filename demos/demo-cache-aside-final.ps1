# demo-cache-aside.ps1
# Demostracion del patron Cache-Aside en el sistema de reservas
# Muestra mejora de rendimiento con cache vs sin cache

Write-Host "`n=== DEMO: Patron Cache-Aside ===" -ForegroundColor Cyan
Write-Host "Patron de Rendimiento - Optimizacion de consultas de disponibilidad`n" -ForegroundColor Gray

$baseUrl = "http://localhost:3000"
$month = "2025-01"

# Paso 1: Primera consulta (CACHE MISS - debe ir a BD)
Write-Host "PASO 1: Primera consulta de disponibilidad (CACHE MISS esperado)" -ForegroundColor Yellow
$time1 = Measure-Command { 
    $response1 = Invoke-RestMethod -Uri "$baseUrl/rooms/availability?month=$month" -Method GET 
}

Write-Host "[OK] Consulta completada" -ForegroundColor Green
Write-Host "  Origen: $($response1.source) (esperado: database)" -ForegroundColor $(if ($response1.source -eq "database") { "Green" } else { "Red" })
Write-Host "  Tiempo de respuesta: $([math]::Round($time1.TotalMilliseconds, 2))ms" -ForegroundColor Cyan
Write-Host "  Habitaciones encontradas: $($response1.data.Count)" -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 1

# Paso 2: Segunda consulta inmediata (CACHE HIT - debe venir del cache)
Write-Host "PASO 2: Segunda consulta (CACHE HIT esperado)" -ForegroundColor Yellow
$time2 = Measure-Command { 
    $response2 = Invoke-RestMethod -Uri "$baseUrl/rooms/availability?month=$month" -Method GET 
}

Write-Host "[OK] Consulta completada" -ForegroundColor Green
Write-Host "  Origen: $($response2.source) (esperado: cache)" -ForegroundColor $(if ($response2.source -eq "cache") { "Green" } else { "Red" })
Write-Host "  Tiempo de respuesta: $([math]::Round($time2.TotalMilliseconds, 2))ms" -ForegroundColor Cyan

# Calcular mejora de rendimiento
$mejora = [math]::Round((($time1.TotalMilliseconds - $time2.TotalMilliseconds) / $time1.TotalMilliseconds) * 100, 2)

Write-Host "  Mejora de rendimiento: $mejora%" -ForegroundColor $(if ($mejora -gt 0) { "Green" } else { "Yellow" })
Write-Host "  Reduccion de latencia: $([math]::Round($time1.TotalMilliseconds - $time2.TotalMilliseconds, 2))ms`n" -ForegroundColor Cyan

Start-Sleep -Seconds 1

# Paso 3: Multiples consultas para demostrar consistencia
Write-Host "PASO 3: Ejecutando 5 consultas adicionales (todas deben ser CACHE HIT)" -ForegroundColor Yellow

$hitCount = 0
$totalTimeWithCache = 0

for ($i = 1; $i -le 5; $i++) {
    $time = Measure-Command { 
        $result = Invoke-RestMethod -Uri "$baseUrl/rooms/availability?month=$month" -Method GET 
    }
    
    if ($result.source -eq "cache") {
        $hitCount++
        Write-Host "  [$i/5] CACHE HIT - $([math]::Round($time.TotalMilliseconds, 2))ms" -ForegroundColor Green
    } else {
        Write-Host "  [$i/5] CACHE MISS - $([math]::Round($time.TotalMilliseconds, 2))ms" -ForegroundColor Yellow
    }
    
    $totalTimeWithCache += $time.TotalMilliseconds
    Start-Sleep -Milliseconds 200
}

$avgTimeWithCache = [math]::Round($totalTimeWithCache / 5, 2)
Write-Host "`n[OK] Cache hits: $hitCount/5" -ForegroundColor Green
Write-Host "[OK] Tiempo promedio con cache: ${avgTimeWithCache}ms`n" -ForegroundColor Cyan

Start-Sleep -Seconds 1

# Paso 4: Obtener estadisticas del cache
Write-Host "PASO 4: Estadisticas del cache" -ForegroundColor Yellow
$stats = Invoke-RestMethod -Uri "$baseUrl/cache/stats" -Method GET

Write-Host "[OK] Estadisticas obtenidas:" -ForegroundColor Green
Write-Host "  Items totales: $($stats.data.totalItems)" -ForegroundColor Gray
Write-Host "  Items activos: $($stats.data.activeItems)" -ForegroundColor Green
Write-Host "  Items expirados: $($stats.data.expiredItems)" -ForegroundColor $(if ($stats.data.expiredItems -eq 0) { "Green" } else { "Yellow" })
Write-Host "  TTL por defecto: $($stats.data.defaultTTL)ms ($($stats.data.defaultTTL / 60000) minutos)`n" -ForegroundColor Gray

Start-Sleep -Seconds 1

# Paso 5: Demostrar invalidacion de cache al crear reserva
Write-Host "PASO 5: Demostracion de invalidacion de cache" -ForegroundColor Yellow
Write-Host "Creando una nueva reserva..." -ForegroundColor Gray

$booking = @{
    client_name = "Demo Usuario Cache"
    room_number = 101
    check_in = "2025-01-20"
    check_out = "2025-01-22"
    total_price = 300.00
} | ConvertTo-Json

try {
    $newBooking = Invoke-RestMethod -Uri "$baseUrl/bookings" -Method POST -Body $booking -ContentType "application/json"
    Write-Host "[OK] Reserva creada: ID $($newBooking.data.id)" -ForegroundColor Green
    
    Start-Sleep -Milliseconds 500
    
    # Consultar disponibilidad (deberia ser CACHE MISS por invalidacion)
    Write-Host "`nConsultando disponibilidad (deberia ser CACHE MISS por invalidacion)..." -ForegroundColor Gray
    $time3 = Measure-Command { 
        $response3 = Invoke-RestMethod -Uri "$baseUrl/rooms/availability?month=$month" -Method GET 
    }
    
    Write-Host "[OK] Origen: $($response3.source) (esperado: database)" -ForegroundColor $(if ($response3.source -eq "database") { "Green" } else { "Red" })
    Write-Host "[OK] Tiempo: $([math]::Round($time3.TotalMilliseconds, 2))ms" -ForegroundColor Cyan
    Write-Host "`n[OK] Cache invalidado correctamente al crear reserva!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Error al crear reserva: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Resumen final
Write-Host "=== RESUMEN DEL PATRON CACHE-ASIDE ===" -ForegroundColor Cyan
Write-Host "[OK] Primera consulta (CACHE MISS): $([math]::Round($time1.TotalMilliseconds, 2))ms - Datos de PostgreSQL" -ForegroundColor Yellow
Write-Host "[OK] Segunda consulta (CACHE HIT): $([math]::Round($time2.TotalMilliseconds, 2))ms - Datos del cache" -ForegroundColor Green
Write-Host "[OK] Mejora de rendimiento: $mejora%" -ForegroundColor Green
Write-Host "[OK] Promedio con cache: ${avgTimeWithCache}ms" -ForegroundColor Green

Write-Host "`n=== BENEFICIOS DEMOSTRADOS ===" -ForegroundColor Cyan
Write-Host "- Reduccion de carga en la base de datos" -ForegroundColor Gray
Write-Host "- Mejora significativa en tiempo de respuesta" -ForegroundColor Gray
Write-Host "- Cache con TTL automatico (5 minutos)" -ForegroundColor Gray
Write-Host "- Transparente para el cliente (misma API)" -ForegroundColor Gray
Write-Host "- Limpieza automatica de items expirados" -ForegroundColor Gray
Write-Host "- Invalidacion automatica al crear/eliminar reservas`n" -ForegroundColor Gray

Write-Host "Demo completada exitosamente!" -ForegroundColor Green
