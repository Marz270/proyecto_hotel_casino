# Scripts de Demostracion TFU3
# Sistema de Reservas Salto Hotel & Casino

Write-Host "Iniciando Demo Completa TFU3 - Salto Hotel & Casino" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Variables de configuracion
$API_BASE = "http://localhost:3000"
$FRONTEND_URL = "http://localhost:4200"

# Funcion para hacer llamadas a la API
function Invoke-ApiCall {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Body = @{}
    )
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            Headers = @{
                "Content-Type" = "application/json"
            }
        }
        
        if ($Method -ne "GET" -and $Body.Count -gt 0) {
            $params.Body = $Body | ConvertTo-Json
        }
        
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        Write-Host "Error en API call: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Funcion para iniciar los servicios con Docker Compose
function Start-Services {
    Write-Host "Iniciando servicios con Docker Compose..." -ForegroundColor Yellow
    
    try {
        # Verificar si Docker esta corriendo
        docker --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Docker no esta disponible" -ForegroundColor Red
            return $false
        }
        
        # Detener servicios existentes
        Write-Host "Deteniendo servicios existentes..." -ForegroundColor Gray
        docker-compose down 2>$null
        
        # Iniciar servicios
        Write-Host "Iniciando servicios..." -ForegroundColor Gray
        $process = Start-Process -FilePath "docker-compose" -ArgumentList "up", "-d" -PassThru -WindowStyle Hidden
        $process.WaitForExit(30000)  # Esperar hasta 30 segundos
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Servicios iniciados correctamente" -ForegroundColor Green
            Start-Sleep -Seconds 10  # Dar tiempo para que los servicios se levanten
            return $true
        } else {
            Write-Host "Error al iniciar servicios" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error al iniciar servicios: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "1. Verificando Estado del Sistema" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

# Verificar si los servicios estan corriendo, si no, intentar iniciarlos
$backendReady = $false
$frontendReady = $false

# Verificar backend
try {
    $health = Invoke-ApiCall -Url "$API_BASE/"
    if ($health -and $health.success) {
        Write-Host "Backend API: CONECTADO" -ForegroundColor Green
        Write-Host "   Version: $($health.data.version)" -ForegroundColor Gray
        Write-Host "   Modo: $($health.data.booking_mode)" -ForegroundColor Gray
        $backendReady = $true
    }
}
catch {
    Write-Host "Backend API: NO DISPONIBLE" -ForegroundColor Red
}

# Verificar frontend
try {
    $frontendResponse = Invoke-WebRequest -Uri $FRONTEND_URL -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Frontend Angular: CONECTADO" -ForegroundColor Green
    $frontendReady = $true
}
catch {
    Write-Host "Frontend Angular: NO DISPONIBLE" -ForegroundColor Red
    Write-Host "   El frontend estara disponible una vez que Angular compile" -ForegroundColor Gray
}

# Si los servicios no estan listos, intentar iniciarlos
if (-not $backendReady -or -not $frontendReady) {
    Write-Host ""
    Write-Host "Intentando iniciar servicios..." -ForegroundColor Yellow
    
    if (Start-Services) {
        # Reintentar verificacion
        Start-Sleep -Seconds 15
        
        try {
            $health = Invoke-ApiCall -Url "$API_BASE/"
            if ($health -and $health.success) {
                Write-Host "Backend API: CONECTADO (reinicio exitoso)" -ForegroundColor Green
                $backendReady = $true
            }
        }
        catch {
            Write-Host "Backend API: AUN NO DISPONIBLE" -ForegroundColor Red
        }
        
        Write-Host "Frontend Angular: INICIANDO..." -ForegroundColor Yellow
        Write-Host "   URL: $FRONTEND_URL (disponible en ~2-3 minutos)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "2. Demo - Consulta de Habitaciones Disponibles" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

$rooms = Invoke-ApiCall -Url "$API_BASE/rooms"
if ($rooms -and $rooms.data) {
    Write-Host "Total de habitaciones: $($rooms.count)" -ForegroundColor Green
    
    foreach ($room in $rooms.data) {
        $status = if ($room.available) { "DISPONIBLE" } else { "OCUPADA" }
        $statusColor = if ($room.available) { "Green" } else { "Red" }
        
        Write-Host "   Habitacion $($room.room_number) - $($room.room_type)" -ForegroundColor Cyan
        Write-Host "      Precio: $($room.price_per_night)/noche" -ForegroundColor Gray
        Write-Host "      Huespedes: $($room.max_guests)" -ForegroundColor Gray
        Write-Host "      Estado: $status" -ForegroundColor $statusColor
        Write-Host ""
    }
} else {
    Write-Host "No se pudieron obtener las habitaciones" -ForegroundColor Red
    if ($rooms -and $rooms.error) {
        Write-Host "   Error: $($rooms.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Demo - Crear Nueva Reserva" -ForegroundColor Yellow
Write-Host "-------------------------------------------"
Write-Host "Creando reserva de ejemplo..." -ForegroundColor Cyan

$reservationData = @{
    client_name = "Demo TFU3 - Juan Perez"
    client_email = "juan.perez@email.com"
    room_number = "102"
    check_in = "2025-12-15"
    check_out = "2025-12-17"
    total_price = 300.00
}

Write-Host "   Cliente: $($reservationData.client_name)" -ForegroundColor Gray
Write-Host "   Habitacion: $($reservationData.room_number)" -ForegroundColor Gray
Write-Host "   Check-in: $($reservationData.check_in)" -ForegroundColor Gray
Write-Host "   Check-out: $($reservationData.check_out)" -ForegroundColor Gray
Write-Host "   Total: $($reservationData.total_price)" -ForegroundColor Gray

$newReservation = Invoke-ApiCall -Url "$API_BASE/reservations" -Method "POST" -Body $reservationData
if ($newReservation -and $newReservation.success) {
    Write-Host "Reserva creada exitosamente!" -ForegroundColor Green
    Write-Host "   ID de reserva: $($newReservation.data.id)" -ForegroundColor Cyan
    $reservationId = $newReservation.data.id
} else {
    Write-Host "Error al crear reserva" -ForegroundColor Red
    if ($newReservation -and $newReservation.error) {
        Write-Host "   Error: $($newReservation.error)" -ForegroundColor Red
    }
    if ($newReservation -and $newReservation.details) {
        Write-Host "   Detalles: $($newReservation.details)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "4. Demo - Listar Todas las Reservas" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

$reservations = Invoke-ApiCall -Url "$API_BASE/bookings"
if ($reservations -and $reservations.data) {
    Write-Host "Total de reservas: $($reservations.count)" -ForegroundColor Green
    Write-Host "Fuente de datos: $($reservations.source)" -ForegroundColor Cyan
    
    foreach ($reservation in $reservations.data) {
        Write-Host "   Reserva #$($reservation.id)" -ForegroundColor Cyan
        Write-Host "      Cliente: $($reservation.client_name)" -ForegroundColor Gray
        Write-Host "      Habitacion: $($reservation.room_number)" -ForegroundColor Gray
        Write-Host "      Check-in: $($reservation.check_in)" -ForegroundColor Gray
        Write-Host "      Check-out: $($reservation.check_out)" -ForegroundColor Gray
        Write-Host "      Total: $($reservation.total_price)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host ""
Write-Host "5. Demo - Simulacion de Pago" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

if ($reservationId) {
    Write-Host "Procesando pago para reserva #$reservationId..." -ForegroundColor Cyan
    
    $paymentData = @{
        reservation_id = $reservationId
        amount = 300.00
        payment_method = "credit_card"
        card_number = "**** **** **** 1234"
    }
    
    $payment = Invoke-ApiCall -Url "$API_BASE/payments" -Method "POST" -Body $paymentData
    if ($payment -and $payment.success) {
        Write-Host "Pago procesado exitosamente!" -ForegroundColor Green
        Write-Host "   ID de transaccion: $($payment.data.transaction_id)" -ForegroundColor Cyan
        Write-Host "   Estado: $($payment.data.status)" -ForegroundColor Green
    } else {
        Write-Host "Error al procesar pago" -ForegroundColor Red
        if ($payment -and $payment.error) {
            Write-Host "   Error: $($payment.error)" -ForegroundColor Red
        }
    }
    }
}

Write-Host ""
Write-Host "6. Demo - Reportes Administrativos" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

$reports = Invoke-ApiCall -Url "$API_BASE/reports"
if ($reports -and $reports.data) {
    Write-Host "Reportes generados en: $($reports.generated_at)" -ForegroundColor Green
    
    # Resumen general
    if ($reports.data.summary) {
        $summary = $reports.data.summary
        Write-Host ""
        Write-Host "RESUMEN GENERAL:" -ForegroundColor Cyan
        Write-Host "   Total de reservas: $($summary.total_bookings)" -ForegroundColor Gray
        Write-Host "   Total de habitaciones: $($summary.total_rooms)" -ForegroundColor Gray
        Write-Host "   Valor promedio por reserva: $([math]::Round($summary.avg_booking_value, 2))" -ForegroundColor Gray
        Write-Host "   Reservas ultimos 30 dias: $($summary.bookings_last_month)" -ForegroundColor Gray
    }
    
    # Reporte de ocupacion
    if ($reports.data.occupancy) {
        $occupancy = $reports.data.occupancy
        Write-Host ""
        Write-Host "OCUPACION ACTUAL:" -ForegroundColor Cyan
        Write-Host "   Habitaciones totales: $($occupancy.total_rooms)" -ForegroundColor Gray
        Write-Host "   Habitaciones ocupadas: $($occupancy.occupied_rooms)" -ForegroundColor Gray
        Write-Host "   Tasa de ocupacion: $($occupancy.occupancy_rate)%" -ForegroundColor Gray
    }
    
    # Ingresos mensuales
    if ($reports.data.revenue) {
        Write-Host ""
        Write-Host "INGRESOS POR MES:" -ForegroundColor Cyan
        foreach ($revenue in $reports.data.revenue) {
            $month = [datetime]$revenue.month
            Write-Host "   $($month.ToString('MMMM yyyy')): $($revenue.total_revenue) USD - $($revenue.total_bookings) reservas" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "No se pudieron obtener los reportes" -ForegroundColor Red
    if ($reports -and $reports.error) {
        Write-Host "   Error: $($reports.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "7. Demo - Tacticas de Arquitectura" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host "DIFERIR BINDING (Cambio de implementacion):" -ForegroundColor Cyan
Write-Host "   1. Patron Factory para BookingService" -ForegroundColor White
Write-Host "   2. Configuracion externa via variables de entorno" -ForegroundColor White
Write-Host "   3. Inyeccion de dependencias en tiempo de ejecucion" -ForegroundColor White
Write-Host ""

Write-Host "ROLLBACK (Facilidad de despliegue):" -ForegroundColor Cyan
Write-Host "   1. Contenedorizacion con Docker" -ForegroundColor White
Write-Host "   2. Versionado de imagenes" -ForegroundColor White
Write-Host "   3. Scripts automatizados de despliegue y rollback" -ForegroundColor White
Write-Host ""

Write-Host "8. Demo - Escalado Horizontal" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host "Verificar instancias en ejecucion:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null

Write-Host ""
Write-Host "Servicios activos:" -ForegroundColor Cyan
Write-Host "API Backend: $API_BASE" -ForegroundColor Green
Write-Host "Frontend Angular: $FRONTEND_URL" -ForegroundColor Green
Write-Host "Load Balancer (Nginx): http://localhost:8080" -ForegroundColor Green
Write-Host "Base de datos PostgreSQL: localhost:5432" -ForegroundColor Green

Write-Host ""
Write-Host "Endpoints disponibles:" -ForegroundColor Cyan
Write-Host "   GET    /                 - Info de la API" -ForegroundColor Gray
Write-Host "   GET    /rooms            - Consultar habitaciones" -ForegroundColor Gray
Write-Host "   GET    /bookings         - Listar reservas" -ForegroundColor Gray
Write-Host "   POST   /reservations     - Crear reserva" -ForegroundColor Gray
Write-Host "   POST   /payments         - Procesar pago" -ForegroundColor Gray
Write-Host "   GET    /reports          - Reportes administrativos" -ForegroundColor Gray
Write-Host "   DELETE /bookings/:id     - Eliminar reserva" -ForegroundColor Gray

Write-Host ""
Write-Host "DEMO COMPLETADA EXITOSAMENTE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

Write-Host ""
Write-Host "Proximos pasos para la presentacion:" -ForegroundColor Cyan
Write-Host "1. Abrir frontend en: $FRONTEND_URL" -ForegroundColor White
Write-Host "2. Probar todas las funcionalidades en las 3 pestanas" -ForegroundColor White
Write-Host "3. Demostrar rollback con .\deploy-v2.ps1 y .\rollback.ps1" -ForegroundColor White
Write-Host "4. Mostrar reportes y estadisticas en tiempo real" -ForegroundColor White
Write-Host "5. Explicar arquitectura de componentes del documento TFU3" -ForegroundColor White

Write-Host ""
Write-Host "TFU3 - Analisis y Diseno de Aplicaciones II - 2025" -ForegroundColor Magenta
Write-Host ""

# Abrir automaticamente el frontend en el navegador
if ($frontendReady -or $backendReady) {
    Write-Host "Abriendo frontend en el navegador..." -ForegroundColor Yellow
    Start-Process $FRONTEND_URL
}