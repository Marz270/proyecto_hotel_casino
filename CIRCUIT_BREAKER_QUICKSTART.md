# CIRCUIT BREAKER Circuit Breaker - Guía de Uso Rápido

## ¿Qué es?

El patrón Circuit Breaker protege tu sistema de fallos en cascada cuando servicios externos (como pasarelas de pago) están experimentando problemas. Funciona como un "fusible" que se abre cuando detecta demasiados errores.

## Estados

- **OK CLOSED**: Todo funciona normal
- **ERROR OPEN**: Demasiados errores, rechaza peticiones y usa fallback
- **WARNING HALF_OPEN**: Probando si el servicio se recuperó

## Endpoints Nuevos

### 1. Procesar Pago (con protección)
```bash
curl -X POST http://localhost:3000/payments \
  -H "Content-Type: application/json" \
  -d '{"reservation_id": 1, "amount": 100, "payment_method": "credit_card"}'
```

### 2. Ver Estado del Circuit Breaker
```bash
curl http://localhost:3000/payments/circuit-status | jq '.'
```

### 3. Resetear Circuito (admin)
```bash
curl -X POST http://localhost:3000/payments/circuit-reset
```

## Demo Rápida

```bash
# Linux/Mac
./demo-circuit-breaker.sh

# Windows
.\demo-circuit-breaker.ps1
```

## ¿Cómo Funciona?

1. Envías peticiones de pago normalmente
2. Si >50% fallan en 10 segundos → Circuito se ABRE
3. Peticiones siguientes fallan rápido y se encolan
4. Después de 60s, prueba si el servicio se recuperó
5. Si la prueba es exitosa → Circuito se CIERRA

## Documentación Completa

Ver: `backend/patterns/circuit-breaker/README.md`

## Test Standalone

```bash
node backend/patterns/circuit-breaker/test-circuit-breaker.js
```

---

**Implementado con [Opossum](https://github.com/nodeshift/opossum) - Circuit Breaker robusto para Node.js**
