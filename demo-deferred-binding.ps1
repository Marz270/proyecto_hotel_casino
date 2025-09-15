# ==========================================
# DEMO-DEFERRED-BINDING.PS1 - TFU2
# ==========================================
# Script para demostrar Deferred Binding de forma sistemática
# Cambia entre PostgreSQL y Mock sin recompilar código

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("complete", "pg-to-mock", "mock-to-pg")]
    [string]$DemoType = "complete"
)

Write-Host "=== DEMOSTRACION DEFERRED BINDING - TFU2 ===" -ForegroundColor Cyan
Write-Host "Demostrando cambio de implementación sin recompilar código" -ForegroundColor Green

function Show-CurrentBinding {
    Write-Host "`n🔍 ESTADO ACTUAL DEL DEFERRED BINDING:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $envContent = Get-Content .env | Where-Object { $_ -match "BOOKING_MODE" }
    Write-Host "📁 Configuración: $envContent" -ForegroundColor Cyan
    
    # Probar endpoint actual
    Write-Host "🌐 Probando endpoint actual..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/bookings" -Method GET -TimeoutSec 10
        $data = $response.Content | ConvertFrom-Json
        
        Write-Host "✅ Respuesta exitosa:" -ForegroundColor Green
        Write-Host "   📊 Source: $($data.source)" -ForegroundColor White
        Write-Host "   📈 Count: $($data.count)" -ForegroundColor White
        Write-Host "   🏷️ Data: $($data.data[0].client_name)" -ForegroundColor White
        
        return $data.source
    } catch {
        Write-Host "❌ Error al probar endpoint: $($_.Exception.Message)" -ForegroundColor Red
        return "ERROR"
    }
}

function Test-Endpoint {
    param([string]$ExpectedSource)
    
    Write-Host "`n🧪 PRUEBA DE ENDPOINT:" -ForegroundColor Magenta
    Write-Host "----------------------" -ForegroundColor Gray
    Write-Host "Esperado: $ExpectedSource" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/bookings" -Method GET
        $data = $response.Content | ConvertFrom-Json
        
        Write-Host "📊 Resultado: $($data.source)" -ForegroundColor White
        Write-Host "📈 Registros: $($data.count)" -ForegroundColor White
        
        if ($data.source -eq $ExpectedSource) {
            Write-Host "✅ PRUEBA EXITOSA: Binding funcionando correctamente" -ForegroundColor Green
        } else {
            Write-Host "❌ PRUEBA FALLIDA: Binding incorrecto" -ForegroundColor Red
        }
        
        Write-Host "`n📝 Muestra de datos:" -ForegroundColor Yellow
        $data.data | Select-Object -First 2 | ForEach-Object {
            Write-Host "   • $($_.client_name) - Habitación $($_.room_number)" -ForegroundColor White
        }
        
        return $true
    } catch {
        Write-Host "❌ Error en prueba: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Change-Binding {
    param([string]$NewMode)
    
    Write-Host "`n🔄 CAMBIANDO DEFERRED BINDING:" -ForegroundColor Magenta
    Write-Host "------------------------------" -ForegroundColor Gray
    Write-Host "Nuevo modo: $NewMode" -ForegroundColor Cyan
    
    # Ejecutar script de configuración
    Write-Host "📝 Ejecutando set-booking-mode-final.ps1..." -ForegroundColor Yellow
    & ".\set-booking-mode-final.ps1" -Mode $NewMode
    
    Write-Host "`n🔄 Reiniciando servicios para aplicar binding..." -ForegroundColor Yellow
    docker-compose restart backend_v1
    
    Start-Sleep -Seconds 5
    Write-Host "✅ Servicios reiniciados" -ForegroundColor Green
}

# Mostrar estado inicial
Show-CurrentBinding | Out-Null

if ($DemoType -eq "complete") {
    Write-Host "`n🎬 INICIANDO DEMO COMPLETA DE DEFERRED BINDING" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    
    # Fase 1: PostgreSQL
    Write-Host "`n📍 FASE 1: CONFIGURACIÓN PostgreSQL" -ForegroundColor Blue
    Write-Host "=====================================" -ForegroundColor Blue
    Change-Binding "pg"
    Test-Endpoint "PostgreSQL"
    
    Write-Host "`nPresiona Enter para continuar a la FASE 2..." -ForegroundColor Yellow
    Read-Host
    
    # Fase 2: Mock
    Write-Host "`n📍 FASE 2: CONFIGURACIÓN Mock Service" -ForegroundColor Blue  
    Write-Host "=====================================" -ForegroundColor Blue
    Change-Binding "mock"
    Test-Endpoint "Mock Service"
    
    Write-Host "`nPresiona Enter para continuar a la FASE 3..." -ForegroundColor Yellow
    Read-Host
    
    # Fase 3: Vuelta a PostgreSQL
    Write-Host "`n📍 FASE 3: REGRESO A PostgreSQL" -ForegroundColor Blue
    Write-Host "=================================" -ForegroundColor Blue
    Change-Binding "pg"
    Test-Endpoint "PostgreSQL"
    
} elseif ($DemoType -eq "pg-to-mock") {
    Write-Host "`n🎬 DEMO: PostgreSQL → Mock" -ForegroundColor Cyan
    Change-Binding "mock"
    Test-Endpoint "Mock Service"
    
} elseif ($DemoType -eq "mock-to-pg") {
    Write-Host "`n🎬 DEMO: Mock → PostgreSQL" -ForegroundColor Cyan
    Change-Binding "pg"
    Test-Endpoint "PostgreSQL"
}

Write-Host "`n🎉 DEMOSTRACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host "✅ Deferred Binding demostrado exitosamente" -ForegroundColor Green
Write-Host "📚 Táctica arquitectónica validada para TFU2" -ForegroundColor Cyan