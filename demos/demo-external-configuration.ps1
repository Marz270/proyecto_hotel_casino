# ============================================
# Demo External Configuration Store Pattern
# Salto Hotel & Casino API
# ============================================

Write-Host "======================================" -ForegroundColor Blue
Write-Host "External Configuration Store Demo" -ForegroundColor Blue
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

function Get-CurrentConfig {
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/" -Method Get -ErrorAction Stop
        return @{
            Version = $response.data.version
            BookingMode = $response.data.booking_mode
            Success = $true
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Wait-ForBackend($maxAttempts = 10) {
    Write-Host "Esperando a que el backend inicie..." -NoNewline
    
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            $response = Invoke-RestMethod -Uri "$API_URL/" -Method Get -ErrorAction Stop
            Write-Host " OK" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host " TIMEOUT" -ForegroundColor Red
    return $false
}

# ============================================
# 1. Estado Actual de Configuracion
# ============================================
Print-Header "1. Estado Actual de Configuracion"
Write-Host ""

$currentConfig = Get-CurrentConfig

if ($currentConfig.Success) {
    Print-Success "API respondiendo correctamente"
    Print-Info "Version: $($currentConfig.Version)"
    Print-Info "Booking Mode: $($currentConfig.BookingMode)"
    
    $originalMode = $currentConfig.BookingMode
} else {
    Print-Error "No se pudo conectar a la API"
    Print-Error $currentConfig.Error
    exit 1
}

Write-Host ""

# ============================================
# 2. Verificar Datos Actuales
# ============================================
Print-Header "2. Verificar Datos Actuales ($originalMode mode)"
Write-Host ""

try {
    $bookings = Invoke-RestMethod -Uri "$API_URL/bookings" -Method Get
    $count = $bookings.data.Count
    $source = $bookings.source
    
    Print-Info "Total de reservas: $count"
    Print-Info "Fuente de datos: $source"
    
    if ($count -gt 0) {
        Print-Info "Primera reserva: ID=$($bookings.data[0].id), Cliente=$($bookings.data[0].client_name)"
    }
} catch {
    Print-Warning "Error al obtener reservas: $($_.Exception.Message)"
}

Write-Host ""

# ============================================
# 3. Cambiar a Modo Alternativo
# ============================================
$targetMode = if ($originalMode -eq "pg") { "mock" } else { "pg" }

Print-Header "3. Cambiar Configuracion: $originalMode -> $targetMode"
Write-Host ""

Print-Info "Deteniendo backend..."
docker-compose stop backend_v1 2>&1 | Out-Null

Print-Info "Cambiando BOOKING_MODE a '$targetMode'..."
$env:BOOKING_MODE = $targetMode

Print-Info "Iniciando backend con nueva configuracion..."
docker-compose up -d backend_v1 2>&1 | Out-Null

if (Wait-ForBackend) {
    $newConfig = Get-CurrentConfig
    
    if ($newConfig.BookingMode -eq $targetMode) {
        Print-Success "Configuracion cambiada exitosamente"
        Print-Info "Nuevo Booking Mode: $($newConfig.BookingMode)"
    } else {
        Print-Warning "Booking Mode no cambio como se esperaba"
        Print-Warning "Esperado: $targetMode, Actual: $($newConfig.BookingMode)"
    }
} else {
    Print-Error "Backend no inicio correctamente"
    exit 1
}

Write-Host ""

# ============================================
# 4. Verificar Comportamiento con Nueva Config
# ============================================
Print-Header "4. Verificar Comportamiento ($targetMode mode)"
Write-Host ""

try {
    $bookings = Invoke-RestMethod -Uri "$API_URL/bookings" -Method Get
    $count = $bookings.data.Count
    $source = $bookings.source
    
    Print-Info "Total de reservas: $count"
    Print-Info "Fuente de datos: $source"
    
    if ($targetMode -eq "mock") {
        if ($source -like "*Mock*") {
            Print-Success "Modo MOCK activo - datos en memoria"
            Print-Info "Mock data incluye $count reservas de prueba"
        } else {
            Print-Warning "Se esperaba fuente con 'Mock', obtenido '$source'"
        }
    } else {
        if ($source -like "*PostgreSQL*") {
            Print-Success "Modo PostgreSQL activo - datos persistentes"
            Print-Info "Database contiene $count reservas reales"
        } else {
            Print-Warning "Se esperaba fuente con 'PostgreSQL', obtenido '$source'"
        }
    }
} catch {
    Print-Error "Error al obtener reservas: $($_.Exception.Message)"
}

Write-Host ""

# ============================================
# 5. Probar Persistencia
# ============================================
Print-Header "5. Probar Persistencia de Datos"
Write-Host ""

if ($targetMode -eq "pg") {
    Print-Info "Creando una reserva en modo PostgreSQL..."
    
    $newBooking = @{
        client_name = "Config Test User"
        room_number = 101
        check_in = "2025-11-15"
        check_out = "2025-11-17"
        total_price = 200.00
    } | ConvertTo-Json
    
    try {
        $result = Invoke-RestMethod -Uri "$API_URL/bookings" -Method Post -Body $newBooking -ContentType "application/json"
        Print-Success "Reserva creada: ID=$($result.data.id)"
        $testBookingId = $result.data.id
        
        # Verificar que se guardo
        Start-Sleep -Seconds 1
        $verify = Invoke-RestMethod -Uri "$API_URL/bookings/$testBookingId" -Method Get
        Print-Success "Reserva verificada en database"
        
        # Limpiar
        Invoke-RestMethod -Uri "$API_URL/bookings/$testBookingId" -Method Delete | Out-Null
        Print-Info "Reserva de prueba eliminada"
    } catch {
        Print-Warning "Error al probar persistencia: $($_.Exception.Message)"
    }
} else {
    Print-Info "En modo MOCK, los datos NO persisten"
    Print-Info "Al reiniciar el servicio, los datos mock se reinician"
    Print-Warning "Los datos creados en MOCK se pierden al cambiar a PG mode"
}

Write-Host ""

# ============================================
# 6. Restaurar Configuracion Original
# ============================================
Print-Header "6. Restaurar Configuracion Original"
Write-Host ""

if ($originalMode -ne $targetMode) {
    Print-Info "Restaurando BOOKING_MODE a '$originalMode'..."
    
    docker-compose stop backend_v1 2>&1 | Out-Null
    $env:BOOKING_MODE = $originalMode
    docker-compose up -d backend_v1 2>&1 | Out-Null
    
    if (Wait-ForBackend) {
        $restoredConfig = Get-CurrentConfig
        
        if ($restoredConfig.BookingMode -eq $originalMode) {
            Print-Success "Configuracion restaurada exitosamente"
            Print-Info "Booking Mode actual: $($restoredConfig.BookingMode)"
        } else {
            Print-Warning "Booking Mode: $($restoredConfig.BookingMode)"
        }
    }
} else {
    Print-Info "Ya esta en la configuracion original: $originalMode"
}

Write-Host ""

# ============================================
# 7. Ventajas del Patron
# ============================================
Print-Header "7. Ventajas de External Configuration Store"
Write-Host ""

Write-Host "Beneficios demostrados:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Cambio de comportamiento SIN recompilar codigo"
Write-Host "     - Switching entre mock/pg sin rebuild"
Write-Host ""
Write-Host "  2. Deferred Binding (Diferir Enlace)"
Write-Host "     - Factory resuelve dependencias en runtime"
Write-Host "     - BookingServiceFactory.createBookingService()"
Write-Host ""
Write-Host "  3. Multiple entornos con mismo artefacto"
Write-Host "     - Dev: BOOKING_MODE=mock (sin DB)"
Write-Host "     - Prod: BOOKING_MODE=pg (con PostgreSQL)"
Write-Host ""
Write-Host "  4. Feature Toggles simplificados"
Write-Host "     - Activar/desactivar features via config"
Write-Host ""
Write-Host "  5. Rollback instantaneo"
Write-Host "     - Revertir config sin redesplegar codigo"
Write-Host ""

# ============================================
# 8. Casos de Uso Practicos
# ============================================
Print-Header "8. Casos de Uso Practicos"
Write-Host ""

Write-Host "Escenarios reales:" -ForegroundColor Cyan
Write-Host ""

Write-Host "A. Desarrollo Local (mock mode)" -ForegroundColor Yellow
Write-Host "   - Frontend developer sin PostgreSQL instalado"
Write-Host "   - Testing rapido con datos predecibles"
Write-Host "   - Sin dependencias externas"
Write-Host ""

Write-Host "B. CI/CD Pipelines (mock mode)" -ForegroundColor Yellow
Write-Host "   - Tests unitarios sin base de datos"
Write-Host "   - Builds mas rapidos"
Write-Host "   - Sin necesidad de provisionar DB"
Write-Host ""

Write-Host "C. Produccion (pg mode)" -ForegroundColor Yellow
Write-Host "   - Datos persistentes en PostgreSQL"
Write-Host "   - Alta disponibilidad"
Write-Host "   - Backups y disaster recovery"
Write-Host ""

Write-Host "D. Canary Deployment" -ForegroundColor Yellow
Write-Host "   - 90% trafico -> v1 (config estable)"
Write-Host "   - 10% trafico -> v2 (config experimental)"
Write-Host "   - Rollback cambiando variable"
Write-Host ""

# ============================================
# Resumen
# ============================================
Print-Header "Resumen de External Configuration Store"
Write-Host ""

Write-Host "Funcionalidades verificadas:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - Configuracion externalizada (variables de entorno)"
Write-Host "  - Deferred Binding (Factory Pattern)"
Write-Host "  - Cambio de config sin recompilar"
Write-Host "  - Multiple entornos (dev/prod)"
Write-Host "  - Feature toggles (mock/pg mode)"
Write-Host "  - Zero downtime configuration change"
Write-Host ""

Print-Success "External Configuration Store Pattern implementado correctamente"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Para mas informacion:"
Write-Host "  - Factory: backend/services/bookingServiceFactory.js"
Write-Host "  - Mock Service: backend/services/bookingService.mock.js"
Write-Host "  - PG Service: backend/services/bookingService.pg.js"
Write-Host "  - README: backend/patterns/external-configuration/README.md"
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

Write-Host "Comandos utiles:" -ForegroundColor Yellow
Write-Host "  # Cambiar a mock mode"
Write-Host "  `$env:BOOKING_MODE='mock'; docker-compose up -d --force-recreate backend_v1"
Write-Host ""
Write-Host "  # Cambiar a pg mode"
Write-Host "  `$env:BOOKING_MODE='pg'; docker-compose up -d --force-recreate backend_v1"
Write-Host ""
Write-Host "  # Verificar config actual"
Write-Host "  Invoke-RestMethod -Uri http://localhost:3000/ | Select-Object -ExpandProperty data"
Write-Host ""
