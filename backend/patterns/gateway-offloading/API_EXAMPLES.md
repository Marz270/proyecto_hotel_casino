# Gateway Offloading - Ejemplos de Uso

Este documento contiene ejemplos prácticos y configuraciones avanzadas del patrón Gateway Offloading.

## Ejemplos de curl para probar cada funcionalidad

### 1. Rate Limiting

```bash
# Test rate limiting - enviar múltiples requests
for i in {1..15}; do
  echo "Request $i:"
  curl -w "\nStatus: %{http_code}\n" http://localhost/api/bookings
  echo "---"
done
```

**Resultado esperado**: Después de ~10 requests, empezarás a ver status 429 (Too Many Requests)

### 2. Security Headers

```bash
# Verificar todos los security headers
curl -I http://localhost/api/bookings

# Buscar headers específicos
curl -I http://localhost/api/bookings | grep -i "x-content-type-options"
curl -I http://localhost/api/bookings | grep -i "x-frame-options"
curl -I http://localhost/api/bookings | grep -i "x-xss-protection"
curl -I http://localhost/api/bookings | grep -i "referrer-policy"
```

### 3. Compresión gzip

```bash
# Sin compresión
curl -H "Accept-Encoding: identity" \
     -w "Size: %{size_download} bytes\n" \
     -o /dev/null -s \
     http://localhost/api/bookings

# Con compresión
curl -H "Accept-Encoding: gzip" \
     -w "Size: %{size_download} bytes\n" \
     -o /dev/null -s \
     --compressed \
     http://localhost/api/bookings
```

### 4. CORS Preflight

```bash
# Simular preflight request de un frontend
curl -X OPTIONS http://localhost/api/bookings \
     -H "Origin: http://frontend.example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -v
```

**Debe retornar**:
- Status: 204 No Content
- Headers: Access-Control-Allow-* con valores apropiados

### 5. SSL/TLS Testing (para producción)

```bash
# Test SSL configuration (si HTTPS está habilitado)
curl -v https://localhost/api/bookings

# Test con SSLLabs
# https://www.ssllabs.com/ssltest/analyze.html?d=tu-dominio.com

# Test con testssl.sh
docker run --rm -ti drwetter/testssl.sh https://tu-dominio.com
```

### 6. Logging

```bash
# Hacer una petición identificable
curl http://localhost/api/bookings?tracking=test123

# Ver el log inmediatamente
docker-compose exec nginx tail -f /var/log/nginx/access.log

# Buscar petición específica
docker-compose exec nginx grep "test123" /var/log/nginx/access.log
```

### 7. Connection Pooling

```bash
# Test de conexiones persistentes
curl -v http://localhost/api/bookings 2>&1 | grep -i "connection"

# Apache Bench para múltiples conexiones
ab -n 1000 -c 10 http://localhost/api/bookings
```

## Configuraciones Avanzadas

### Rate Limiting por Ruta Específica

```nginx
# En nginx-gateway-offloading.conf

# Zona para pagos (muy restrictiva)
limit_req_zone $binary_remote_addr zone=payments:10m rate=2r/s;

location /api/payments {
    limit_req zone=payments burst=5 nodelay;
    
    proxy_pass http://backend;
    # ... resto de configuración
}
```

### Rate Limiting por API Key

```nginx
# Rate limiting basado en API key en lugar de IP
limit_req_zone $http_x_api_key zone=api_key:10m rate=100r/s;

location /api/ {
    if ($http_x_api_key = "") {
        return 401 "API Key required";
    }
    
    limit_req zone=api_key burst=200 nodelay;
    
    proxy_pass http://backend;
}
```

### Whitelist de IPs (sin rate limiting)

```nginx
# Definir geo para IPs internas
geo $is_internal {
    default 0;
    192.168.0.0/16 1;
    10.0.0.0/8 1;
}

location /api/ {
    # Solo aplicar rate limiting a IPs externas
    if ($is_internal = 0) {
        limit_req zone=api burst=50 nodelay;
    }
    
    proxy_pass http://backend;
}
```

### CORS Dinámico por Dominio

```nginx
# Permitir solo dominios específicos
map $http_origin $cors_origin {
    default "";
    "~^https?://(www\.)?example\.com$" "$http_origin";
    "~^https?://(www\.)?frontend\.com$" "$http_origin";
}

server {
    location / {
        add_header 'Access-Control-Allow-Origin' $cors_origin always;
        # ... resto de configuración
    }
}
```

### SSL con Let's Encrypt

```nginx
server {
    listen 443 ssl http2;
    server_name tu-dominio.com;
    
    # Certificados de Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/tu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tu-dominio.com/privkey.pem;
    
    # Configuración SSL moderna
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers off;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/tu-dominio.com/chain.pem;
    
    # ... resto de configuración
}
```

### Caché de Respuestas Estáticas

```nginx
# Zona de caché
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=100m;

location /api/rooms {
    # Cachear respuestas exitosas por 5 minutos
    proxy_cache api_cache;
    proxy_cache_valid 200 5m;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    
    add_header X-Cache-Status $upstream_cache_status;
    
    proxy_pass http://backend;
}
```

### Health Check Activo

```nginx
upstream backend {
    server backend_v1:3000 max_fails=3 fail_timeout=30s;
    server backend_v2:3000 backup;
    
    # Health check (requiere nginx-plus o módulo adicional)
    # check interval=3000 rise=2 fall=5 timeout=1000;
}

# Health check pasivo mediante endpoint
location /health {
    access_log off;
    proxy_pass http://backend/health;
    proxy_next_upstream error timeout;
}
```

### Logging Extendido con Variables Personalizadas

```nginx
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    'rt=$request_time '
                    'uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" '
                    'urt="$upstream_response_time" '
                    'ucs="$upstream_cache_status" '
                    'cs=$upstream_addr '
                    'api_key=$http_x_api_key '
                    'user_id=$http_x_user_id';

access_log /var/log/nginx/access.log detailed;
```

### Protección contra Path Traversal

```nginx
location / {
    # Bloquear intentos de path traversal
    if ($request_uri ~* "(\.\./|\.\.\\)") {
        return 403 "Path traversal attempt detected";
    }
    
    # Bloquear peticiones con caracteres null
    if ($request_uri ~* "\x00") {
        return 403 "Null byte injection detected";
    }
    
    proxy_pass http://backend;
}
```

### Rate Limiting con Burst y Delay

```nginx
# Configuración más flexible de rate limiting
location /api/ {
    # Permite 10 req/s base
    # Burst de 20 requests (10 se procesan inmediatamente, 10 con delay)
    limit_req zone=api burst=20 delay=10;
    
    proxy_pass http://backend;
}
```

## Monitoreo y Métricas

### Dashboard de Nginx con stub_status

```nginx
# Agregar al servidor
location /nginx_status {
    stub_status on;
    access_log off;
    
    # Restringir acceso solo a localhost
    allow 127.0.0.1;
    deny all;
}
```

**Uso**:
```bash
curl http://localhost/nginx_status
```

**Output**:
```
Active connections: 42
server accepts handled requests
 123456 123456 234567
Reading: 1 Writing: 3 Waiting: 38
```

### Exportar métricas a Prometheus

```bash
# Usar nginx-prometheus-exporter
docker run -d -p 9113:9113 \
  nginx/nginx-prometheus-exporter:latest \
  -nginx.scrape-uri=http://nginx:80/nginx_status
```

### Análisis de Logs con GoAccess

```bash
# Análisis en tiempo real
docker-compose exec nginx tail -f /var/log/nginx/access.log | \
  goaccess --log-format=COMBINED -

# Generar reporte HTML
docker-compose exec nginx goaccess /var/log/nginx/access.log \
  -o /var/log/nginx/report.html \
  --log-format=COMBINED
```

## Testing de Carga

### Apache Bench

```bash
# 1000 requests, 10 concurrentes
ab -n 1000 -c 10 http://localhost/api/bookings

# Con autenticación
ab -n 1000 -c 10 -H "Authorization: Bearer TOKEN" \
   http://localhost/api/bookings
```

### wrk (más avanzado)

```bash
# 30 segundos, 4 threads, 100 conexiones
wrk -t4 -c100 -d30s http://localhost/api/bookings

# Con script Lua para POST
wrk -t4 -c100 -d30s -s post.lua http://localhost/api/bookings
```

Archivo `post.lua`:
```lua
wrk.method = "POST"
wrk.body   = '{"client_id":1,"room_id":101,"check_in":"2025-11-01"}'
wrk.headers["Content-Type"] = "application/json"
```

### Verificar Rate Limiting bajo Carga

```bash
# Enviar 100 requests lo más rápido posible
seq 1 100 | xargs -I {} -P 20 curl -s -o /dev/null -w "%{http_code}\n" \
  http://localhost/api/bookings | sort | uniq -c

# Output esperado:
#   10 200
#   90 429
```

## Troubleshooting

### Debug de Rate Limiting

```bash
# Ver estado de las zonas de rate limiting
docker-compose exec nginx cat /proc/meminfo | grep nginx

# Ver configuración activa
docker-compose exec nginx nginx -T | grep limit_req
```

### Debug de SSL/TLS

```bash
# Ver certificados
openssl s_client -connect localhost:443 -showcerts

# Test de protocolo específico
openssl s_client -connect localhost:443 -tls1_2
openssl s_client -connect localhost:443 -tls1_3
```

### Ver configuración compilada de Nginx

```bash
docker-compose exec nginx nginx -V
```

### Test de sintaxis de configuración

```bash
docker-compose exec nginx nginx -t
```

### Reload sin downtime

```bash
docker-compose exec nginx nginx -s reload
```

## Integración con Docker Compose

### docker-compose.yaml completo

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx-gateway-offloading.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - backend_v1
      - backend_v2
    networks:
      - app_network
    restart: unless-stopped

  backend_v1:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
      - BOOKING_MODE=pg
    networks:
      - app_network

  backend_v2:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=production
      - BOOKING_MODE=pg
    networks:
      - app_network

volumes:
  nginx_logs:

networks:
  app_network:
    driver: bridge
```

---

## Referencias

- [Nginx Rate Limiting Guide](https://www.nginx.com/blog/rate-limiting-nginx/)
- [Nginx Security Headers](https://observatory.mozilla.org/)
- [SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Gateway Offloading Pattern (Microsoft)](https://docs.microsoft.com/en-us/azure/architecture/patterns/gateway-offloading)

---

**Documento creado**: `backend/patterns/gateway-offloading/API_EXAMPLES.md`
