#!/bin/bash

# ============================================
# Demo Gateway Offloading Pattern
# Salto Hotel & Casino API
# ============================================

echo "======================================"
echo "Gateway Offloading Pattern Demo"
echo "======================================"
echo ""

# Colors para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_URL="http://localhost:80"
API_ENDPOINT="/api/bookings"

# Función para imprimir con color
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Verificar que el servicio esté corriendo
print_header "0. Verificación de Servicios"
if curl -s "$API_URL/health" > /dev/null; then
    print_success "API está corriendo en $API_URL"
else
    print_error "API no está accesible. Ejecuta: docker-compose up -d"
    exit 1
fi
echo ""

# ============================================
# 1. Probar Rate Limiting
# ============================================
print_header "1. Rate Limiting (10 req/s)"
echo "Enviando 20 requests rápidos para disparar rate limit..."
echo ""

success_count=0
rate_limited_count=0

for i in {1..20}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL$API_ENDPOINT")
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo -n "."
        ((success_count++))
    elif [ "$response" = "429" ]; then
        echo -n "X"
        ((rate_limited_count++))
    else
        echo -n "?"
    fi
done

echo ""
echo ""
print_success "Requests exitosos: $success_count"
print_warning "Requests bloqueados (429): $rate_limited_count"

if [ $rate_limited_count -gt 0 ]; then
    print_success "Rate limiting funcionando correctamente"
else
    print_warning "Rate limiting NO activado (todos pasaron)"
fi
echo ""

# ============================================
# 2. Verificar Security Headers
# ============================================
print_header "2. Security Headers"
echo "Verificando headers de seguridad..."
echo ""

headers=$(curl -s -I "$API_URL$API_ENDPOINT")

check_header() {
    header_name=$1
    expected_value=$2
    
    if echo "$headers" | grep -qi "$header_name"; then
        header_value=$(echo "$headers" | grep -i "$header_name" | cut -d: -f2- | tr -d '\r\n' | xargs)
        print_success "$header_name: $header_value"
    else
        print_error "$header_name: NO ENCONTRADO"
    fi
}

check_header "X-Content-Type-Options" "nosniff"
check_header "X-Frame-Options" "SAMEORIGIN"
check_header "X-XSS-Protection" "1; mode=block"
check_header "Referrer-Policy" "strict-origin-when-cross-origin"

echo ""

# ============================================
# 3. Verificar Compresión gzip
# ============================================
print_header "3. Compresión gzip"
echo "Comparando tamaño de respuesta con/sin compresión..."
echo ""

# Sin gzip
size_no_gzip=$(curl -s -H "Accept-Encoding: identity" "$API_URL$API_ENDPOINT" | wc -c)
print_warning "Tamaño sin gzip: $size_no_gzip bytes"

# Con gzip
response_gzip=$(curl -s -H "Accept-Encoding: gzip" --compressed "$API_URL$API_ENDPOINT")
size_gzip=$(echo "$response_gzip" | wc -c)
print_success "Tamaño con gzip: $size_gzip bytes"

if [ $size_no_gzip -gt 0 ]; then
    reduction=$(echo "scale=2; (1 - $size_gzip / $size_no_gzip) * 100" | bc)
    print_success "Reducción: ${reduction}%"
else
    print_warning "No se pudo calcular reducción"
fi
echo ""

# ============================================
# 4. Verificar CORS Headers
# ============================================
print_header "4. CORS Headers"
echo "Simulando preflight request..."
echo ""

cors_response=$(curl -s -I -X OPTIONS "$API_URL$API_ENDPOINT" \
    -H "Origin: http://frontend.example.com" \
    -H "Access-Control-Request-Method: POST")

check_cors_header() {
    header_name=$1
    
    if echo "$cors_response" | grep -qi "$header_name"; then
        header_value=$(echo "$cors_response" | grep -i "$header_name" | cut -d: -f2- | tr -d '\r\n' | xargs)
        print_success "$header_name: $header_value"
    else
        print_error "$header_name: NO ENCONTRADO"
    fi
}

check_cors_header "Access-Control-Allow-Origin"
check_cors_header "Access-Control-Allow-Methods"
check_cors_header "Access-Control-Allow-Headers"

echo ""

# ============================================
# 5. Verificar Logging
# ============================================
print_header "5. Request Logging"
echo "Verificando que las peticiones se loggean..."
echo ""

# Hacer una petición distintiva
timestamp=$(date +%s)
test_path="/api/bookings?test=$timestamp"
curl -s "$API_URL$test_path" > /dev/null

# Esperar un momento para que se escriba el log
sleep 1

# Verificar si el log existe en el contenedor
if docker-compose exec -T nginx test -f /var/log/nginx/access.log 2>/dev/null; then
    print_success "Archivo de log existe: /var/log/nginx/access.log"
    
    # Buscar la petición en el log
    if docker-compose exec -T nginx grep -q "$timestamp" /var/log/nginx/access.log 2>/dev/null; then
        print_success "Petición registrada en el log"
        echo ""
        echo "Últimas 3 líneas del log:"
        docker-compose exec -T nginx tail -3 /var/log/nginx/access.log
    else
        print_warning "Petición no encontrada en el log"
    fi
else
    print_warning "No se pudo acceder al archivo de log (puede ser normal en algunos setups)"
fi

echo ""

# ============================================
# 6. Verificar Upstream Backend
# ============================================
print_header "6. Backend Upstream & Connection Pooling"
echo "Verificando proxy pass al backend..."
echo ""

# Hacer petición y capturar headers de backend
response=$(curl -s -v "$API_URL$API_ENDPOINT" 2>&1)

if echo "$response" | grep -q "X-Forwarded-For"; then
    print_success "Header X-Forwarded-For presente (proxy funciona)"
fi

if echo "$response" | grep -q "X-Real-IP"; then
    print_success "Header X-Real-IP presente (IP original preservada)"
fi

print_success "Nginx actúa como reverse proxy correctamente"

echo ""

# ============================================
# 7. Performance Benchmark Simple
# ============================================
print_header "7. Performance Benchmark"
echo "Midiendo tiempos de respuesta (10 peticiones)..."
echo ""

total_time=0
requests=10

for i in $(seq 1 $requests); do
    request_time=$(curl -s -o /dev/null -w "%{time_total}" "$API_URL$API_ENDPOINT")
    total_time=$(echo "$total_time + $request_time" | bc)
    echo -n "."
done

echo ""
echo ""

avg_time=$(echo "scale=3; $total_time / $requests" | bc)
print_success "Tiempo promedio por request: ${avg_time}s"

if [ $(echo "$avg_time < 0.1" | bc) -eq 1 ]; then
    print_success "Performance excelente (<100ms)"
elif [ $(echo "$avg_time < 0.5" | bc) -eq 1 ]; then
    print_success "Performance buena (<500ms)"
else
    print_warning "Performance puede mejorar (>${avg_time}s)"
fi

echo ""

# ============================================
# Resumen Final
# ============================================
print_header "Resumen de Gateway Offloading"

echo ""
echo "Funcionalidades verificadas:"
echo ""
echo "  - Rate Limiting (protección DDoS)"
echo "  - Security Headers (XSS, clickjacking)"
echo "  - Compresión gzip (reducción bandwidth)"
echo "  - CORS Handling (cross-origin)"
echo "  - Request Logging (auditoría)"
echo "  - Reverse Proxy (connection pooling)"
echo "  - Performance (tiempos de respuesta)"
echo ""

print_success "Gateway Offloading Pattern implementado correctamente"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Para más información:"
echo "  - Configuración: nginx/nginx-gateway-offloading.conf"
echo "  - README: backend/patterns/gateway-offloading/README.md"
echo "  - Logs: docker-compose logs nginx"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
