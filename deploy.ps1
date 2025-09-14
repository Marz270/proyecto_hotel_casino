# 🚀 Deploy Script para Windows - TFU2
# Demuestra "Diferir Binding" y "Facilidad de Despliegue"

Write-Host "🏨 === DEPLOY SCRIPT - TFU2 Análisis y Diseño de Aplicaciones II ===" -ForegroundColor Cyan
Write-Host "🎯 Desplegando Salto Hotel & Casino API..." -ForegroundColor Yellow

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

# Crear archivo .env si no existe
if (-not (Test-Path .env)) {
    Write-Log "📝 Creando archivo .env con configuración por defecto..."
    @"
# TFU2 - Configuración de Base de Datos
DB_HOST=db
DB_USER=hoteluser
DB_PASSWORD=casino123
DB_DATABASE=hotel_casino
DB_PORT=5432

# TFU2 - Configuración de Aplicación
NODE_ENV=production
BOOKING_MODE=pg
"@ | Out-File -FilePath .env -Encoding UTF8
}

# Verificar Docker
Write-Log "🔍 Verificando Docker y Docker Compose..."
try {
    docker --version | Out-Null
    docker-compose --version | Out-Null
} catch {
    Write-Error "Docker o Docker Compose no están instalados"
}

# Limpiar contenedores existentes
Write-Log "🧹 Limpiando contenedores existentes..."
docker-compose down --remove-orphans

# PASO 1: Iniciar base de datos
Write-Log "🗄️ PASO 1: Iniciando base de datos PostgreSQL..."
docker-compose up -d db

# PASO 2: Esperar que la DB esté lista
Write-Log "⏳ PASO 2: Esperando que la base de datos esté lista..."
$timeout = 60
$counter = 0
do {
    Start-Sleep -Seconds 2
    $counter += 2
    if ($counter -ge $timeout) {
        Write-Error "Timeout esperando la base de datos"
    }
    Write-Host "." -NoNewline
} while (-not (docker-compose exec -T db pg_isready -U hoteluser -d hotel_casino 2>$null))

Write-Host ""
Write-Log "✅ Base de datos lista!"

# PASO 3: Iniciar backend_v1
Write-Log "🚀 PASO 3: Desplegando backend_v1 (versión estable)..."
docker-compose up -d backend_v1

# PASO 4: Verificar que responda
Write-Log "🔍 PASO 4: Verificando que backend_v1 responda..."
Start-Sleep -Seconds 10
$counter = 0
do {
    Start-Sleep -Seconds 2
    $counter += 2
    if ($counter -ge 30) {
        Write-Error "backend_v1 no responde en http://localhost:3000"
    }
    Write-Host "." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 5
        $success = $true
    } catch {
        $success = $false
    }
} while (-not $success)

Write-Host ""
Write-Log "✅ backend_v1 desplegado exitosamente!"

Write-Host ""
Write-Host "🎉 === DESPLIEGUE COMPLETADO EXITOSAMENTE ===" -ForegroundColor Green
Write-Host "📊 Información del despliegue:" -ForegroundColor Cyan
Write-Host "   🌐 API v1 (estable): http://localhost:3000" -ForegroundColor White
Write-Host "   🗄️ Base de datos: localhost:5432" -ForegroundColor White
Write-Host "   🔗 Modo de binding: $((Get-Content .env | Where-Object {$_ -match 'BOOKING_MODE='}) -replace 'BOOKING_MODE=','')" -ForegroundColor White
Write-Host ""
Write-Host "📋 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   🔍 Probar API:          curl http://localhost:3000" -ForegroundColor White
Write-Host "   📝 Ver reservas:        curl http://localhost:3000/bookings" -ForegroundColor White
Write-Host "   🚀 Desplegar v2:        .\deploy-v2.ps1" -ForegroundColor White
Write-Host "   📊 Ver logs:            docker-compose logs -f backend_v1" -ForegroundColor White
Write-Host "   🔄 Cambiar a mock:      Editar .env → BOOKING_MODE=mock" -ForegroundColor White

Write-Log "🏁 Deploy script completado - Sistema listo!"