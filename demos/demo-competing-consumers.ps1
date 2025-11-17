# ========================================
# DEMO: Competing Consumers Pattern
# ========================================
# Demuestra el patron Competing Consumers con workers in-memory
# procesando tareas concurrentemente desde una cola

$API_URL = "http://localhost:3000"
$ErrorActionPreference = "Continue"

# Funciones de utilidad
function Print-Header {
    param([string]$text)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $text -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$text)
    Write-Host "[OK] $text" -ForegroundColor Green
}

function Print-Warning {
    param([string]$text)
    Write-Host "[WARNING] $text" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$text)
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

function Print-Info {
    param([string]$text)
    Write-Host "[INFO] $text" -ForegroundColor Blue
}

function Wait-Seconds {
    param([int]$seconds, [string]$message = "Esperando")
    Write-Host "`n$message " -NoNewline -ForegroundColor Gray
    for ($i = 0; $i -lt $seconds; $i++) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }
    Write-Host ""
}

# ========================================
# 1. VERIFICAR API
# ========================================
Print-Header "1. VERIFICANDO API"

try {
    $response = Invoke-RestMethod -Uri "$API_URL/" -Method Get -TimeoutSec 5
    if ($response.success) {
        Print-Success "API respondiendo correctamente"
        Print-Info "Version: $($response.data.version)"
        Print-Info "Modo: $($response.data.booking_mode)"
    }
} catch {
    Print-Error "API no disponible. Asegurate de que Docker este corriendo."
    Print-Info "Ejecuta: docker-compose up -d"
    exit 1
}

# ========================================
# 2. RESETEAR COLA Y WORKERS
# ========================================
Print-Header "2. PREPARANDO SISTEMA"

try {
    # Detener workers si estaban corriendo
    $stopResponse = Invoke-RestMethod -Uri "$API_URL/queue/workers/stop" -Method Post
    Print-Info "Workers detenidos"
    
    # Resetear cola
    $resetResponse = Invoke-RestMethod -Uri "$API_URL/queue/reset" -Method Delete
    Print-Success "Sistema reiniciado y listo para la demo"
} catch {
    Print-Warning "No se pudo resetear (primera ejecucion?)"
}

# ========================================
# 3. INICIAR WORKERS
# ========================================
Print-Header "3. INICIANDO POOL DE WORKERS"

try {
    $startResponse = Invoke-RestMethod -Uri "$API_URL/queue/workers/start" -Method Post
    
    if ($startResponse.success) {
        Print-Success "Workers iniciados exitosamente"
        
        foreach ($worker in $startResponse.workers) {
            $status = if ($worker.isRunning) { "ACTIVO" } else { "INACTIVO" }
            $statusColor = if ($worker.isRunning) { "Green" } else { "Red" }
            Write-Host "  Worker $($worker.id): " -NoNewline
            Write-Host $status -ForegroundColor $statusColor
            Print-Info "    Polling interval: $($worker.pollInterval)ms"
        }
    }
} catch {
    Print-Error "Error al iniciar workers: $_"
    exit 1
}

# ========================================
# 4. AGREGAR TAREAS INDIVIDUALES
# ========================================
Print-Header "4. AGREGANDO TAREAS INDIVIDUALES"

$tasks = @(
    @{ type = "email"; data = @{ to = "guest1@hotel.com"; subject = "Confirmacion de Reserva"; bookingId = "RES-001" } }
    @{ type = "reservation"; data = @{ clientId = 123; roomId = 301; checkIn = "2025-11-01"; checkOut = "2025-11-05" } }
    @{ type = "payment"; data = @{ amount = 500; currency = "USD"; cardLast4 = "4242" } }
    @{ type = "notification"; data = @{ userId = "user-456"; message = "Tu reserva esta confirmada"; channel = "push" } }
    @{ type = "email"; data = @{ to = "guest2@hotel.com"; subject = "Recordatorio Check-in"; bookingId = "RES-002" } }
)

$addedTasks = @()

foreach ($task in $tasks) {
    try {
        $body = $task | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri "$API_URL/queue/tasks" -Method Post -Body $body -ContentType "application/json"
        
        if ($response.success) {
            $addedTasks += $response.task
            Print-Success "Tarea agregada: $($response.task.type) - ID: $($response.task.id)"
        }
    } catch {
        Print-Error "Error al agregar tarea: $_"
    }
}

Print-Info "Total agregadas: $($addedTasks.Count) tareas"

# ========================================
# 5. MONITOREAR PROCESAMIENTO
# ========================================
Print-Header "5. MONITOREANDO PROCESAMIENTO (15 segundos)"

for ($i = 1; $i -le 5; $i++) {
    try {
        $stats = Invoke-RestMethod -Uri "$API_URL/queue/stats" -Method Get
        
        Write-Host "`n--- Check #$i ---" -ForegroundColor Cyan
        Write-Host "Pendientes: " -NoNewline
        Write-Host $stats.stats.pending -ForegroundColor Yellow
        Write-Host "Procesando: " -NoNewline
        Write-Host $stats.stats.processing -ForegroundColor Blue
        Write-Host "Completadas: " -NoNewline
        Write-Host $stats.stats.completed -ForegroundColor Green
        Write-Host "Fallidas: " -NoNewline
        Write-Host $stats.stats.failed -ForegroundColor Red
        
        if ($stats.processing.Count -gt 0) {
            Write-Host "`nTareas en procesamiento:" -ForegroundColor Blue
            foreach ($proc in $stats.processing) {
                $duration = [math]::Round($proc.duration / 1000, 2)
                Write-Host "  Worker $($proc.workerId): $($proc.type) ($($duration)s)" -ForegroundColor Gray
            }
        }
        
    } catch {
        Print-Warning "Error al obtener estadisticas: $_"
    }
    
    if ($i -lt 5) {
        Start-Sleep -Seconds 3
    }
}

# ========================================
# 6. AGREGAR BATCH DE TAREAS
# ========================================
Print-Header "6. AGREGANDO BATCH DE 10 TAREAS"

$batchTasks = @()
for ($i = 1; $i -le 10; $i++) {
    $taskType = @("email", "reservation", "payment", "notification")[$i % 4]
    $batchTasks += @{
        type = $taskType
        data = @{
            batchNumber = $i
            timestamp = (Get-Date).ToString("o")
        }
    }
}

try {
    $batchBody = @{ tasks = $batchTasks } | ConvertTo-Json -Depth 10
    $batchResponse = Invoke-RestMethod -Uri "$API_URL/queue/tasks/batch" -Method Post -Body $batchBody -ContentType "application/json"
    
    if ($batchResponse.success) {
        Print-Success "$($batchResponse.message)"
        Print-Info "Los 3 workers procesaran estas tareas concurrentemente"
    }
} catch {
    Print-Error "Error al agregar batch: $_"
}

# ========================================
# 7. MONITOREAR BATCH (20 segundos)
# ========================================
Print-Header "7. MONITOREANDO BATCH (20 segundos)"

$maxChecks = 7
$checkInterval = 3

for ($i = 1; $i -le $maxChecks; $i++) {
    try {
        $stats = Invoke-RestMethod -Uri "$API_URL/queue/stats" -Method Get
        
        Write-Host "`n--- Batch Check #$i/$maxChecks ---" -ForegroundColor Cyan
        Write-Host "Pendientes: $($stats.stats.pending) | " -NoNewline -ForegroundColor Yellow
        Write-Host "Procesando: $($stats.stats.processing) | " -NoNewline -ForegroundColor Blue
        Write-Host "Completadas: $($stats.stats.completed)" -ForegroundColor Green
        
        # Mostrar progreso
        $total = [int]$stats.stats.pending + [int]$stats.stats.processing + [int]$stats.stats.completed
        if ($total -gt 0) {
            $progress = [math]::Round(([int]$stats.stats.completed / $total) * 100, 1)
            Write-Host "Progreso: $progress%" -ForegroundColor Cyan
        }
        
        # Si no quedan tareas pendientes ni procesando, salir
        if ($stats.stats.pending -eq 0 -and $stats.stats.processing -eq 0) {
            Print-Success "Todas las tareas han sido procesadas!"
            break
        }
        
    } catch {
        Print-Warning "Error al obtener estadisticas: $_"
    }
    
    if ($i -lt $maxChecks) {
        Start-Sleep -Seconds $checkInterval
    }
}

# ========================================
# 8. ESTADISTICAS FINALES
# ========================================
Print-Header "8. ESTADISTICAS FINALES"

try {
    $finalStats = Invoke-RestMethod -Uri "$API_URL/queue/stats" -Method Get
    $workersStatus = Invoke-RestMethod -Uri "$API_URL/queue/workers" -Method Get
    
    Write-Host "`n=== RESUMEN DE LA COLA ===" -ForegroundColor Green
    Write-Host "Total procesadas: " -NoNewline
    Write-Host $finalStats.stats.completed -ForegroundColor Green
    Write-Host "Total fallidas: " -NoNewline
    Write-Host $finalStats.stats.failed -ForegroundColor Red
    Write-Host "Tasa de exito: " -NoNewline
    Write-Host $finalStats.stats.successRate -ForegroundColor Cyan
    Write-Host "Pendientes: " -NoNewline
    Write-Host $finalStats.stats.pending -ForegroundColor Yellow
    
    Write-Host "`n=== ESTADO DE WORKERS ===" -ForegroundColor Green
    foreach ($worker in $workersStatus.workers) {
        Write-Host "`nWorker $($worker.id):" -ForegroundColor Cyan
        Write-Host "  Estado: " -NoNewline
        if ($worker.isRunning) {
            Write-Host "ACTIVO" -ForegroundColor Green
        } else {
            Write-Host "INACTIVO" -ForegroundColor Red
        }
        Write-Host "  Tareas procesadas: $($worker.tasksProcessed)"
        Write-Host "  Intervalo de polling: $($worker.pollInterval)ms"
    }
    
    if ($finalStats.recentCompleted.Count -gt 0) {
        Write-Host "`n=== ULTIMAS TAREAS COMPLETADAS ===" -ForegroundColor Green
        foreach ($task in $finalStats.recentCompleted | Select-Object -Last 5) {
            Write-Host "  ID: $($task.id) | Worker: $($task.workerId) | Completada: $($task.completedAt)" -ForegroundColor Gray
        }
    }
    
} catch {
    Print-Error "Error al obtener estadisticas finales: $_"
}

# ========================================
# 9. DETENER WORKERS
# ========================================
Print-Header "9. DETENIENDO WORKERS"

try {
    $stopResponse = Invoke-RestMethod -Uri "$API_URL/queue/workers/stop" -Method Post
    
    if ($stopResponse.success) {
        Print-Success "Todos los workers detenidos correctamente"
        
        foreach ($worker in $stopResponse.workers) {
            Write-Host "  Worker $($worker.id): $($worker.tasksProcessed) tareas procesadas" -ForegroundColor Gray
        }
    }
} catch {
    Print-Error "Error al detener workers: $_"
}

# ========================================
# 10. BENEFICIOS DEL PATRON
# ========================================
Print-Header "10. BENEFICIOS DEL PATRON COMPETING CONSUMERS"

Write-Host @"

1. PROCESAMIENTO PARALELO
   Multiple workers procesan tareas concurrentemente,
   aumentando el throughput del sistema.

2. ESCALABILIDAD
   Facil agregar o quitar workers segun la carga.
   Cada worker opera independientemente.

3. TOLERANCIA A FALLOS
   Si un worker falla, otros continuan procesando.
   Las tareas fallidas pueden reintentarse.

4. BALANCEO DE CARGA
   Las tareas se distribuyen automaticamente
   entre los workers disponibles (FIFO).

5. DESACOPLAMIENTO
   Los productores (API) y consumidores (workers)
   estan desacoplados por la cola.

CASOS DE USO:
- Envio de emails masivos
- Procesamiento de imagenes
- Generacion de reportes
- Notificaciones push
- Procesamiento de pagos
- Integraciones con servicios externos

"@ -ForegroundColor Yellow

Print-Header "DEMO COMPLETADA"
Print-Success "Patron Competing Consumers demostrado exitosamente!"
Print-Info "Los workers procesaron tareas concurrentemente desde una cola compartida"
