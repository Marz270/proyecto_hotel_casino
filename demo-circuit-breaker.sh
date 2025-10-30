#!/bin/bash

# Script de demostración del patrón Circuit Breaker
# Demuestra cómo el circuit breaker protege el sistema de fallos en cascada

echo "🔧 Demostración del patrón Circuit Breaker"
echo "=========================================="
echo ""

API_URL="http://localhost:3000"
PAYMENT_ENDPOINT="$API_URL/payments"
STATUS_ENDPOINT="$API_URL/payments/circuit-status"
RESET_ENDPOINT="$API_URL/payments/circuit-reset"

echo "📊 Paso 1: Verificar estado inicial del Circuit Breaker"
echo "--------------------------------------------------------"
curl -s "$STATUS_ENDPOINT" | jq '.'
echo ""
echo "Estado inicial: El circuito debe estar CLOSED (funcionamiento normal)"
echo ""
read -p "Presiona Enter para continuar..."
echo ""

echo "✅ Paso 2: Enviar peticiones de pago (algunas fallarán aleatoriamente)"
echo "-----------------------------------------------------------------------"
echo "Enviando 15 peticiones de pago..."
echo ""

for i in {1..15}; do
  echo "Petición #$i:"
  RESPONSE=$(curl -s -X POST "$PAYMENT_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "{\"reservation_id\": $i, \"amount\": 100, \"payment_method\": \"credit_card\"}")
  
  STATUS=$(echo "$RESPONSE" | jq -r '.data.status // .success')
  MESSAGE=$(echo "$RESPONSE" | jq -r '.message // .error')
  
  echo "  Estado: $STATUS - $MESSAGE"
  
  sleep 0.5
done

echo ""
echo "📊 Paso 3: Verificar estado del Circuit Breaker después de los fallos"
echo "----------------------------------------------------------------------"
curl -s "$STATUS_ENDPOINT" | jq '.'
echo ""
echo "Si hubo suficientes fallos (>50% en 10s), el circuito debería estar OPEN"
echo ""
read -p "Presiona Enter para continuar..."
echo ""

echo "🚫 Paso 4: Intentar enviar más pagos con el circuito ABIERTO"
echo "------------------------------------------------------------"
echo "Estas peticiones deberían ser rechazadas inmediatamente (fail-fast)"
echo ""

for i in {16..20}; do
  echo "Petición #$i:"
  RESPONSE=$(curl -s -X POST "$PAYMENT_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "{\"reservation_id\": $i, \"amount\": 100, \"payment_method\": \"credit_card\"}")
  
  STATUS=$(echo "$RESPONSE" | jq -r '.data.status // .success')
  MESSAGE=$(echo "$RESPONSE" | jq -r '.message // .warning // .error')
  QUEUED=$(echo "$RESPONSE" | jq -r '.data.queued // false')
  
  echo "  Estado: $STATUS - Encolado: $QUEUED"
  echo "  Mensaje: $MESSAGE"
  
  sleep 0.3
done

echo ""
echo "📊 Paso 5: Verificar estadísticas finales"
echo "-----------------------------------------"
curl -s "$STATUS_ENDPOINT" | jq '.'
echo ""

echo "🔄 Paso 6: Esperar a que el circuito pase a HALF_OPEN"
echo "-----------------------------------------------------"
echo "El circuito intentará cerrarse después de 60 segundos..."
echo "(Puedes resetear manualmente con: curl -X POST $RESET_ENDPOINT)"
echo ""

echo "✅ Demostración completada!"
echo ""
echo "Conclusiones del patrón Circuit Breaker:"
echo "- Protege el sistema de fallos en cascada"
echo "- Falla rápido (fail-fast) cuando el servicio externo está caído"
echo "- Se auto-recupera probando periódicamente (HALF_OPEN → CLOSED)"
echo "- Proporciona fallback (encolar pagos) cuando el circuito está abierto"
echo "- Mejora la disponibilidad y resiliencia del sistema"
echo ""
