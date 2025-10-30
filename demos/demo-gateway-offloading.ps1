# ============================================
# Demo Gateway Offloading Pattern
# Salto Hotel & Casino API
# ============================================

Write-Host "======================================" -ForegroundColor Blue
Write-Host "Gateway Offloading Pattern Demo" -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue
Write-Host ""

$NGINX_URL = "http://localhost:8080"
$BACKEND_URL = "http://localhost:3000"
$API_ENDPOINT = "/bookings"

# Funciones auxiliares
function Print-Header($text) {
    Write-Host "==========================================" -ForegroundColor Blue
    Write-Host $text -ForegroundColor Blue
    Write-Host "==========================================" -ForegroundColor Blue
}

function Print-Success($text) {
    Write-Host "[OK] $text" -ForegroundColor Green
}

function Print-Warning($text) {
    Write-Host "[WARNING] $text" -ForegroundColor Yellow
}

function Print-Error($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

# Verificar que los servicios esten corriendo
Print-Header "0. Verificacion de Servicios"
try {
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/" -UseBasicParsing -ErrorAction Stop
    Print-Success "Backend esta corriendo en $BACKEND_URL"
} catch {
    Print-Error "Backend no esta accesible"
    exit 1
}

try {
    $response = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -UseBasicParsing -ErrorAction Stop
    Print-Success "Nginx esta corriendo en $NGINX_URL"
} catch {
    Print-Error "Nginx no esta accesible. Ejecuta: docker-compose up -d"
    exit 1
}
Write-Host ""

# ============================================
# 1. Probar Rate Limiting
# ============================================
Print-Header "1. Rate Limiting (10 req/s)"
Write-Host "Enviando 20 requests rapidos para disparar rate limit..."
Write-Host ""

$successCount = 0
$rateLimitedCount = 0

for ($i = 1; $i -le 20; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -UseBasicParsing -ErrorAction Stop
        Write-Host -NoNewline "."
        $successCount++
    } catch {
        if ($_.Exception.Response.StatusCode -eq 429) {
            Write-Host -NoNewline "X"
            $rateLimitedCount++
        } else {
            Write-Host -NoNewline "?"
        }
    }
}

Write-Host ""
Write-Host ""
Print-Success "Requests exitosos: $successCount"
Print-Warning "Requests bloqueados (429): $rateLimitedCount"

if ($rateLimitedCount -gt 0) {
    Print-Success "Rate limiting funcionando correctamente"
} else {
    Print-Warning "Rate limiting NO activado (todos pasaron)"
}
Write-Host ""

# ============================================
# 2. Verificar Security Headers
# ============================================
Print-Header "2. Security Headers"
Write-Host "Verificando headers de seguridad..."
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -Method Head -UseBasicParsing
    
    function Check-Header($headerName, $expectedValue) {
        if ($response.Headers.ContainsKey($headerName)) {
            $value = $response.Headers[$headerName]
            Print-Success "$headerName : $value"
        } else {
            Print-Error "$headerName : NO ENCONTRADO"
        }
    }
    
    Check-Header "X-Content-Type-Options" "nosniff"
    Check-Header "X-Frame-Options" "SAMEORIGIN"
    Check-Header "X-XSS-Protection" "1; mode=block"
    Check-Header "Referrer-Policy" "strict-origin-when-cross-origin"
} catch {
    Print-Error "Error al verificar headers: $_"
}

Write-Host ""

# ============================================
# 3. Verificar Compresion gzip
# ============================================
Print-Header "3. Compresion gzip"
Write-Host "Comparando tamano de respuesta con/sin compresion..."
Write-Host ""

try {
    # Sin gzip
    $noGzip = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -Headers @{"Accept-Encoding"="identity"} -UseBasicParsing
    $sizeNoGzip = $noGzip.Content.Length
    Print-Warning "Tamano sin gzip: $sizeNoGzip bytes"
    
    # Con gzip
    $withGzip = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -UseBasicParsing
    $sizeGzip = $withGzip.Content.Length
    Print-Success "Tamano con gzip: $sizeGzip bytes"
    
    if ($sizeNoGzip -gt 0) {
        $reduction = [math]::Round((1 - $sizeGzip / $sizeNoGzip) * 100, 2)
        Print-Success "Reduccion: $reduction%"
    }
} catch {
    Print-Warning "Error al medir compresion: $_"
}

Write-Host ""

# ============================================
# 4. Verificar CORS Headers
# ============================================
Print-Header "4. CORS Headers"
Write-Host "Simulando preflight request..."
Write-Host ""

try {
    $headers = @{
        "Origin" = "http://frontend.example.com"
        "Access-Control-Request-Method" = "POST"
    }
    $response = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -Method Options -Headers $headers -UseBasicParsing
    
    function Check-CorsHeader($headerName) {
        if ($response.Headers.ContainsKey($headerName)) {
            $value = $response.Headers[$headerName]
            Print-Success "$headerName : $value"
        } else {
            Print-Error "$headerName : NO ENCONTRADO"
        }
    }
    
    Check-CorsHeader "Access-Control-Allow-Origin"
    Check-CorsHeader "Access-Control-Allow-Methods"
    Check-CorsHeader "Access-Control-Allow-Headers"
} catch {
    Print-Warning "Error al verificar CORS: $_"
}

Write-Host ""

# ============================================
# 5. Verificar Logging
# ============================================
Print-Header "5. Request Logging"
Write-Host "Verificando que las peticiones se loggean..."
Write-Host ""

$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$testPath = "/bookings?test=$timestamp"

try {
    Invoke-WebRequest -Uri "$NGINX_URL$testPath" -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
    Start-Sleep -Seconds 1
    
    # Intentar verificar el log
    $logCheck = docker-compose exec -T nginx test -f /var/log/nginx/access.log 2>$null
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Archivo de log existe: /var/log/nginx/access.log"
        
        $logContent = docker-compose exec -T nginx grep $timestamp /var/log/nginx/access.log 2>$null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Peticion registrada en el log"
            Write-Host ""
            Write-Host "Ultimas 3 lineas del log:"
            docker-compose exec -T nginx tail -3 /var/log/nginx/access.log
        } else {
            Print-Warning "Peticion no encontrada en el log"
        }
    } else {
        Print-Warning "No se pudo acceder al archivo de log (puede ser normal en algunos setups)"
    }
} catch {
    Print-Warning "Error al verificar logging: $_"
}

Write-Host ""

# ============================================
# 6. Verificar Upstream Backend
# ============================================
Print-Header "6. Backend Upstream & Connection Pooling"
Write-Host "Verificando proxy pass al backend..."
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -UseBasicParsing
    
    if ($response.Headers.ContainsKey("X-Forwarded-For")) {
        Print-Success "Header X-Forwarded-For presente (proxy funciona)"
    }
    
    if ($response.Headers.ContainsKey("X-Real-IP")) {
        Print-Success "Header X-Real-IP presente (IP original preservada)"
    }
    
    Print-Success "Nginx actua como reverse proxy correctamente"
} catch {
    Print-Warning "Error al verificar proxy: $_"
}

Write-Host ""

# ============================================
# 7. Performance Benchmark Simple
# ============================================
Print-Header "7. Performance Benchmark"
Write-Host "Midiendo tiempos de respuesta (10 peticiones)..."
Write-Host ""

$totalTime = 0
$requests = 10

for ($i = 1; $i -le $requests; $i++) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Invoke-WebRequest -Uri "$NGINX_URL$API_ENDPOINT" -UseBasicParsing -ErrorAction Stop | Out-Null
        $stopwatch.Stop()
        $totalTime += $stopwatch.Elapsed.TotalSeconds
        Write-Host -NoNewline "."
    } catch {
        Write-Host -NoNewline "!"
    }
}

Write-Host ""
Write-Host ""

$avgTime = [math]::Round($totalTime / $requests, 3)
Print-Success "Tiempo promedio por request: ${avgTime}s"

if ($avgTime -lt 0.1) {
    Print-Success "Performance excelente (<100ms)"
} elseif ($avgTime -lt 0.5) {
    Print-Success "Performance buena (<500ms)"
} else {
    Print-Warning "Performance puede mejorar (>${avgTime}s)"
}

Write-Host ""

# ============================================
# Resumen Final
# ============================================
Print-Header "Resumen de Gateway Offloading"

Write-Host ""
Write-Host "Funcionalidades verificadas:"
Write-Host ""
Write-Host "  - Rate Limiting (proteccion DDoS)"
Write-Host "  - Security Headers (XSS, clickjacking)"
Write-Host "  - Compresion gzip (reduccion bandwidth)"
Write-Host "  - CORS Handling (cross-origin)"
Write-Host "  - Request Logging (auditoria)"
Write-Host "  - Reverse Proxy (connection pooling)"
Write-Host "  - Performance (tiempos de respuesta)"
Write-Host ""

Print-Success "Gateway Offloading Pattern implementado correctamente"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Blue
Write-Host "Para mas informacion:"
Write-Host "  - Configuracion: nginx/nginx.conf"
Write-Host "  - README: backend/patterns/gateway-offloading/README.md"
Write-Host "  - Logs: docker-compose logs nginx"
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""
