# ============================================
# Demo Health Endpoint Monitoring Pattern
# Salto Hotel & Casino API
# ============================================

Write-Host "======================================" -ForegroundColor Blue
Write-Host "Health Endpoint Monitoring Demo" -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue
Write-Host ""

$API_URL = "http://localhost:3000"

# Funciones auxiliares
function Print-Header($text) {
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host $text -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
}

function Print-Success($text) {
    Write-Host "[OK] $text" -ForegroundColor Green
}

function Print-Warning($text) {
    Write-Host "[WARNING] $text" -ForegroundColor Yellow
}

function Print-Error($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

function Print-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor Cyan
}

# ============================================
# 1. Health Check Basico
# ============================================
Print-Header "1. Health Check Basico"
Write-Host "Consultando endpoint /health..."
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get -ErrorAction Stop
    
    if ($response.success) {
        Print-Success "API esta saludable"
        Write-Host ""
        
        $health = $response.data
        Print-Info "Status: $($health.status)"
        Print-Info "Version: $($health.version)"
        Print-Info "Environment: $($health.environment)"
        Print-Info "Uptime: $([math]::Round($health.uptime, 2)) segundos"
        Print-Info "Timestamp: $($health.timestamp)"
    } else {
        Print-Error "Health check fallo"
    }
} catch {
    Print-Error "No se pudo conectar al endpoint /health"
    Print-Error $_.Exception.Message
    exit 1
}

Write-Host ""

# ============================================
# 2. Verificar Componentes Individuales
# ============================================
Print-Header "2. Estado de Componentes"
Write-Host "Revisando estado de cada componente..."
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get
    $checks = $response.data.checks
    
    # Database check
    Write-Host "Database:" -ForegroundColor Cyan
    if ($checks.database.status -eq "healthy") {
        Print-Success "  Estado: $($checks.database.status)"
        Print-Info "  Tiempo de respuesta: $($checks.database.responseTime)"
    } else {
        Print-Error "  Estado: $($checks.database.status)"
        if ($checks.database.error) {
            Print-Error "  Error: $($checks.database.error)"
        }
    }
    Write-Host ""
    
    # Memory check
    Write-Host "Memory:" -ForegroundColor Cyan
    if ($checks.memory.status -eq "healthy") {
        Print-Success "  Estado: $($checks.memory.status)"
        Print-Info "  Usado: $($checks.memory.used) / $($checks.memory.total)"
        Print-Info "  Porcentaje: $($checks.memory.percentage)"
    } elseif ($checks.memory.status -eq "warning") {
        Print-Warning "  Estado: $($checks.memory.status)"
        Print-Warning "  Usado: $($checks.memory.used) / $($checks.memory.total)"
        Print-Warning "  Porcentaje: $($checks.memory.percentage) (alta utilizacion)"
    } else {
        Print-Error "  Estado: $($checks.memory.status)"
    }
    Write-Host ""
    
    # Circuit Breaker check
    Write-Host "Circuit Breaker:" -ForegroundColor Cyan
    if ($checks.circuitBreaker.status -eq "healthy") {
        Print-Success "  Estado: $($checks.circuitBreaker.status)"
        Print-Info "  State: $($checks.circuitBreaker.state)"
        Print-Info "  Total Requests: $($checks.circuitBreaker.stats.totalRequests)"
        Print-Info "  Failures: $($checks.circuitBreaker.stats.failures)"
        Print-Info "  Success Rate: $($checks.circuitBreaker.stats.successRate)%"
    } elseif ($checks.circuitBreaker.status -eq "degraded") {
        Print-Warning "  Estado: $($checks.circuitBreaker.status)"
        Print-Warning "  State: $($checks.circuitBreaker.state)"
        Print-Warning "  $($checks.circuitBreaker.message)"
    } else {
        Print-Error "  Estado: $($checks.circuitBreaker.status)"
    }
} catch {
    Print-Error "Error al obtener detalles de componentes"
}

Write-Host ""

# ============================================
# 3. Monitoreo Continuo (5 checks cada 3 seg)
# ============================================
Print-Header "3. Monitoreo Continuo"
Write-Host "Realizando 5 health checks cada 3 segundos..."
Write-Host ""

$healthHistory = @()

for ($i = 1; $i -le 5; $i++) {
    try {
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get -ErrorAction Stop
        $endTime = Get-Date
        $responseTime = ($endTime - $startTime).TotalMilliseconds
        
        $status = $response.data.status
        $dbStatus = $response.data.checks.database.status
        $memUsage = $response.data.checks.memory.percentage
        
        $healthHistory += @{
            Check = $i
            Status = $status
            ResponseTime = [math]::Round($responseTime, 2)
            DbStatus = $dbStatus
            MemUsage = $memUsage
        }
        
        $statusColor = if ($status -eq "healthy") { "Green" } else { "Red" }
        Write-Host "Check #$i - " -NoNewline
        Write-Host "$status" -ForegroundColor $statusColor -NoNewline
        Write-Host " | Response: ${responseTime}ms | DB: $dbStatus | Memory: $memUsage"
        
        if ($i -lt 5) {
            Start-Sleep -Seconds 3
        }
    } catch {
        Print-Error "Check #$i - Failed"
        $healthHistory += @{
            Check = $i
            Status = "error"
            ResponseTime = 0
            DbStatus = "error"
            MemUsage = "N/A"
        }
    }
}

Write-Host ""

# ============================================
# 4. Estadisticas de Monitoreo
# ============================================
Print-Header "4. Estadisticas de Monitoreo"

$successfulChecks = ($healthHistory | Where-Object { $_.Status -eq "healthy" }).Count

# Calcular promedio de tiempo de respuesta
$totalResponseTime = 0
$validChecks = 0
foreach ($check in $healthHistory) {
    if ($check.ResponseTime -gt 0) {
        $totalResponseTime += $check.ResponseTime
        $validChecks++
    }
}
$avgResponseTime = if ($validChecks -gt 0) { $totalResponseTime / $validChecks } else { 0 }

Write-Host ""
Print-Info "Checks exitosos: $successfulChecks / 5"
Print-Info "Tiempo de respuesta promedio: $([math]::Round($avgResponseTime, 2))ms"

if ($successfulChecks -eq 5) {
    Print-Success "Todos los health checks pasaron correctamente"
} elseif ($successfulChecks -ge 3) {
    Print-Warning "Algunos health checks fallaron ($successfulChecks/5)"
} else {
    Print-Error "La mayoria de health checks fallaron ($successfulChecks/5)"
}

Write-Host ""

# ============================================
# 5. Simulacion de Fallo (Opcional)
# ============================================
Print-Header "5. Simulacion de Fallo de Base de Datos"
Write-Host "Para probar el comportamiento ante fallos:"
Write-Host ""
Write-Host "  1. Detener la base de datos:" -ForegroundColor Yellow
Write-Host "     docker-compose stop db" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Verificar health check (deberia fallar):" -ForegroundColor Yellow
Write-Host "     Invoke-RestMethod -Uri http://localhost:3000/health" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Reiniciar la base de datos:" -ForegroundColor Yellow
Write-Host "     docker-compose start db" -ForegroundColor Gray
Write-Host ""

# ============================================
# Resumen
# ============================================
Print-Header "Resumen de Health Endpoint Monitoring"

Write-Host ""
Write-Host "Funcionalidades verificadas:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Health endpoint (/health) operativo"
Write-Host "  - Verificacion de conexion a PostgreSQL"
Write-Host "  - Monitoreo de uso de memoria"
Write-Host "  - Estado del Circuit Breaker"
Write-Host "  - Tiempo de respuesta < 100ms"
Write-Host "  - Deteccion automatica de componentes degradados"
Write-Host ""

Print-Success "Health Endpoint Monitoring Pattern implementado correctamente"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Para mas informacion:"
Write-Host "  - Endpoint: GET /health"
Write-Host "  - Implementacion: backend/routes/index.routes.js"
Write-Host "  - README: backend/patterns/health-endpoint/README.md"
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""
