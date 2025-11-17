# demo-valet-key.ps1
Write-Host "Demo Valet Key - Salto Hotel & Casino" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$API_BASE = "http://localhost:3000"

# Paso 1: Crear una reserva
Write-Host "Paso 1: Creando reserva de prueba..." -ForegroundColor Yellow
$booking = Invoke-RestMethod -Uri "$API_BASE/bookings" -Method POST `
    -ContentType "application/json" `
    -Body '{"client_name":"Martin Gonzales","room_number":105,"check_in":"2025-11-15","check_out":"2025-11-17","total_price":300.00}'

$bookingId = $booking.data.id
Write-Host "Reserva creada: ID = $bookingId" -ForegroundColor Green
Write-Host ""

# Paso 2: Solicitar token de upload
Write-Host "Paso 2: Solicitando token temporal para subir pasaporte..." -ForegroundColor Yellow
$tokenResponse = Invoke-RestMethod -Uri "$API_BASE/bookings/$bookingId/upload-token" -Method POST `
    -ContentType "application/json" `
    -Body '{"documentType":"passport"}'

Write-Host "Token generado:" -ForegroundColor Green
Write-Host "   URL: $($tokenResponse.data.uploadUrl)" -ForegroundColor Gray
Write-Host "   Expira: $($tokenResponse.data.expiresAt)" -ForegroundColor Gray
Write-Host "   Tipos permitidos: $($tokenResponse.data.allowedTypes -join ', ')" -ForegroundColor Gray
Write-Host ""

$token = $tokenResponse.data.token

# Paso 3: Usar el token para "subir" documento
Write-Host "Paso 3: Subiendo documento con el token..." -ForegroundColor Yellow
$uploadResponse = Invoke-RestMethod -Uri "$API_BASE/upload/$token" -Method PUT `
    -Headers @{"X-Filename" = "passport_juan_perez.pdf"}

Write-Host "Documento subido:" -ForegroundColor Green
Write-Host "   Archivo: $($uploadResponse.data.filename)" -ForegroundColor Gray
Write-Host "   Estado: $($uploadResponse.data.status)" -ForegroundColor Gray
Write-Host ""

# Paso 4: Intentar reusar el token (debe fallar)
Write-Host "Paso 4: Intentando reusar el token (debe fallar)..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$API_BASE/upload/$token" -Method PUT `
        -Headers @{"X-Filename" = "otro_archivo.pdf"}
    Write-Host "ERROR: Token fue reusado (no debería permitirse)" -ForegroundColor Red
} catch {
    Write-Host "Token rechazado correctamente (ya fue usado)" -ForegroundColor Green
}
Write-Host ""

# Paso 5: Verificar token expirado
Write-Host "Paso 5: Validacion de token..." -ForegroundColor Yellow
$validation = Invoke-RestMethod -Uri "$API_BASE/upload/$token/validate" -Method GET
$validationStatus = if ($validation.data.valid) { 'Válido' } else { 'Inválido' }
Write-Host "   Estado: $validationStatus" -ForegroundColor Gray
Write-Host "   Razon: $($validation.data.error)" -ForegroundColor Gray
Write-Host ""

# Resumen
Write-Host "Resumen del Patron Valet Key:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Backend NO maneja archivos sensibles" -ForegroundColor Green
Write-Host "Tokens temporales (15 min expiry)" -ForegroundColor Green
Write-Host "Uso unico (no reutilizables)" -ForegroundColor Green
Write-Host "Permisos especificos por documento" -ForegroundColor Green
Write-Host "Auditoria en base de datos" -ForegroundColor Green
Write-Host ""
Write-Host "Beneficios de Seguridad:" -ForegroundColor Cyan
Write-Host "   - Reduce superficie de ataque del backend" -ForegroundColor White
Write-Host "   - Previene acceso no autorizado" -ForegroundColor White
Write-Host "   - Cumple con regulaciones del casino" -ForegroundColor White
Write-Host "   - Facilita auditorias de seguridad" -ForegroundColor White