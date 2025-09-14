# 📘 Manual de Usuario - TFU2: Hotel & Casino API

## 🎯 Trabajo Final Unidad 2 - Análisis y Diseño de Aplicaciones II

Este manual contiene todos los comandos y ejemplos necesarios para **demostrar las tácticas de arquitectura** implementadas en el sistema de reservas del Salto Hotel & Casino.

### 🏗️ Tácticas Implementadas

1. **Diferir Binding** - Inyección de dependencias con `BOOKING_MODE=pg|mock`
2. **Rollback** - Despliegue sin pérdida de datos entre versiones

---

## 🚀 1. DESPLIEGUE INICIAL

### Desplegar sistema completo

```bash
# Windows (PowerShell)
.\deploy.sh

# Linux/Mac
chmod +x *.sh
./deploy.sh
```

**Resultado esperado:**

- ✅ Base de datos PostgreSQL en `localhost:5432`
- ✅ backend_v1 (estable) en `http://localhost:3000`
- ✅ Volumen persistente `db_data` creado

---

## 🧪 2. TESTING DE DIFERIR BINDING

### 2.1 Modo PostgreSQL (Producción)

```bash
# El sistema inicia por defecto en modo PostgreSQL
# Verificar configuración actual
curl http://localhost:3000

# Respuesta esperada:
{
  "message": "🏨 Salto Hotel & Casino API",
  "version": "1.0",
  "booking_mode": "pg",
  "endpoints": {...}
}
```

### 2.2 Cambiar a Modo Mock (Simulado)

```bash
# Opción 1: Editar .env y reiniciar contenedor
echo "BOOKING_MODE=mock" >> .env
docker-compose restart backend_v1

# Opción 2: Variable de entorno temporal
docker-compose exec backend_v1 sh -c "BOOKING_MODE=mock node server.js"
```

### 2.3 Verificar cambio de implementación

```bash
# En modo PostgreSQL
curl http://localhost:3000/bookings
# Respuesta: "source": "PostgreSQL"

# En modo Mock
curl http://localhost:3000/bookings
# Respuesta: "source": "Mock Service"
```

---

## 📋 3. CRUD DE RESERVAS

### 3.1 Obtener todas las reservas

```bash
curl -X GET http://localhost:3000/bookings

# Respuesta esperada:
{
  "success": true,
  "data": [...],
  "source": "PostgreSQL" | "Mock Service",
  "count": 3
}
```

### 3.2 Crear nueva reserva

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

# Respuesta esperada:
{
  "success": true,
  "data": {
    "id": 4,
    "client_name": "Ana López",
    "room_number": 102,
    "check_in": "2025-09-25",
    "check_out": "2025-09-27",
    "total_price": 300.00,
    "created_at": "2025-09-13T..."
  },
  "source": "PostgreSQL",
  "message": "Booking created successfully"
}
```

### 3.3 Obtener reserva por ID

```bash
curl -X GET http://localhost:3000/bookings/1

# Respuesta esperada:
{
  "success": true,
  "data": {
    "id": 1,
    "client_name": "Juan Pérez",
    "room_number": 101,
    ...
  },
  "source": "PostgreSQL"
}
```

### 3.4 Eliminar reserva

```bash
curl -X DELETE http://localhost:3000/bookings/1

# Respuesta esperada:
{
  "success": true,
  "data": {...},
  "source": "PostgreSQL",
  "message": "Booking deleted successfully"
}
```

### 3.5 Testing de validación (debe fallar)

```bash
# Datos inválidos - debe retornar HTTP 400
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "",
    "room_number": -1,
    "check_in": "fecha_invalida",
    "total_price": -100
  }'

# Respuesta esperada:
{
  "success": false,
  "error": "Validation failed",
  "details": [
    {
      "type": "field",
      "msg": "Client name is required",
      "path": "client_name",
      "location": "body"
    },
    ...
  ]
}
```

---

## 🔄 4. DEMOSTRACIÓN DE ROLLBACK

### 4.1 Desplegar versión 2

```bash
# Ejecutar después del despliegue inicial
./deploy-v2.sh
```

**Resultado esperado:**

- ✅ backend_v1 en `http://localhost:3000`
- ✅ backend_v2 en `http://localhost:3001`
- ✅ Misma base de datos compartida

### 4.2 Verificar ambas versiones

```bash
# Probar v1 (estable)
curl http://localhost:3000
# Respuesta: "version": "1.0.0"

# Probar v2 (nueva)
curl http://localhost:3001
# Respuesta: "version": "2.0.0"

# Verificar que comparten datos
curl http://localhost:3000/bookings
curl http://localhost:3001/bookings
# Ambos deben mostrar las mismas reservas
```

### 4.3 Ejecutar rollback

```bash
# Simular problema con v2 y hacer rollback
./rollback.sh
```

**Resultado esperado:**

- ✅ backend_v2 detenido
- ✅ backend_v1 funcionando en `localhost:3000`
- ✅ Datos preservados (sin pérdida)

### 4.4 Verificar integridad después del rollback

```bash
# Verificar versión
curl http://localhost:3000
# Respuesta: "version": "1.0.0"

# Verificar datos preservados
curl http://localhost:3000/bookings
# Todas las reservas creadas deben estar presentes

# Verificar que v2 está detenida
curl http://localhost:3001
# No debe responder (connection refused)
```

---

## 🎭 5. SCRIPT PARA DEMO DE 5 MINUTOS

```bash
#!/bin/bash
echo "🎯 === DEMO TFU2 - TÁCTICAS DE ARQUITECTURA ==="

echo "📌 1. Despliegue inicial (Diferir Binding)"
./deploy.sh
curl http://localhost:3000

echo "📌 2. Probar CRUD con PostgreSQL"
curl http://localhost:3000/bookings
curl -X POST http://localhost:3000/bookings -H "Content-Type: application/json" -d '{"client_name": "Demo User", "room_number": 999, "check_in": "2025-12-01", "check_out": "2025-12-02", "total_price": 200.00}'

echo "📌 3. Cambiar a modo Mock (Diferir Binding)"
echo "BOOKING_MODE=mock" > .env
docker-compose restart backend_v1
curl http://localhost:3000/bookings

echo "📌 4. Desplegar v2 (Rollback tactic)"
echo "BOOKING_MODE=pg" > .env
docker-compose restart backend_v1
./deploy-v2.sh
curl http://localhost:3000
curl http://localhost:3001

echo "📌 5. Ejecutar rollback sin pérdida de datos"
./rollback.sh
curl http://localhost:3000/bookings

echo "✅ Demo completada - Tácticas demostradas exitosamente!"
```

---

## 🔍 6. COMANDOS DE DEBUGGING

### Ver logs

```bash
# Logs de backend_v1
docker-compose logs -f backend_v1

# Logs de base de datos
docker-compose logs -f db

# Logs de todos los servicios
docker-compose logs -f
```

### Estado del sistema

```bash
# Ver contenedores activos
docker-compose ps

# Ver volúmenes
docker volume ls

# Ver redes
docker network ls
```

### Acceso directo a base de datos

```bash
# Conectar a PostgreSQL
docker-compose exec db psql -U hoteluser -d hotel_casino

# Consultar reservas directamente
docker-compose exec db psql -U hoteluser -d hotel_casino -c "SELECT * FROM bookings;"
```

### Limpiar sistema completo

```bash
# Detener y eliminar todo
docker-compose down --volumes --remove-orphans

# Eliminar imágenes (opcional)
docker-compose down --rmi all --volumes --remove-orphans
```

---

## 📊 7. VALIDACIÓN DE REQUERIMIENTOS NO FUNCIONALES

### ✅ Diferir Binding

- **Demostrado**: Cambio de `BOOKING_MODE=pg` a `BOOKING_MODE=mock`
- **Validar**: `curl http://localhost:3000/bookings` muestra diferente `"source"`

### ✅ Rollback sin pérdida de datos

- **Demostrado**: `./deploy-v2.sh` + `./rollback.sh`
- **Validar**: Reservas creadas en v2 persisten después del rollback

### ✅ Facilidad de despliegue

- **Demostrado**: Scripts automatizados `deploy.sh`, `deploy-v2.sh`, `rollback.sh`
- **Validar**: Un comando despliega todo el sistema

### ✅ Seguridad (Validación)

- **Demostrado**: `express-validator` en endpoints POST
- **Validar**: Datos inválidos retornan HTTP 400 con detalles

---

## 🎯 RESUMEN PARA PRESENTACIÓN

**Tiempo estimado: 4-5 minutos**

1. **Diferir Binding** (1 min): `./deploy.sh` → mostrar cambio BOOKING_MODE
2. **CRUD básico** (1 min): Crear y consultar reserva
3. **Rollback** (2 min): `./deploy-v2.sh` → `./rollback.sh`
4. **Validación** (1 min): Mostrar datos preservados

¡Sistema listo para demostración del TFU2! 🎉
