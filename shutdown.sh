#!/bin/bash

echo "==============================================="
echo "    HOTEL-CASINO TFU2 - SHUTDOWN SCRIPT"
echo "==============================================="

echo "Deteniendo todos los servicios del proyecto..."

# Detener servicios con docker-compose
docker-compose down -v --remove-orphans

# Detener contenedores individuales si existen
echo "Deteniendo contenedores individuales..."
docker stop hotel_api_v1 hotel_api_v2 hotel_casino_db hotel_nginx 2>/dev/null || true
docker rm hotel_api_v1 hotel_api_v2 hotel_casino_db hotel_nginx 2>/dev/null || true

# Limpiar redes
echo "Limpiando redes..."
docker network rm proyecto_hotel_casino_hotel-network 2>/dev/null || true

# Limpiar volúmenes
echo "Limpiando volúmenes..."
docker volume rm proyecto_hotel_casino_db_data 2>/dev/null || true

# Limpiar imágenes del proyecto (opcional)
read -p "¿Quieres eliminar también las imágenes del proyecto? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Eliminando imágenes del proyecto..."
    docker rmi proyecto_hotel_casino-backend_v1 proyecto_hotel_casino-backend_v2 2>/dev/null || true
fi

echo "✅ Shutdown completado"
echo "==============================================="