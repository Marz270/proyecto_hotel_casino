# 🧪 Guía de Testing - Hotel & Casino API

Esta guía contiene ejemplos de cómo probar las **tácticas de arquitectura** implementadas en el TFU2.

## 🎯 Tácticas Implementadas

1. **Deferred Binding** - Inyección de dependencias con `BOOKING_MODE`
2. **Rollback** - Despliegue sin pérdida de datos entre versiones

---

## 🚀 Comandos de Despliegue

### Despliegue inicial (v1)

```bash
# Windows (PowerShell)
.\deploy.sh

# Linux/Mac
chmod +x *.sh
./deploy.sh
```

### Actualizar a v2

```bash
.\deploy-v2.sh
```

### Rollback a v1

```bash
.\rollback.sh
```

---

## 🔗 Deferred Binding - Cambio de Implementación

### Modo PostgreSQL (Producción)

```bash
# Configurar modo PostgreSQL
docker-compose exec backend_v1 sh -c "export BOOKING_MODE=pg && npm start"

# Probar con datos reales de la base de datos
curl http://localhost:3000/bookings
```

### Modo Mock (Desarrollo/Testing)

```bash
# Configurar modo Mock
docker-compose exec backend_v1 sh -c "export BOOKING_MODE=mock && npm start"

# Probar con datos simulados
curl http://localhost:3000/bookings
```

---

## 📋 Ejemplos de API (CRUD Bookings)

### 1. Obtener todas las reservas

```bash
curl -X GET http://localhost:3000/bookings
```

**Respuesta esperada:**

```json
{
  "success": true,
  "data": [...],
  "source": "PostgreSQL" | "Mock Service",
  "count": 3
}
```

### 2. Crear nueva reserva

```bash
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Ana López",
    "room_number": 102,
    "check_in": "2025-09-25",
    "check_out": "2025-09-27",
    "total_price": 300.00
  }'
```

### 3. Obtener reserva por ID

```bash
curl -X GET http://localhost:3000/bookings/1
```

### 4. Eliminar reserva

```bash
curl -X DELETE http://localhost:3000/bookings/1
```

---

## 🔄 Demo de Rollback

### Escenario completo de demostración

1. **Iniciar con v1:**

```bash
.\deploy.sh
curl http://localhost:3000  # Verificar version: 1.0.0
```

2. **Actualizar a v2:**

```bash
.\deploy-v2.sh
curl http://localhost:3000  # Verificar version: 2.0.0
```

3. **Simular falla y hacer rollback:**

```bash
.\rollback.sh
curl http://localhost:3000  # Verificar version: 1.0.0 (de vuelta)
```

4. **Verificar que los datos se mantuvieron:**

```bash
curl http://localhost:3000/bookings  # Los datos siguen ahí
```

---

## 🎨 Testing de Deferred Binding

### Script de prueba automática

```bash
# Crear archivo test-deferred-binding.sh
echo '#!/bin/bash

echo "🧪 Testing Deferred Binding..."

# Test modo PostgreSQL
export BOOKING_MODE=pg
echo "Testing PostgreSQL mode..."
curl -s http://localhost:3000/bookings | grep "PostgreSQL"

# Test modo Mock
export BOOKING_MODE=mock
echo "Testing Mock mode..."
curl -s http://localhost:3000/bookings | grep "Mock Service"

echo "✅ Deferred Binding tests completed!"' > test-deferred-binding.sh

chmod +x test-deferred-binding.sh
.\test-deferred-binding.sh
```

---

## 📊 Verificación de Arquitectura

### Endpoints de información del sistema

```bash
# Información general de la API
curl http://localhost:3000

# Health check
curl http://localhost:3000/health

# Verificar conexión a base de datos
docker-compose exec db psql -U hoteluser -d hotel_casino -c "SELECT COUNT(*) FROM bookings;"
```

### Monitoreo de contenedores

```bash
# Ver estado de todos los servicios
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs específicos
docker-compose logs backend_v1
docker-compose logs backend_v2
```

---

## 🔍 Validación de NFRs

### 1. **Facilidad de Despliegue (Rollback)**

- ✅ Cambio de v1 → v2 → v1 sin pérdida de datos
- ✅ Base de datos persistente entre versiones
- ✅ Scripts automatizados para despliegue y rollback

### 2. **Modificabilidad (Deferred Binding)**

- ✅ Cambio de implementación sin recompilar código
- ✅ Configuración externa via variables de entorno
- ✅ Inyección de dependencias con factory pattern

### 3. **Seguridad**

- ✅ Validación de inputs con `express-validator`
- ✅ Manejo centralizado de errores
- ✅ Configuración sensible en variables de entorno

---

## 🎭 Demo para Presentación (5 minutos)

### Script de presentación:

1. **"Iniciar sistema"** → `.\deploy.sh`
2. **"Mostrar deferred binding"** → Cambiar `BOOKING_MODE`
3. **"Actualizar a v2"** → `.\deploy-v2.sh`
4. **"Simular problema y rollback"** → `.\rollback.sh`
5. **"Verificar datos preservados"** → `curl /bookings`

**Tiempo estimado: 4-5 minutos** ⏱️
