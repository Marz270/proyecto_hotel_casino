# ==========================================
# SET-BOOKING-MODE.PS1 - TFU2 (Versión Final)
# ==========================================
# Script robusto para configurar BOOKING_MODE sin caracteres Unicode

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("pg", "mock", "v2")]
    [string]$Mode
)

Write-Host "=== CONFIGURADOR BOOKING_MODE - TFU2 ===" -ForegroundColor Cyan
Write-Host "Configurando BOOKING_MODE = $Mode" -ForegroundColor Green

$envFile = ".env"

# Crear backup
if (Test-Path $envFile) {
    Copy-Item $envFile "$envFile.backup" -Force
    Write-Host "Backup creado: $envFile.backup" -ForegroundColor Yellow
}

# Template base del archivo .env
$baseContent = @(
    "# TFU2 - Configuracion de Base de Datos",
    "DB_HOST=db",
    "DB_USER=hoteluser", 
    "DB_PASSWORD=casino123",
    "DB_DATABASE=hotel_casino",
    "DB_PORT=5432",
    "",
    "# TFU2 - Configuracion de Aplicacion",
    "NODE_ENV=production",
    "BOOKING_MODE=$Mode"
)

# Escribir archivo limpio
Write-Host "Escribiendo archivo .env limpio..." -ForegroundColor Yellow
$baseContent | Set-Content $envFile -Encoding UTF8

# Verificar resultado
Write-Host ""
Write-Host "Archivo .env configurado:" -ForegroundColor Cyan
Write-Host "------------------------" -ForegroundColor Gray
Get-Content $envFile | ForEach-Object {
    if ($_ -match "BOOKING_MODE") {
        Write-Host $_ -ForegroundColor Green
    } else {
        Write-Host $_ -ForegroundColor White
    }
}
Write-Host "------------------------" -ForegroundColor Gray

# Verificar que no hay caracteres problemáticos
$content = Get-Content $envFile -Raw
if ($content -match '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]') {
    Write-Host "ADVERTENCIA: Se detectaron caracteres problemáticos" -ForegroundColor Red
} else {
    Write-Host "Verificacion: Sin caracteres Unicode problemáticos" -ForegroundColor Green
}

Write-Host ""
Write-Host "BOOKING_MODE configurado exitosamente a: $Mode" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "  docker-compose up -d --force-recreate backend_v1" -ForegroundColor Cyan
Write-Host "  docker-compose up -d --force-recreate backend_v2" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTA: Es necesario RECREAR el contenedor para que tome las nuevas variables" -ForegroundColor Yellow
Write-Host "=== CONFIGURACION COMPLETADA ===" -ForegroundColor Cyan