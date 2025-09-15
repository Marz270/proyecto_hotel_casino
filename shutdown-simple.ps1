# Shutdown Simple - TFU2 Hotel Casino
Write-Host "=== SHUTDOWN TFU2 ===" -ForegroundColor Green

Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans

Write-Host "Verificando..." -ForegroundColor Yellow
$containers = docker ps -a --filter "name=hotel_" --format "{{.Names}}"
if ($containers) {
    Write-Host "Eliminando contenedores restantes..." -ForegroundColor Red
    docker stop hotel_api_v1 hotel_api_v2 hotel_casino_db hotel_nginx 2>$null
    docker rm hotel_api_v1 hotel_api_v2 hotel_casino_db hotel_nginx 2>$null
}

Write-Host "Estado final:" -ForegroundColor Green
docker ps
Write-Host "Shutdown completado!" -ForegroundColor Green