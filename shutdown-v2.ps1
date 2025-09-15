# ===============================================
#     HOTEL-CASINO TFU2 - SHUTDOWN SCRIPT v2
# ===============================================

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    HOTEL-CASINO TFU2 - SHUTDOWN SCRIPT" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "`nDeteniendo todos los servicios del proyecto..." -ForegroundColor Green

# Detener servicios con docker-compose
Write-Host "`n🛑 Ejecutando docker-compose down..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# Verificar estado
Write-Host "`n📊 Verificando limpieza..." -ForegroundColor Green

$containers = docker ps -a --filter "name=hotel_" --format "{{.Names}}"
if ($containers) {
    Write-Host "⚠️  Contenedores restantes:" -ForegroundColor Yellow
    $containers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    
    # Forzar eliminación
    Write-Host "`n🔧 Eliminando contenedores restantes..." -ForegroundColor Yellow
    $containers | ForEach-Object { 
        docker stop $_ 2>$null
        docker rm $_ 2>$null
    }
} else {
    Write-Host "✅ Todos los contenedores eliminados" -ForegroundColor Green
}

$networks = docker network ls --filter "name=proyecto_hotel_casino" --format "{{.Name}}"
if ($networks) {
    Write-Host "⚠️  Redes restantes:" -ForegroundColor Yellow
    $networks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
} else {
    Write-Host "✅ Todas las redes eliminadas" -ForegroundColor Green
}

$volumes = docker volume ls --filter "name=proyecto_hotel_casino" --format "{{.Name}}"
if ($volumes) {
    Write-Host "⚠️  Volúmenes restantes:" -ForegroundColor Yellow
    $volumes | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
} else {
    Write-Host "✅ Todos los volúmenes eliminados" -ForegroundColor Green
}

# Preguntar por las imágenes
Write-Host "`n🐳 Gestión de imágenes Docker:" -ForegroundColor Magenta
$images = docker images --filter "reference=proyecto_hotel_casino*" --format "{{.Repository}}:{{.Tag}}"
if ($images) {
    Write-Host "Imágenes del proyecto encontradas:" -ForegroundColor Yellow
    $images | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
    
    $response = Read-Host "`n¿Quieres eliminar también las imágenes del proyecto? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "🗑️  Eliminando imágenes..." -ForegroundColor Yellow
        docker rmi $(docker images --filter "reference=proyecto_hotel_casino*" -q) 2>$null
        Write-Host "✅ Imágenes eliminadas" -ForegroundColor Green
    } else {
        Write-Host "📦 Imágenes conservadas para futuras ejecuciones" -ForegroundColor Gray
    }
} else {
    Write-Host "✅ No hay imágenes del proyecto" -ForegroundColor Green
}

Write-Host "`n🎯 ¡Shutdown completado exitosamente!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Estado final
Write-Host "`n📋 Estado final del sistema:" -ForegroundColor Magenta
Write-Host "Contenedores activos:" -ForegroundColor Yellow
$activeContainers = docker ps --format "{{.Names}}"
if ($activeContainers) {
    $activeContainers | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "  ✅ Ningún contenedor ejecutándose" -ForegroundColor Green
}

Write-Host "`n🔄 Para volver a levantar el proyecto:" -ForegroundColor Cyan
Write-Host "  .\deploy.ps1" -ForegroundColor White
Write-Host "`n===============================================" -ForegroundColor Cyan