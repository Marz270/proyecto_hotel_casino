# Deploy V2 Script para Windows - TFU2
# Demuestra tactica de "Rollback" con despliegue blue-green

Write-Host "=== DEPLOY V2 SCRIPT - TFU2 ===" -ForegroundColor Cyan
Write-Host "Desplegando version 2 de Hotel & Casino API..." -ForegroundColor Yellow

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red
    exit 1
}

# PASO 1: Verificar que v1 este funcionando
Write-Log "PASO 1: Verificando que backend_v1 este activo..."
try {
    $null = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 10
    Write-Log "backend_v1 funcionando correctamente"
} catch {
    Write-Error "backend_v1 no esta funcionando en localhost:3000. Ejecuta .\deploy.ps1 primero"
}

# PASO 2: Desplegar backend_v2
Write-Log "PASO 2: Desplegando backend_v2 (nueva version)..."
docker-compose --profile v2 up -d backend_v2

# PASO 3: Configurar nginx para v2
Write-Log "PASO 3: Configurando nginx para usar v2..."
Copy-Item -Path "./nginx/nginx.rollback.conf" -Destination "./nginx/nginx.conf" -Force

# PASO 4: Reiniciar nginx
Write-Log "PASO 4: Reiniciando nginx con nueva configuracion..."
docker restart hotel_nginx

# PASO 3: Esperar que v2 este lista
Write-Log "PASO 3: Esperando que backend_v2 este lista en localhost:3001..."
Start-Sleep -Seconds 15
$counter = 0
do {
    Start-Sleep -Seconds 3
    $counter += 3
    if ($counter -ge 45) {
        Write-Log "backend_v2 no responde, manteniendo v1 activa"
        docker-compose stop backend_v2
        Write-Error "Timeout esperando backend_v2"
    }
    Write-Host "." -NoNewline
    try {
        $null = Invoke-WebRequest -Uri "http://localhost:3001" -Method GET -TimeoutSec 5
        $success = $true
    } catch {
        $success = $false
    }
} while (-not $success)

Write-Host ""
Write-Log "backend_v2 esta respondiendo!"

# PASO 4: Verificar ambas versiones
Write-Log "PASO 4: Verificando respuestas de ambas versiones..."
try {
    $v1_response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 10
    $v2_response = Invoke-WebRequest -Uri "http://localhost:3001" -Method GET -TimeoutSec 10
    
    if ($v1_response.Content -match '"version":"1.0.0"' -and $v2_response.Content -match '"version":"2.0.0"') {
        Write-Log "Ambas versiones funcionando correctamente"
    } else {
        Write-Log "Error en las versiones. Limpiando v2..."
        docker-compose stop backend_v2
        Write-Error "Las versiones no responden correctamente"
    }
} catch {
    Write-Log "Error verificando versiones. Limpiando v2..."
    docker-compose stop backend_v2
    Write-Error "Error en la verificacion de versiones"
}

Write-Host ""
Write-Host "=== DESPLIEGUE V2 COMPLETADO EXITOSAMENTE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Estado actual del sistema:" -ForegroundColor Cyan
Write-Host "   v1 (estable) -> http://localhost:3000" -ForegroundColor White
Write-Host "   v2 (nueva) -> http://localhost:3001" -ForegroundColor White
Write-Host "   Base de datos compartida -> localhost:5432" -ForegroundColor White
Write-Host ""
Write-Host "Comandos de testing:" -ForegroundColor Cyan
Write-Host "   Test v1: curl http://localhost:3000/bookings" -ForegroundColor White
Write-Host "   Test v2: curl http://localhost:3001/bookings" -ForegroundColor White
Write-Host "   Rollback: .\rollback.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Si hay problemas con v2, ejecuta: .\rollback.ps1" -ForegroundColor Yellow

Write-Log "Deploy v2 completado - Ambas versiones activas!"