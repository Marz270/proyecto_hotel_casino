# Circuit Breaker - Ejemplos de Respuestas

## 1. Pago Exitoso (Circuito CLOSED)

**Request:**
```bash
POST http://localhost:3000/payments
Content-Type: application/json

{
  "reservation_id": 1,
  "amount": 100.50,
  "payment_method": "credit_card"
}
```

**Response:**
```json
HTTP/1.1 201 Created
Content-Type: application/json

{
  "success": true,
  "data": {
    "id": 7421,
    "reservation_id": 1,
    "amount": 100.5,
    "payment_method": "credit_card",
    "status": "approved",
    "transaction_id": "TXN_1761794311323",
    "processed_at": "2025-10-30T12:34:56.789Z",
    "gateway": "simulated-payment-gateway"
  },
  "message": "Payment processed successfully"
}
```

---

## 2. Pago Encolado (Circuito OPEN - Fallback)

**Request:**
```bash
POST http://localhost:3000/payments
Content-Type: application/json

{
  "reservation_id": 2,
  "amount": 250.00,
  "payment_method": "debit_card"
}
```

**Response:**
```json
HTTP/1.1 202 Accepted
Content-Type: application/json

{
  "success": true,
  "data": {
    "id": null,
    "reservation_id": 2,
    "amount": 250,
    "payment_method": "debit_card",
    "status": "pending",
    "transaction_id": "PENDING_1761794445678",
    "processed_at": "2025-10-30T12:35:45.678Z",
    "message": "Payment queued for processing. Payment gateway is temporarily unavailable.",
    "queued": true
  },
  "message": "Payment queued for processing. Payment gateway is temporarily unavailable.",
  "warning": "Payment service is temporarily unavailable. Payment queued for processing."
}
```

---

## 3. Estado del Circuit Breaker - CLOSED

**Request:**
```bash
GET http://localhost:3000/payments/circuit-status
```

**Response:**
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "data": {
    "state": "CLOSED",
    "stats": {
      "fires": 45,
      "successes": 38,
      "failures": 7,
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

---

## 4. Estado del Circuit Breaker - OPEN

**Request:**
```bash
GET http://localhost:3000/payments/circuit-status
```

**Response:**
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "data": {
    "state": "OPEN",
    "stats": {
      "fires": 62,
      "successes": 25,
      "failures": 32,
      "rejects": 5,
      "timeouts": 0,
      "fallbacks": 5,
      "latencyMean": 1456.78,
      "percentiles": {
        "p50": 1350,
        "p90": 2100,
        "p99": 2800
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

---

## 5. Estado del Circuit Breaker - HALF_OPEN

**Request:**
```bash
GET http://localhost:3000/payments/circuit-status
```

**Response:**
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "data": {
    "state": "HALF_OPEN",
    "stats": {
      "fires": 68,
      "successes": 30,
      "failures": 33,
      "rejects": 5,
      "timeouts": 0,
      "fallbacks": 5,
      "latencyMean": 1389.45,
      "percentiles": {
        "p50": 1300,
        "p90": 2000,
        "p99": 2700
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

---

## 6. Reset Manual del Circuit Breaker

**Request:**
```bash
POST http://localhost:3000/payments/circuit-reset
```

**Response:**
```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "message": "Circuit Breaker reset to CLOSED state",
  "data": {
    "state": "CLOSED",
    "stats": {
      "fires": 68,
      "successes": 30,
      "failures": 33,
      "rejects": 5,
      "timeouts": 0,
      "fallbacks": 5,
      "latencyMean": 1389.45,
      "percentiles": {
        "p50": 1300,
        "p90": 2000,
        "p99": 2700
      }
    },
    "options": {
      "timeout": 3000,
      "errorThreshold": 50,
      "resetTimeout": 60000
    }
  }
}
```

---

## 7. Error de Validación (antes del Circuit Breaker)

**Request:**
```bash
POST http://localhost:3000/payments
Content-Type: application/json

{
  "reservation_id": "invalid",
  "amount": -50,
  "payment_method": "bitcoin"
}
```

**Response:**
```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "success": false,
  "error": "Validation failed",
  "details": [
    {
      "msg": "Reservation ID must be a positive integer",
      "param": "reservation_id",
      "location": "body"
    },
    {
      "msg": "Amount must be a positive number",
      "param": "amount",
      "location": "body"
    },
    {
      "msg": "Invalid payment method",
      "param": "payment_method",
      "location": "body"
    }
  ]
}
```

---

## Interpretación de Estadísticas

### States (Estados)
- **CLOSED**: Funcionamiento normal ✅
- **OPEN**: Servicio degradado, usando fallback ⚠️
- **HALF_OPEN**: Probando recuperación 🔄

### Stats (Estadísticas)
- **fires**: Total de peticiones procesadas
- **successes**: Peticiones exitosas
- **failures**: Peticiones fallidas
- **rejects**: Peticiones rechazadas (circuito abierto)
- **timeouts**: Peticiones que excedieron el timeout
- **fallbacks**: Veces que se usó el fallback
- **latencyMean**: Latencia promedio en milisegundos

### Percentiles de Latencia
- **p50**: 50% de las peticiones son más rápidas que este valor
- **p90**: 90% de las peticiones son más rápidas que este valor
- **p99**: 99% de las peticiones son más rápidas que este valor

---

## Códigos de Estado HTTP

| Código | Significado |
|--------|-------------|
| 201    | Pago procesado exitosamente |
| 202    | Pago aceptado y encolado (fallback) |
| 200    | Consulta de estado exitosa |
| 400    | Error de validación |
| 500    | Error interno del servidor |

---

**Última actualización:** 30 de octubre de 2025
