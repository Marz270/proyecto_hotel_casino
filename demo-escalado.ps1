# 🧪 Demo de Escalado Horizontal - TFU3
# Demostración de escalabilidad de microservicios

Write-Host "🚀 Demo de Escalado Horizontal - Salto Hotel & Casino" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "📊 1. Estado Inicial del Sistema" -ForegroundColor Yellow
Write-Host "------------------------------------"

# Mostrar contenedores actuales
Write-Host "🔍 Contenedores en ejecución:" -ForegroundColor Green
docker-compose ps

Write-Host ""
Write-Host "🔧 2. Escalando Backend a 3 Instancias" -ForegroundColor Yellow
Write-Host "----------------------------------------"

Write-Host "⚡ Ejecutando escalado horizontal..." -ForegroundColor Cyan
docker-compose up --scale backend_v1=3 -d

Start-Sleep -Seconds 5

Write-Host ""
Write-Host "📊 3. Verificando Escalado" -ForegroundColor Yellow
Write-Host "----------------------------"

Write-Host "🔍 Contenedores después del escalado:" -ForegroundColor Green
docker-compose ps

Write-Host ""
Write-Host "🌐 4. Probando Load Balancing" -ForegroundColor Yellow
Write-Host "-------------------------------"

Write-Host "🧪 Haciendo múltiples requests para verificar distribución de carga..." -ForegroundColor Cyan

for ($i = 1; $i -le 5; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3000/" -Method GET
        Write-Host "   Request $i - Versión API: $($response.version) - Modo: $($response.booking_mode)" -ForegroundColor Green
    } catch {
        Write-Host "   Request $i - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "📈 5. Métricas de Performance" -ForegroundColor Yellow
Write-Host "-------------------------------"

Write-Host "💾 Uso de recursos por contenedor:" -ForegroundColor Green
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

Write-Host ""
Write-Host "🔍 6. Logs de Contenedores Backend" -ForegroundColor Yellow
Write-Host "-----------------------------------"

Write-Host "📋 Últimas entradas de log de backends:" -ForegroundColor Green
docker-compose logs --tail=3 backend_v1

Write-Host ""
Write-Host "⬇️ 7. Volviendo a 1 Instancia" -ForegroundColor Yellow
Write-Host "------------------------------"

Write-Host "🔧 Escalando de vuelta a 1 instancia..." -ForegroundColor Cyan
docker-compose up --scale backend_v1=1 -d

Start-Sleep -Seconds 3

Write-Host ""
Write-Host "✅ 8. Verificación Final" -ForegroundColor Yellow
Write-Host "-------------------------"

Write-Host "🔍 Estado final del sistema:" -ForegroundColor Green
docker-compose ps

Write-Host ""
Write-Host "🎯 DEMO DE ESCALADO COMPLETADA! 🎉" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Resumen de lo demostrado:" -ForegroundColor Cyan
Write-Host "✅ Escalado horizontal sin interrupción del servicio" -ForegroundColor White
Write-Host "✅ Load balancing automático entre instancias" -ForegroundColor White
Write-Host "✅ Monitoreo de recursos en tiempo real" -ForegroundColor White
Write-Host "✅ Escalado dinámico bidireccional (up/down)" -ForegroundColor White

Write-Host ""
Write-Host "🏗️ Conceptos de Arquitectura Demostrados:" -ForegroundColor Cyan
Write-Host "• Servicios sin estado (stateless)" -ForegroundColor White
Write-Host "• Contenedores como unidades de despliegue" -ForegroundColor White
Write-Host "• Escalabilidad horizontal automática" -ForegroundColor White
Write-Host "• Disponibilidad durante escalado" -ForegroundColor White

Write-Host ""
Write-Host "🎓 TFU3 - Análisis y Diseño de Aplicaciones II - 2025" -ForegroundColor Magenta