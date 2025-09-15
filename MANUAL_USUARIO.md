# � Manual de Usuario - Salto Hotel & Casino API

## 🎯 TFU2 - Guía Completa de Uso

Este manual detalla cómo usar el sistema de reservas del Hotel & Casino para demostrar las tácticas de arquitectura **Deferred Binding** y **Rollback**.

### 🏗️ Tácticas Implementadas

1. **Deferred Binding** - Factory Pattern con `BOOKING_MODE=pg|mock`
2. **Rollback** - Blue-Green deployment sin pérdida de datos

---

## 🚀 1. DESPLIEGUE INICIAL

### Desplegar sistema completo

```powershell
# Windows PowerShell (CORRECTO)
.\deploy.ps1

# Verificar que servicios están activos
docker-compose ps
```

**Resultado esperado:**

- ✅ Base de datos PostgreSQL en `localhost:5432`
- ✅ backend_v1 en `http://localhost:3000`
- ✅ nginx en `http://localhost:8080`
- ✅ Volumen persistente `hotel_db_data` creado

### Verificar funcionamiento inicial

```powershell
# Health check V1
curl http://localhost:3000/health
# Respuesta: "healthy - v1.0.0"

# A través de nginx
curl http://localhost:8080/health
# Respuesta: "healthy - v1.0.0"

# Información general del API
curl http://localhost:3000/

# Respuesta esperada:
{
  "message": "🏨 Salto Hotel & Casino API",
  "version": "1.0.0",
  "booking_mode": "pg",
  "endpoints": {
    "bookings": "/bookings",
    "health": "/health"
  }
}
```

---

## 🧪 2. DEMO: TÁCTICA "DEFERRED BINDING"

### 🎯 Objetivo

Demostrar que el mismo código puede usar diferentes implementaciones (PostgreSQL vs Mock) sin recompilar, solo cambiando configuración externa.

### 2.1 Estado Inicial (PostgreSQL)

```powershell
# Verificar configuración actual
Get-Content .env | Select-String "BOOKING_MODE"
# Debe mostrar: BOOKING_MODE=pg

# Probar endpoint de reservas
curl http://localhost:3000/bookings

# Respuesta esperada con PostgreSQL:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "client_name": "Juan Pérez",
      "room_number": 101,
      "check_in": "2025-09-15T00:00:00.000Z",
      "check_out": "2025-09-17T00:00:00.000Z",
      "total_price": "300.00",
      "created_at": "2025-09-15T01:58:57.417Z",
      "updated_at": "2025-09-15T01:58:57.417Z"
    }
    // ... más registros reales
  ],
  "source": "PostgreSQL",  # ← INDICADOR CLAVE
  "count": 4
}
```

### 2.2 Cambiar a Mock Service

```powershell
# PASO 1: Cambiar configuración usando script
.\set-booking-mode-final.ps1 -Mode mock

# PASO 2: CRÍTICO - Recrear contenedor (NO restart)
docker-compose up -d --force-recreate backend_v1

# PASO 3: Verificar cambio en contenedor
docker exec hotel_api_v1 env | Select-String "BOOKING"
# Debe mostrar: BOOKING_MODE=mock
```

### 2.3 Verificar Cambio de Implementación

```powershell
# Probar MISMO endpoint
curl http://localhost:3000/bookings

# Respuesta esperada con Mock Service:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "client_name": "Mock Client 1",
      "room_number": 101,
      "check_in": "2025-12-01T00:00:00.000Z",
      "check_out": "2025-12-03T00:00:00.000Z",
      "total_price": "250.00"
    },
    {
      "id": 2,
      "client_name": "Mock Client 2",
      "room_number": 102,
      "check_in": "2025-12-05T00:00:00.000Z",
      "check_out": "2025-12-07T00:00:00.000Z",
      "total_price": "350.00"
    }
  ],
  "source": "Mock Service",  # ← CAMBIÓ LA IMPLEMENTACIÓN
  "count": 2
}
```

### 2.4 Regresar a PostgreSQL

```powershell
# Cambiar de vuelta a PostgreSQL
.\set-booking-mode-final.ps1 -Mode pg
docker-compose up -d --force-recreate backend_v1

# Verificar regreso a datos reales
curl http://localhost:3000/bookings
# Respuesta: "source": "PostgreSQL" (datos reales preservados)
```

### 🎯 Puntos Clave de la Demostración

- **Mismo código ejecutándose**: Nunca se recompila nada
- **Misma URL**: `http://localhost:3000/bookings`
- **Diferente implementación**: Factory Pattern decide qué servicio usar
- **Configuración externa**: Solo cambia variable de entorno `BOOKING_MODE`
- **Cambio instantáneo**: Efecto inmediato tras recrear contenedor
- **Sin downtime**: El servicio sigue disponible durante el cambio

---

## 📋 3. GESTIÓN DE RESERVAS (CRUD)

### 3.1 Listar todas las reservas

```powershell
curl -X GET http://localhost:3000/bookings

# Respuesta esperada (PostgreSQL):
{
  "success": true,
  "data": [
    {
      "id": 1,
      "client_name": "Juan Pérez",
      "room_number": 101,
      "check_in": "2025-09-15T00:00:00.000Z",
      "check_out": "2025-09-17T00:00:00.000Z",
      "total_price": "300.00",
      "created_at": "2025-09-15T01:58:57.417Z",
      "updated_at": "2025-09-15T01:58:57.417Z"
    }
    // ... más reservas
  ],
  "source": "PostgreSQL",
  "count": 4
}
```

### 3.2 Crear nueva reserva

```powershell
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "María González",
    "room_number": 205,
    "check_in": "2025-10-15",
    "check_out": "2025-10-17",
    "total_price": 450.00
  }'

# Respuesta esperada:
{
  "success": true,
  "data": {
    "id": 5,
    "client_name": "María González",
    "room_number": 205,
    "check_in": "2025-10-15T00:00:00.000Z",
    "check_out": "2025-10-17T00:00:00.000Z",
    "total_price": "450.00",
    "created_at": "2025-09-15T02:15:30.123Z",
    "updated_at": "2025-09-15T02:15:30.123Z"
  },
  "source": "PostgreSQL",
  "message": "Booking created successfully"
}
```

### 3.3 Obtener reserva por ID

```powershell
curl -X GET http://localhost:3000/bookings/1

# Respuesta esperada:
{
  "success": true,
  "data": {
    "id": 1,
    "client_name": "Juan Pérez",
    "room_number": 101,
    "check_in": "2025-09-15T00:00:00.000Z",
    "check_out": "2025-09-17T00:00:00.000Z",
    "total_price": "300.00",
    "created_at": "2025-09-15T01:58:57.417Z",
    "updated_at": "2025-09-15T01:58:57.417Z"
  },
  "source": "PostgreSQL"
}
```

### 3.4 Eliminar reserva

```powershell
curl -X DELETE http://localhost:3000/bookings/1

# Respuesta esperada:
{
  "success": true,
  "data": {
    "id": 1,
    "client_name": "Juan Pérez",
    // ... datos completos de la reserva eliminada
  },
  "source": "PostgreSQL",
  "message": "Booking deleted successfully"
}
```

### 3.5 Validación de datos (debe fallar)

```powershell
# Datos inválidos - debe retornar HTTP 400
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "A",
    "room_number": -1,
    "check_in": "invalid-date",
    "total_price": "not-a-number"
  }'

# Respuesta esperada (HTTP 400):
{
  "success": false,
  "error": "Validation failed",
  "details": [
    {"msg": "Client name must be at least 2 characters", "param": "client_name"},
    {"msg": "Room number must be a positive integer", "param": "room_number"},
    {"msg": "Check-in must be a valid date", "param": "check_in"},
    {"msg": "Total price must be a positive number", "param": "total_price"}
  ]
}
```

---

## 🔄 4. DEMO: TÁCTICA "ROLLBACK"

### 🎯 Objetivo

Demostrar despliegue de nueva versión con rollback sin pérdida de datos usando arquitectura blue-green.

### 4.1 Desplegar versión 2 (Blue-Green)

```powershell
# IMPORTANTE: Asegurar que estamos en PostgreSQL
.\set-booking-mode-final.ps1 -Mode pg
docker-compose up -d --force-recreate backend_v1

# Desplegar versión 2 en paralelo
.\deploy-v2.ps1

# Verificar estado - ambas versiones activas
docker-compose ps
```

**Resultado esperado:**

```
      Name                    Command               State                 Ports
---------------------------------------------------------------------------------------
hotel_api_v1         docker-entrypoint.sh node ...   Up       0.0.0.0:3000->3000/tcp
hotel_api_v2         docker-entrypoint.sh node ...   Up       0.0.0.0:3001->3001/tcp
hotel_casino_db      docker-entrypoint.sh postgres   Up       0.0.0.0:5432->5432/tcp
hotel_nginx          /docker-entrypoint.sh ngin ...   Up       0.0.0.0:8080->80/tcp
```

### 4.2 Verificar ambas versiones funcionando

```powershell
# V1 - acceso directo
curl http://localhost:3000/health
# Respuesta: "healthy - v1.0.0"

# V2 - acceso directo
curl http://localhost:3001/health
# Respuesta: "healthy - v2.0.0"

# Nginx - apunta a V2 por defecto tras deploy-v2
curl http://localhost:8080/health
# Respuesta: "healthy - v2 deployment active"
```

### 4.3 Comparar datos entre versiones

```powershell
# V1 - PostgreSQL con datos reales
curl http://localhost:3000/bookings
# Respuesta: "source": "PostgreSQL", 4+ registros reales

# V2 - Mock Service con datos ficticios
curl http://localhost:3001/bookings
# Respuesta: "source": "Mock Service", 2 registros ficticios

# Nginx - dirigido a V2 (Mock)
curl http://localhost:8080/bookings
# Respuesta: igual a V2 ("source": "Mock Service")
```

### 4.4 Simular problema y ejecutar rollback

```powershell
# Simular que V2 tiene problemas (en demo real podría ser performance, bugs, etc.)
Write-Host "🚨 V2 presenta problemas - ejecutando rollback..."

# Rollback automatizado
.\rollback.ps1

# El script realiza:
# 1. Reconfigura nginx para apuntar a V1
# 2. Reinicia nginx
# 3. Detiene y elimina V2
# 4. Verifica que V1 funciona
# 5. Preserva datos en base compartida
```

### 4.5 Verificar rollback exitoso

```powershell
# Estado final del sistema
docker-compose ps
# Debe mostrar solo: hotel_api_v1, hotel_nginx, hotel_casino_db
# (V2 eliminado)

# Nginx ahora apunta a V1
curl http://localhost:8080/health
# Respuesta: "healthy - rollback to v1 completed"

# Datos preservados en PostgreSQL
curl http://localhost:8080/bookings
# Respuesta: "source": "PostgreSQL" (todos los datos intactos)

# V2 no debe responder (eliminado)
curl http://localhost:3001/health
# Error: connection refused (esperado)
```

### 🎯 Puntos Clave de la Demostración

- **Zero downtime**: Sistema disponible durante todo el rollback
- **Datos preservados**: Base PostgreSQL compartida mantiene toda la información
- **Blue-green deployment**: V1 y V2 corriendo en paralelo antes del rollback
- **Automatizado**: Script `rollback.ps1` maneja toda la complejidad
- **Recuperación rápida**: Vuelta a versión estable en segundos
- **Load balancer**: nginx maneja el routing transparentemente

---

## � 5. NGINX COMO LOAD BALANCER

### Puertos y routing del sistema

```powershell
# Acceso directo a versiones específicas
curl http://localhost:3000/bookings  # V1 siempre
curl http://localhost:3001/bookings  # V2 (cuando esté activo)

# Acceso a través de nginx (versión activa configurada)
curl http://localhost:8080/bookings  # Dirigido por nginx
```

### Health checks para verificar routing

```powershell
# Verificar qué versión está activa en nginx
curl http://localhost:8080/health

# Posibles respuestas:
# "healthy - v1.0.0" → Nginx apunta a V1
# "healthy - v2 deployment active" → Nginx apunta a V2
# "healthy - rollback to v1 completed" → Rollback ejecutado exitosamente
```

### Estados del sistema

1. **Estado inicial**: nginx → V1
2. **Tras deploy-v2.ps1**: nginx → V2, V1 disponible en :3000
3. **Tras rollback.ps1**: nginx → V1, V2 eliminado

---

## 🎭 6. SCRIPT PARA DEMO DE 5 MINUTOS

```powershell
# Demo completa automatizada
Write-Host "🎯 === DEMO TFU2 - TÁCTICAS DE ARQUITECTURA ==="

Write-Host "📌 1. Despliegue inicial"
.\deploy.ps1
curl http://localhost:3000/health

Write-Host "📌 2. Demostrar Deferred Binding: PostgreSQL → Mock"
curl http://localhost:3000/bookings  # Ver "source": "PostgreSQL"
.\set-booking-mode-final.ps1 -Mode mock
docker-compose up -d --force-recreate backend_v1
curl http://localhost:3000/bookings  # Ver "source": "Mock Service"

Write-Host "📌 3. Regresar a PostgreSQL"
.\set-booking-mode-final.ps1 -Mode pg
docker-compose up -d --force-recreate backend_v1
curl http://localhost:3000/bookings  # Ver "source": "PostgreSQL"

Write-Host "📌 4. Demo Rollback: V1 → V2 → Rollback"
.\deploy-v2.ps1
curl http://localhost:3000/health     # V1
curl http://localhost:3001/health     # V2
curl http://localhost:8080/health     # nginx → V2

Write-Host "📌 5. Ejecutar rollback"
.\rollback.ps1
curl http://localhost:8080/health     # nginx → V1
curl http://localhost:8080/bookings   # Datos preservados

Write-Host "✅ Demo completada - Ambas tácticas demostradas!"
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
