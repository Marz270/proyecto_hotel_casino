# Circuit Breaker Pattern - Implementación

## Descripción

El patrón Circuit Breaker está implementado en el sistema de procesamiento de pagos del backend. Protege al sistema de fallos en cascada cuando el servicio de pagos externo experimenta problemas.

## Arquitectura

### Estados del Circuit Breaker

```
┌─────────┐
│ CLOSED  │ ◄─── Estado normal, todas las peticiones pasan
└────┬────┘
     │ Fallos >= 50% en ventana de 10s
     ▼
┌─────────┐
│  OPEN   │ ◄─── Rechaza peticiones, activa fallback
└────┬────┘
     │ Después de 60 segundos
     ▼
┌──────────┐
│HALF_OPEN │ ◄─── Permite 1 petición de prueba
└────┬─────┘
     │
     ├─── Si éxito ───► CLOSED
     │
     └─── Si falla ───► OPEN
```

### Configuración

- **Timeout de operación**: 3 segundos
- **Umbral de error**: 50% de fallos
- **Ventana de medición**: 10 segundos
- **Timeout de reset**: 60 segundos (para pasar a HALF_OPEN)
- **Volumen mínimo**: 5 peticiones antes de evaluar

## Archivos

### Backend

```
backend/
├── patterns/
│   └── circuit-breaker/
│       └── paymentCircuitBreaker.js    # Implementación del Circuit Breaker
└── routes/
    └── index.routes.js                  # Integración en rutas de API
```

### Scripts de demostración

```
demo-circuit-breaker.sh     # Script Bash para Linux/Mac
demo-circuit-breaker.ps1    # Script PowerShell para Windows
```

## Uso

### API Endpoints

#### 1. Procesar pago (con Circuit Breaker)

```bash
POST /payments
Content-Type: application/json

{
  "reservation_id": 1,
  "amount": 100,
  "payment_method": "credit_card"
}
```

**Respuestas posibles:**

**Pago exitoso (circuito CLOSED):**
```json
{
  "success": true,
  "data": {
    "id": 1234,
    "reservation_id": 1,
    "amount": 100,
    "payment_method": "credit_card",
    "status": "approved",
    "transaction_id": "TXN_1234567890",
    "processed_at": "2025-10-30T12:00:00.000Z",
    "gateway": "simulated-payment-gateway"
  },
  "message": "Payment processed successfully"
}
```

**Pago encolado (circuito OPEN, fallback activado):**
```json
{
  "success": true,
  "data": {
    "id": null,
    "reservation_id": 1,
    "amount": 100,
    "payment_method": "credit_card",
    "status": "pending",
    "transaction_id": "PENDING_1234567890",
    "processed_at": "2025-10-30T12:00:00.000Z",
    "message": "Payment queued for processing. Payment gateway is temporarily unavailable.",
    "queued": true
  },
  "warning": "Payment service is temporarily unavailable. Payment queued for processing."
}
```

#### 2. Obtener estado del Circuit Breaker

```bash
GET /payments/circuit-status
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "state": "CLOSED",
    "stats": {
      "fires": 25,
      "successes": 20,
      "failures": 5,
      "rejects": 0,
      "timeouts": 0,
      "fallbacks": 0,
      "latencyMean": 1234.56,
      "percentiles": {
        "p50": 1200,
        "p90": 1800,
        "p99": 2500
      }
    },
    "options": {
      "timeout": 3000,
      "errorThreshold": 50,
      "resetTimeout": 60000
    }
  },
  "message": "Circuit Breaker status retrieved successfully"
}
```

#### 3. Resetear Circuit Breaker manualmente (admin)

```bash
POST /payments/circuit-reset
```

**Respuesta:**
```json
{
  "success": true,
  "message": "Circuit Breaker reset to CLOSED state",
  "data": {
    "state": "CLOSED",
    ...
  }
}
```

## Demostración

### Opción 1: Usando el script automatizado

**En Linux/Mac:**
```bash
chmod +x demo-circuit-breaker.sh
./demo-circuit-breaker.sh
```

**En Windows (PowerShell):**
```powershell
.\demo-circuit-breaker.ps1
```

### Opción 2: Prueba manual

1. **Verificar estado inicial:**
```bash
curl http://localhost:3000/payments/circuit-status | jq '.'
```

2. **Enviar múltiples peticiones de pago:**
```bash
# Algunas fallarán aleatoriamente (15% de probabilidad)
for i in {1..15}; do
  curl -X POST http://localhost:3000/payments \
    -H "Content-Type: application/json" \
    -d "{\"reservation_id\": $i, \"amount\": 100, \"payment_method\": \"credit_card\"}"
  echo ""
  sleep 0.5
done
```

3. **Verificar si el circuito se abrió:**
```bash
curl http://localhost:3000/payments/circuit-status | jq '.data.state'
```

4. **Probar el fallback (si el circuito está OPEN):**
```bash
# Estas peticiones deberían usar el fallback y encolar los pagos
curl -X POST http://localhost:3000/payments \
  -H "Content-Type: application/json" \
  -d '{"reservation_id": 99, "amount": 100, "payment_method": "credit_card"}'
```

5. **Resetear el circuito manualmente (opcional):**
```bash
curl -X POST http://localhost:3000/payments/circuit-reset
```

## Monitoreo y Logs

El Circuit Breaker emite eventos que se registran en la consola:

```
[WARNING] Circuit Breaker OPENED - Payment service appears to be down
   Subsequent requests will fail fast without attempting payment processing

[INFO] Circuit Breaker HALF-OPEN - Testing if payment service recovered

[OK] Circuit Breaker CLOSED - Payment service is healthy again

[OK] Payment processed successfully: TXN_1234567890

[ERROR] Payment processing failed: Payment gateway temporarily unavailable

[TIMEOUT] Payment processing timeout exceeded

[INFO] Fallback triggered, returning cached/default response

[WARNING] Request rejected - Circuit is OPEN
```

## Beneficios

1. **Protección contra fallos en cascada**: Evita que fallos del servicio de pagos afecten toda la aplicación
2. **Fail-fast**: Rechaza peticiones rápidamente cuando el servicio está caído, liberando recursos
3. **Auto-recuperación**: Prueba automáticamente si el servicio se recuperó (estado HALF_OPEN)
4. **Fallback**: Proporciona respuesta alternativa (encolar pagos) cuando el servicio no está disponible
5. **Observabilidad**: Estadísticas detalladas sobre éxito, fallos, latencia y percentiles
6. **Mejora la experiencia del usuario**: Respuestas rápidas en lugar de timeouts largos

## Configuración avanzada

Puedes ajustar la configuración del Circuit Breaker editando:

```javascript
// backend/patterns/circuit-breaker/paymentCircuitBreaker.js

const circuitBreakerOptions = {
  timeout: 3000,                    // Timeout de operación
  errorThresholdPercentage: 50,     // % de errores para abrir
  resetTimeout: 60000,              // Tiempo antes de HALF_OPEN
  rollingCountTimeout: 10000,       // Ventana de medición
  rollingCountBuckets: 10,          // Buckets para estadísticas
  volumeThreshold: 5,               // Volumen mínimo de peticiones
};
```

## Referencias

- Patrón Circuit Breaker: [Martin Fowler](https://martinfowler.com/bliki/CircuitBreaker.html)
- Librería Opossum: [GitHub](https://github.com/nodeshift/opossum)
- Azure Architecture Patterns: [Circuit Breaker](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)

## Relación con otros patrones

El Circuit Breaker se complementa con:

- **Retry Pattern**: Para fallos transitorios antes de abrir el circuito
- **Timeout Pattern**: Para evitar esperas indefinidas
- **Fallback Pattern**: Para proporcionar respuestas alternativas
- **Health Check Pattern**: Para monitorear el estado del sistema

---

**Implementado por:** Martina Guzmán, Francisco Lima, Nicolás Márquez  
**Fecha:** 30 de octubre de 2025  
**Proyecto:** Salto Hotel & Casino API - TFU4 Patrones de Arquitectura
