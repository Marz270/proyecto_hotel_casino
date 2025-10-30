# Health Endpoint Monitoring Pattern

## Descripción

El patrón **Health Endpoint Monitoring** implementa un endpoint dedicado (`/health`) que permite verificar el estado de salud del servicio y sus dependencias críticas. Este patrón es fundamental para sistemas de monitoreo, balanceadores de carga, orquestadores de contenedores y estrategias de alta disponibilidad.

## Problema que Resuelve

En arquitecturas distribuidas y de microservicios, es crucial detectar proactivamente:

- Fallos de servicios antes de que afecten a los usuarios
- Degradación de dependencias (base de datos, servicios externos)
- Problemas de recursos (memoria, CPU, conexiones)
- Estado general del sistema para decisiones de escalado y rollback

Sin un health check estructurado, los equipos de operaciones y los sistemas automatizados no pueden:

- Determinar si un servicio está listo para recibir tráfico
- Detectar y aislar instancias con problemas
- Activar rollbacks automáticos ante regressions
- Implementar balanceo de carga inteligente

## Implementación en Hotel & Casino API

### Endpoint

**`GET /health`**

Retorna el estado de salud del servicio y todos sus componentes críticos.

### Respuesta Exitosa (200 OK)

```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2025-10-30T14:32:45.123Z",
    "uptime": 3600.5,
    "environment": "production",
    "version": "1.0.0",
    "checks": {
      "database": {
        "status": "healthy",
        "responseTime": "< 10ms"
      },
      "memory": {
        "status": "healthy",
        "used": "120 MB",
        "total": "512 MB",
        "percentage": "23%"
      },
      "circuitBreaker": {
        "status": "healthy",
        "state": "CLOSED",
        "stats": {
          "totalRequests": 1523,
          "failures": 2,
          "successRate": "99.87%"
        }
      }
    }
  }
}
```

### Respuesta con Fallo (503 Service Unavailable)

```json
{
  "success": false,
  "data": {
    "status": "unhealthy",
    "timestamp": "2025-10-30T14:35:12.456Z",
    "uptime": 3747.2,
    "environment": "production",
    "version": "1.0.0",
    "checks": {
      "database": {
        "status": "unhealthy",
        "error": "connection timeout"
      },
      "memory": {
        "status": "healthy",
        "used": "125 MB",
        "total": "512 MB",
        "percentage": "24%"
      },
      "circuitBreaker": {
        "status": "degraded",
        "state": "OPEN",
        "message": "Payment service circuit is open (degraded mode)"
      }
    }
  }
}
```

## Componentes Verificados

### 1. Database Connection (PostgreSQL)

- **Check**: Ejecuta `SELECT 1` para verificar conectividad
- **Healthy**: Respuesta exitosa en < 10ms
- **Unhealthy**: Timeout, error de conexión, o respuesta incorrecta

### 2. Memory Usage

- **Check**: Analiza `process.memoryUsage()`
- **Healthy**: < 90% de heap usado
- **Warning**: 90-95% de heap usado
- **Unhealthy**: > 95% de heap usado

### 3. Circuit Breaker Status

- **Check**: Estado del Circuit Breaker de pagos
- **Healthy**: Estado CLOSED (normal)
- **Degraded**: Estado OPEN (servicio de pagos caído)
- **Unhealthy**: Error al obtener estado

## Códigos de Estado HTTP

- **200 OK**: Servicio saludable, todos los componentes críticos funcionando
- **503 Service Unavailable**: Servicio degradado o no disponible
  - Base de datos inaccesible
  - Memoria crítica (>95%)
  - Componentes críticos fallando

## Integración con Infraestructura

### Docker Compose Health Check

```yaml
backend_v1:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

### Nginx Upstream Health Check

```nginx
upstream backend {
  server backend_v1:3000 max_fails=3 fail_timeout=30s;

  # Health check configuration
  health_check interval=10s fails=3 passes=2 uri=/health;
}
```

### Kubernetes Liveness & Readiness Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
```

## Casos de Uso

### 1. Monitoreo Automático

```bash
# Prometheus exporter
curl http://api.hotel-casino.com/health | jq '.data.status'
```

### 2. Load Balancer Health Check

```nginx
# Nginx verifica cada 10s
# Si 3 checks fallan, retira el backend del pool
```

### 3. Rollback Automático

```bash
# Script de deployment
HEALTH=$(curl -s http://localhost:3000/health | jq -r '.data.status')
if [ "$HEALTH" != "healthy" ]; then
  echo "Deployment failed, rolling back..."
  ./rollback.sh
fi
```

### 4. Alertas Proactivas

```yaml
# Alertmanager rule
- alert: ServiceUnhealthy
  expr: probe_http_status_code{job="health-check"} != 200
  for: 2m
  annotations:
    summary: "Service health check failing"
```

## Beneficios

### Operacionales

- ✅ **Detección temprana**: Identifica problemas antes que afecten a usuarios
- ✅ **Diagnóstico rápido**: Provee contexto detallado del fallo
- ✅ **Automatización**: Permite rollbacks y escalado automático
- ✅ **Visibilidad**: Métricas centralizadas del estado del sistema

### Técnicos

- ✅ **Granularidad**: Estado de cada componente por separado
- ✅ **Consistencia**: Formato estándar para todos los servicios
- ✅ **Extensibilidad**: Fácil agregar nuevos checks
- ✅ **Performance**: Respuesta < 100ms, bajo overhead

## Mejores Prácticas Implementadas

1. **HTTP Status Codes Semánticos**

   - 200: Servicio completamente funcional
   - 503: Servicio degradado o no disponible

2. **Respuesta Estructurada**

   - Status general + checks individuales
   - Timestamp para correlación de logs
   - Metadata útil (version, uptime, environment)

3. **Checks Independientes**

   - Cada componente se verifica por separado
   - Un componente degradado no falla todo el health check si no es crítico
   - Circuit Breaker OPEN = degraded, no unhealthy

4. **Performance**
   - Checks ejecutados en paralelo (cuando sea posible)
   - Timeout de 5s máximo
   - Sin operaciones costosas (queries complejas, I/O pesado)

## Relación con Tácticas de Arquitectura

### Disponibilidad (TFU2)

- **Detección de fallos**: Health check identifica componentes caídos
- **Recuperación**: Permite rollback automático ante regressions
- **Redundancia activa**: Load balancer usa health check para enrutar tráfico

### Facilidad de Despliegue (TFU2)

- **Deployment safety**: Verifica que nueva versión esté saludable antes de promoverla
- **Rollback automation**: Health check fallido dispara rollback automático
- **Canary deployments**: Health check valida nueva versión con tráfico limitado

## Monitoreo en Producción

### Métricas Recomendadas

- Health check success rate (target: > 99.9%)
- Average response time (target: < 50ms)
- Component-specific failure rates
- Time to detection (TTD) de fallos

### Alertas Sugeridas

```yaml
# Critical: Servicio completamente caído
- alert: ServiceDown
  expr: probe_success{job="health-check"} == 0
  for: 1m
  severity: critical

# Warning: Servicio degradado
- alert: ServiceDegraded
  expr: health_check_status != "healthy"
  for: 5m
  severity: warning

# Info: Database latency alta
- alert: DatabaseSlow
  expr: health_check_database_ms > 100
  for: 10m
  severity: info
```

## Testing

### Probar Health Check

```powershell
# Windows PowerShell
.\demos\demo-health-endpoint.ps1
```

### Simular Fallo de Base de Datos

```bash
# Detener PostgreSQL
docker-compose stop db

# Verificar health check (debería retornar 503)
curl http://localhost:3000/health

# Restaurar PostgreSQL
docker-compose start db
```

### Simular Alta Memoria

```javascript
// En backend (para testing)
const bigArray = new Array(1e8).fill("test"); // Consume ~800MB
// Health check debería marcar memoria como "warning" o "unhealthy"
```

## Código de Implementación

**Location**: `backend/routes/index.routes.js`

```javascript
router.get("/health", async (req, res) => {
  const healthCheck = {
    /* ... estructura completa ... */
  };

  // Check database, memory, circuit breaker
  // Return 200 OK if healthy, 503 if unhealthy
});
```

## Referencias

- [Microsoft: Health Endpoint Monitoring Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/health-endpoint-monitoring)
- [AWS: Health Checks for Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [Kubernetes: Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

**Implementado**: 30 de octubre de 2025  
**Patrón**: Health Endpoint Monitoring (Disponibilidad)  
**Demo**: `demos/demo-health-endpoint.ps1`
