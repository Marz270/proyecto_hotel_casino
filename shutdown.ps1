# ===============================================
#     HOTEL-CASINO TFU2 - SHUTDOWN SCRIPT
# ===============================================

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "    HOTEL-CASINO TFU2 - SHUTDOWN SCRIPT" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan

Write-Host "`nDeteniendo todos los servicios del proyecto..." -ForegroundColor Green

# Detener servicios con docker-compose
Write-Host "Ejecutando docker-compose down..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

# Detener contenedores individuales si existen
Write-Host "`nDeteniendo contenedores individuales..." -ForegroundColor Yellow
$containers = @("hotel_api_v1", "hotel_api_v2", "hotel_casino_db", "hotel_nginx")

foreach ($container in $containers) {
    $containerExists = docker ps -a --filter "name=$container" --format "{{.Names}}" | Where-Object { $_ -eq $container }
    if ($containerExists) {
        Write-Host "Deteniendo $container..." -ForegroundColor Cyan
        docker stop $container | Out-Null
        docker rm $container | Out-Null
        Write-Host "✓ Contenedor $container eliminado" -ForegroundColor Green
    } else {
        Write-Host "- Contenedor $container no existe" -ForegroundColor Gray
    }
}

# Limpiar redes
Write-Host "`nLimpiando redes..." -ForegroundColor Yellow
$networkExists = docker network ls --filter "name=proyecto_hotel_casino_hotel-network" --format "{{.Name}}" | Where-Object { $_ -eq "proyecto_hotel_casino_hotel-network" }
if ($networkExists) {
    docker network rm proyecto_hotel_casino_hotel-network | Out-Null
    Write-Host "✓ Red eliminada" -ForegroundColor Green
} else {
    Write-Host "- Red no existe o ya fue eliminada" -ForegroundColor Gray
}

# Limpiar volúmenes
Write-Host "`nLimpiando volúmenes..." -ForegroundColor Yellow
$volumeExists = docker volume ls --filter "name=proyecto_hotel_casino_db_data" --format "{{.Name}}" | Where-Object { $_ -eq "proyecto_hotel_casino_db_data" }
if ($volumeExists) {
    docker volume rm proyecto_hotel_casino_db_data | Out-Null
    Write-Host "✓ Volumen eliminado" -ForegroundColor Green
} else {
    Write-Host "- Volumen no existe o ya fue eliminado" -ForegroundColor Gray
}

# Limpiar imágenes del proyecto (opcional)
$response = Read-Host "`n¿Quieres eliminar también las imágenes del proyecto? (y/N)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "Eliminando imágenes del proyecto..." -ForegroundColor Yellow
    $images = @("proyecto_hotel_casino-backend_v1", "proyecto_hotel_casino-backend_v2")
    
    foreach ($image in $images) {
        $imageExists = docker images --filter "reference=$image" --format "{{.Repository}}"
        if ($imageExists) {
            docker rmi $image | Out-Null
            Write-Host "✓ Imagen $image eliminada" -ForegroundColor Green
        } else {
            Write-Host "- Imagen $image no existe" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Imágenes del proyecto conservadas" -ForegroundColor Gray
}

Write-Host "`n✅ Shutdown completado" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Verificación final
Write-Host "`n📊 Estado final:" -ForegroundColor Magenta
Write-Host "Contenedores del proyecto:" -ForegroundColor Yellow
$remainingContainers = docker ps -a --filter "name=hotel_" --format "{{.Names}}"
if ($remainingContainers) {
    $remainingContainers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
} else {
    Write-Host "  ✓ Ningún contenedor del proyecto" -ForegroundColor Green
}

Write-Host "`nImágenes del proyecto:" -ForegroundColor Yellow
$remainingImages = docker images --filter "reference=proyecto_hotel_casino*" --format "{{.Repository}}:{{.Tag}}"
if ($remainingImages) {
    $remainingImages | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
} else {
    Write-Host "  ✓ Ninguna imagen del proyecto" -ForegroundColor Green
}

Write-Host "`n🎯 Shutdown script completado exitosamente" -ForegroundColor Green