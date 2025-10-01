# Scripts de Demostracion TFU3
# Sistema de Reservas Salto Hotel & Casino

Write-Host "Iniciando Demo Completa TFU3 - Salto Hotel & Casino" -ForegroundColor Cyan                 Write-H        Write-Host "   Habitaciones totales: $($occupancy.total_rooms)" -ForegroundColor Gray
        Write-Host "   Habitaciones ocupadas: $($occupancy.occupied_rooms)" -ForegroundColor Gray
        Write-Host "   Tasa de ocupacion: $($occupancy.occupancy_rate)%" -ForegroundColor Gray "RESUMEN GENERAL:" -ForegroundColor Cyan
        Write-Host "   Total de reservas: $($summary.total_reservations)" -ForegroundColor Gray
        Write-Host "   Total de habitaciones: $($summary.total_rooms)" -ForegroundColor Gray
        Write-Host "   Valor promedio por reserva: `$$([math]::Round($summary.avg_booking_value, 2))" -ForegroundColor Grayrite-H        Write-Host "   Habitaciones totales: $($occupancy.total_rooms)" -ForegroundColor Gray
        Write-Host "   Habitaciones ocupadas: $($occupancy.occupied_rooms)" -ForegroundColor Gray
        Write-Host "   Tasa de ocupacion: $($occupancy.occupancy_rate)%" -ForegroundColor Gray "RESUMEN GENERAL:" -ForegroundColor Cyan
        Write-Host "   Total de reservas: $($summary.total_reservations)" -ForegroundColor Gray
        Write-Host "   Total de habitaciones: $($summary.total_rooms)" -ForegroundColor Gray
        Write-Host "   Valor promedio por reserva: `$$([math]::Round($summary.avg_booking_value, 2))" -ForegroundColor GrayWrite-        Write-Host "   Habitaciones totales: $($occupancy.total_rooms)" -ForegroundColor Gray
        Write-Host "   Habitaciones ocupadas: $($occupancy.occupied_rooms)" -ForegroundColor Gray
        Write-Host "   Tasa de ocupacion: $($occupancy.occupancy_rate)%" -ForegroundColor Grayt "RESUMEN GENERAL:" -ForegroundColor Cyan
        Write-Host "   Total de reservas: $($summary.total_reservations)" -ForegroundColor Gray
        Write-Host "   Total de habitaciones: $($summary.total_rooms)" -ForegroundColor Gray
        Write-Host "   Valor promedio por reserva: `$$([math]::Round($summary.avg_booking_value, 2))" -ForegroundColor Grayite-Host "================================================================" -ForegroundColor Cyan

# Variables de configuración
$API_BASE = "http://localhost:3000"
$FRONTEND_URL = "http://localhost:4200"

# Funcion para hacer peticiones HTTP
function Invoke-ApiCall {
    param(
        [string]$Method = "GET",
        [string]$Url,
        [string]$Body = $null,
        [hashtable]$Headers = @{"Content-Type" = "application/json"}
    )
    
    try {
        if ($Body) {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $Body -Headers $Headers
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $Headers
        }
        return $response
    } catch {
        Write-Host "Error en API call: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host ""
Write-Host "1. Verificando Estado del Sistema" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

# Verificar API Backend
try {
    $apiInfo = Invoke-ApiCall -Url "$API_BASE/"
    if ($apiInfo) {
        Write-Host "Backend API: CONECTADO" -ForegroundColor Green
        Write-Host "   Version: $($apiInfo.version)" -ForegroundColor Gray
        Write-Host "   Modo: $($apiInfo.booking_mode)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Backend API: DESCONECTADO" -ForegroundColor Red
    Write-Host "   Asegurate de ejecutar: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

# Verificar Frontend
try {
    Invoke-WebRequest -Uri $FRONTEND_URL -Method Head -TimeoutSec 5 | Out-Null
    Write-Host "Frontend Angular: DISPONIBLE en $FRONTEND_URL" -ForegroundColor Green
} catch {
    Write-Host "Frontend Angular: NO DISPONIBLE" -ForegroundColor Yellow
    Write-Host "   El frontend estara disponible una vez que Angular compile" -ForegroundColor Gray
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
        Write-Host "      Precio: `$$($room.price_per_night)/noche" -ForegroundColor Gray
        Write-Host "      Huespedes: $($room.max_guests)" -ForegroundColor Gray
        Write-Host "      Estado: $status" -ForegroundColor $statusColor
        Write-Host ""
    }
}

Write-Host "3. Demo - Crear Nueva Reserva" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

# Datos de ejemplo para nueva reserva
$newReservation = @{
    client_name = "Demo TFU3 - Juan Pérez"
    room_number = 102
    check_in = "2025-12-15"
    check_out = "2025-12-17"
    total_price = 300.00
} | ConvertTo-Json

Write-Host "Creando reserva de ejemplo..." -ForegroundColor Cyan
Write-Host "   Cliente: Demo TFU3 - Juan Pérez" -ForegroundColor Gray
Write-Host "   Habitación: 102" -ForegroundColor Gray
Write-Host "   Check-in: 2025-12-15" -ForegroundColor Gray
Write-Host "   Check-out: 2025-12-17" -ForegroundColor Gray
Write-Host "   Total: `$300.00" -ForegroundColor Gray

$createResult = Invoke-ApiCall -Method "POST" -Url "$API_BASE/reservations" -Body $newReservation

if ($createResult -and $createResult.success) {
    Write-Host "Reserva creada exitosamente!" -ForegroundColor Green
    Write-Host "   ID de reserva: $($createResult.data.id)" -ForegroundColor Gray
    $reservationId = $createResult.data.id
} else {
    Write-Host "Error al crear reserva" -ForegroundColor Red
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
        Write-Host "      👤 Cliente: $($reservation.client_name)" -ForegroundColor Gray
        Write-Host "      Habitacion: $($reservation.room_number)" -ForegroundColor Gray
        Write-Host "      Check-in: $($reservation.check_in)" -ForegroundColor Gray
        Write-Host "      Check-out: $($reservation.check_out)" -ForegroundColor Gray
        Write-Host "      Total: `$$($reservation.total_price)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "5. Demo - Simulacion de Pago" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

if ($reservationId) {
    $paymentData = @{
        reservation_id = $reservationId
        amount = 300.00
        payment_method = "credit_card"
    } | ConvertTo-Json
    
    Write-Host "Procesando pago para reserva #$reservationId..." -ForegroundColor Cyan
    
    $paymentResult = Invoke-ApiCall -Method "POST" -Url "$API_BASE/payments" -Body $paymentData
    
    if ($paymentResult -and $paymentResult.success) {
        Write-Host "Pago procesado exitosamente!" -ForegroundColor Green
        Write-Host "   ID de transacción: $($paymentResult.data.transaction_id)" -ForegroundColor Gray
        Write-Host "   Estado: $($paymentResult.data.status)" -ForegroundColor Gray
        Write-Host "   Método: $($paymentResult.data.payment_method)" -ForegroundColor Gray
    } else {
        Write-Host "Error al procesar pago" -ForegroundColor Red
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
        Write-Host "   Valor promedio por reserva: `$$([math]::Round($summary.avg_booking_value, 2))" -ForegroundColor Gray
        Write-Host "   Reservas ultimos 30 dias: $($summary.bookings_last_month)" -ForegroundColor Gray
    }
    
    # Reporte de ocupación
    if ($reports.data.occupancy) {
        $occupancy = $reports.data.occupancy
        Write-Host ""
        Write-Host "OCUPACION ACTUAL:" -ForegroundColor Cyan
        Write-Host "   Habitaciones totales: $($occupancy.total_rooms)" -ForegroundColor Gray
        Write-Host "   Habitaciones ocupadas: $($occupancy.occupied_rooms)" -ForegroundColor Gray
        Write-Host "   Tasa de ocupacion: $($occupancy.occupancy_rate)%" -ForegroundColor Gray
    }
    
    # Reporte de ingresos
    if ($reports.data.revenue -and $reports.data.revenue.Count -gt 0) {
        Write-Host ""
        Write-Host "INGRESOS POR MES:" -ForegroundColor Cyan
        foreach ($revenue in $reports.data.revenue) {
            $month = [datetime]$revenue.month
            Write-Host "   $($month.ToString('MMMM yyyy')): $($revenue.total_revenue) USD - $($revenue.total_bookings) reservas" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "7. Demo - Tacticas de Arquitectura" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host "🔗 DIFERIR BINDING (Cambio de implementación):" -ForegroundColor Cyan
Write-Host "   Actual: $($apiInfo.booking_mode)" -ForegroundColor Gray
Write-Host "   Para cambiar a modo Mock: " -ForegroundColor Gray
Write-Host "   1. Editar archivo .env: BOOKING_MODE=mock" -ForegroundColor Yellow
Write-Host "   2. Ejecutar: docker-compose restart backend_v1" -ForegroundColor Yellow
Write-Host "   3. La API cambiará de PostgreSQL a datos simulados" -ForegroundColor Yellow

Write-Host ""
Write-Host "ROLLBACK (Facilidad de despliegue):" -ForegroundColor Cyan
Write-Host "   Para demostrar rollback:" -ForegroundColor Gray
Write-Host "   1. Desplegar v2: .\deploy-v2.ps1" -ForegroundColor Yellow
Write-Host "   2. Probar nueva versión en puerto 3001" -ForegroundColor Yellow
Write-Host "   3. Ejecutar rollback: .\rollback.ps1" -ForegroundColor Yellow
Write-Host "   4. Sistema vuelve a v1 sin pérdida de datos" -ForegroundColor Yellow

Write-Host ""
Write-Host "8. Demo - Escalado Horizontal" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host "🚀 Para escalar horizontalmente el backend:" -ForegroundColor Cyan
Write-Host "   docker-compose up --scale backend_v1=3 -d" -ForegroundColor Yellow
Write-Host ""
Write-Host "Verificar instancias en ejecucion:" -ForegroundColor Cyan
Write-Host "   docker-compose ps" -ForegroundColor Yellow

Write-Host ""
Write-Host "🌐 9. Acceso a Interfaces" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host "Frontend Angular: $FRONTEND_URL" -ForegroundColor Green
Write-Host "API Backend: $API_BASE" -ForegroundColor Green
Write-Host "Load Balancer (Nginx): http://localhost:8080" -ForegroundColor Green
Write-Host "Base de datos PostgreSQL: localhost:5432" -ForegroundColor Green

Write-Host ""
Write-Host "📚 10. Colección Postman" -ForegroundColor Yellow
Write-Host "-------------------------------------------"

Write-Host "📄 Importar en Postman:" -ForegroundColor Cyan
Write-Host "   Hotel-Casino-API-Fixed.postman_collection.json" -ForegroundColor Yellow
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
Write-Host "TFU3 - Analisis y Diseno de Aplicaciones 2 - 2025" -ForegroundColor Magenta
Write-Host ""