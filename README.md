# 🏨 Salto Hotel & Casino - API de Reservas

## 🎯 TFU2 - Análisis y Diseño de Aplicaciones II

**Trabajo Final Unidad 2** que demuestra la aplicación de **tácticas de arquitectura** para cumplir requerimientos no funcionales (RNF) mediante una API REST containerizada.

### 🏗️ Tácticas de Arquitectura Implementadas

1. **🔗 Diferir Binding**

   - Inyección de dependencias con Factory Pattern
   - Configuración externa via variables de entorno (`BOOKING_MODE=pg|mock`)
   - Cambio de implementación en runtime sin recompilación

2. **🔄 Rollback (Facilidad de Despliegue)**
   - Despliegue blue-green con múltiples versiones
   - Rollback automático sin pérdida de datos
   - Base de datos persistente entre versiones

---

## 🛠️ Stack Tecnológico

- **Backend**: Node.js + Express.js
- **Base de Datos**: PostgreSQL 15
- **Containerización**: Docker + Docker Compose
- **Proxy**: Nginx (para demostración de switcheo)
- **Validación**: express-validator
- **Arquitectura**: CommonJS (require/module.exports)

---

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker y Docker Compose instalados
- Puerto 3000, 3001 y 5432 disponibles

### Despliegue inicial

```bash
# Windows (PowerShell)
.\deploy.ps1

# Linux/Mac
chmod +x *.sh
./deploy.sh
```

### Probar la API

```bash
# Info general
curl http://localhost:3000

# Ver reservas
curl http://localhost:3000/bookings

# Crear reserva
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -d '{"client_name": "Juan Pérez", "room_number": 101, "check_in": "2025-10-01", "check_out": "2025-10-03", "total_price": 250.00}'
```

---

## 🎭 Demo de Tácticas de Arquitectura

### 1. Demostración de "Diferir Binding"

```bash
# 1. Modo PostgreSQL (por defecto)
curl http://localhost:3000/bookings
# Respuesta: "source": "PostgreSQL", 4+ registros reales

# 2. Cambiar a modo Mock usando script
.\set-booking-mode-final.ps1 -Mode mock   # Windows
# o editar .env manualmente: BOOKING_MODE=mock

# 3. IMPORTANTE: Recrear contenedor (NO solo restart)
docker-compose up -d --force-recreate backend_v1

# 4. Verificar cambio de implementación
curl http://localhost:3000/bookings
# Respuesta: "source": "Mock Service", 2 registros ficticios

# 5. Cambiar de vuelta a PostgreSQL
.\set-booking-mode-final.ps1 -Mode pg
docker-compose up -d --force-recreate backend_v1
curl http://localhost:3000/bookings
# Respuesta: "source": "PostgreSQL" otra vez
```

### 2. Demostración de "Rollback"

```bash
# 1. Desplegar v2 (usa Profile de Docker Compose)
.\deploy-v2.ps1  # Windows
# ./deploy-v2.sh   # Linux/Mac

# 2. Verificar ambas versiones activas
curl http://localhost:3000/health   # v1: "healthy - v1.0.0"
curl http://localhost:3001/health   # v2: "healthy - v2.0.0"
curl http://localhost:8080/health   # nginx: "healthy - v2 deployment active"

# 3. Comparar datos entre versiones
curl http://localhost:3000/bookings  # v1: PostgreSQL, 4+ registros
curl http://localhost:3001/bookings  # v2: Mock, 2 registros ficticios

# 4. Crear datos adicionales en v1 (será preservado)
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -d '{"client_name": "Test Rollback", "room_number": 999, "check_in": "2025-12-01", "check_out": "2025-12-02", "total_price": 100.00}'

# 5. Ejecutar rollback completo
.\rollback.ps1   # Windows
# ./rollback.sh    # Linux/Mac

# 6. Verificar estado post-rollback
curl http://localhost:8080/health   # nginx: "healthy - rollback to v1 completed"
curl http://localhost:8080/bookings # Datos preservados + nuevos registros
docker-compose ps                   # Solo v1, db y nginx activos (v2 eliminado)
```

---

## 📁 Estructura del Proyecto

```
proyecto_hotel_casino/
├── backend/
│   ├── server.js              # Servidor Express principal
│   ├── routes/
│   │   └── index.routes.js    # Endpoints REST (/bookings)
│   ├── services/
│   │   ├── bookingService.pg.js      # Implementación PostgreSQL
│   │   ├── bookingService.mock.js    # Implementación Mock
│   │   └── bookingServiceFactory.js  # Factory (Diferir Binding)
│   ├── database/
│   │   ├── db.js              # Pool de conexión PostgreSQL
│   │   └── scripts/
│   │       └── 01-init.sql    # Inicialización de BD
│   └── Dockerfile             # Container del backend
├── nginx/
│   └── nginx.conf             # Configuración proxy para rollback
├── docker-compose.yaml        # Orquestación multi-versión
├── deploy.ps1                 # Script de despliegue inicial (Windows)
├── deploy-v2.ps1              # Script de despliegue v2 (Windows)
├── rollback.ps1               # Script de rollback (Windows)
├── shutdown.ps1               # Script para apagar servicios
├── set-booking-mode-final.ps1 # Script para cambiar BOOKING_MODE
├── demo-deferred-binding.ps1  # Demo automatizada de Deferred Binding
├── .env                       # Variables de entorno (BOOKING_MODE, DB config)
└── README.md                  # Esta documentación
```

---

## 🎯 Endpoints de la API

| Método | Endpoint        | Descripción                   | Puerto         |
| ------ | --------------- | ----------------------------- | -------------- |
| GET    | `/`             | Información general de la API | 3000/3001      |
| GET    | `/health`       | Health check con versión      | 3000/3001/8080 |
| GET    | `/bookings`     | Listar todas las reservas     | 3000/3001      |
| POST   | `/bookings`     | Crear nueva reserva           | 3000/3001      |
| GET    | `/bookings/:id` | Obtener reserva por ID        | 3000/3001      |
| DELETE | `/bookings/:id` | Eliminar reserva              | 3000/3001      |

**Puertos importantes:**

- **3000**: Backend V1 (directo)
- **3001**: Backend V2 (directo, solo cuando está activo)
- **8080**: Nginx proxy (apunta a la versión activa)
- **5432**: PostgreSQL (acceso directo para debugging)

### Ejemplo de respuesta JSON:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "client_name": "Juan Pérez",
      "room_number": 101,
      "check_in": "2025-09-15",
      "check_out": "2025-09-17",
      "total_price": 300.0,
      "created_at": "2025-09-13T10:30:00.000Z"
    }
  ],
  "source": "PostgreSQL",
  "count": 1
}
```

---

## 🧪 Validación de Requerimientos No Funcionales

### ✅ NFR-1: Facilidad de Despliegue (Rollback)

- **Implementado**: Scripts automatizados + Docker Compose multi-versión
- **Demo**: `./deploy-v2.sh` → `./rollback.sh` sin pérdida de datos

### ✅ NFR-2: Modificabilidad (Diferir Binding)

- **Implementado**: Factory Pattern + configuración externa
- **Demo**: Cambio `BOOKING_MODE=pg|mock` sin recompilar

### ✅ NFR-3: Seguridad (Validación)

- **Implementado**: `express-validator` + manejo centralizado de errores
- **Demo**: Requests con datos inválidos retornan HTTP 400

### ✅ NFR-4: Rendimiento (Pooling)

- **Implementado**: PostgreSQL connection pool + configuración optimizada
- **Demo**: Conexiones reutilizadas entre requests

---

## 📋 Comandos Útiles

### 🔧 Gestión de Servicios

```bash
# Ver estado de contenedores
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f backend_v1

# Limpiar todo el sistema
.\shutdown.ps1  # Apagado ordenado
docker-compose down --volumes --remove-orphans  # Limpieza completa
```

### 🔄 Deferred Binding

```bash
# Cambiar implementación de datos
.\set-booking-mode-final.ps1 -Mode mock    # Cambiar a Mock
.\set-booking-mode-final.ps1 -Mode pg      # Cambiar a PostgreSQL

# IMPORTANTE: Siempre recrear después del cambio
docker-compose up -d --force-recreate backend_v1

# Verificar variable de entorno en contenedor
docker exec hotel_api_v1 env | Select-String "BOOKING"
```

### 🗄️ Base de Datos

```bash
# Acceder a PostgreSQL
docker-compose exec db psql -U hoteluser -d hotel_casino

# Ver datos directamente
docker-compose exec db psql -U hoteluser -d hotel_casino -c "SELECT * FROM bookings;"

# Backup de datos
docker-compose exec db pg_dump -U hoteluser hotel_casino > backup.sql
```

### 📊 Testing y Debugging

```bash
# Probar endpoints directamente
curl http://localhost:3000/bookings    # V1 directo
curl http://localhost:3001/bookings    # V2 directo (si está activo)
curl http://localhost:8080/bookings    # A través de nginx

# Verificar health checks
curl http://localhost:3000/health
curl http://localhost:8080/health

# PowerShell testing
$response = Invoke-WebRequest -Uri "http://localhost:3000/bookings" -Method GET
$data = $response.Content | ConvertFrom-Json
Write-Host "Source: $($data.source), Count: $($data.count)"
```

---

## 📚 Documentación Adicional

- **[Manual de Usuario](MANUAL_USUARIO.md)** - Guía completa con ejemplos curl
- **[Testing Guide](TESTING.md)** - Casos de prueba y validación
- **[Postman Collection](Hotel-Casino-API.postman_collection.json)** - Colección de requests

---

## 👥 Información Académica

- **Materia**: Análisis y Diseño de Aplicaciones II
- **Trabajo**: TFU2 - Tácticas de Arquitectura
- **Objetivo**: Demostrar aplicación de tácticas para RNF
- **Duración Demo**: 5 minutos
- **Año**: 2025

---

## 🎉 Demo Rápida para TFU2 (5 minutos)

### ⚡ Protocolo de Demostración Académica

```bash
# 1. DESPLIEGUE INICIAL (30s)
.\deploy.ps1
curl http://localhost:3000/health  # Verificar: "healthy - v1.0.0"

# 2. DEMO DEFERRED BINDING (120s)
# Probar PostgreSQL inicial
curl http://localhost:3000/bookings
# Mostrar: "source": "PostgreSQL", 4+ registros

# Cambiar a Mock Service
.\set-booking-mode-final.ps1 -Mode mock
docker-compose up -d --force-recreate backend_v1
curl http://localhost:3000/bookings
# Mostrar: "source": "Mock Service", 2 registros ficticios

# Volver a PostgreSQL
.\set-booking-mode-final.ps1 -Mode pg
docker-compose up -d --force-recreate backend_v1
curl http://localhost:3000/bookings
# Mostrar: "source": "PostgreSQL" otra vez

# 3. DEMO ROLLBACK (120s)
# Desplegar V2
.\deploy-v2.ps1
curl http://localhost:8080/health   # nginx: "v2 deployment active"
curl http://localhost:3000/bookings # V1: PostgreSQL data
curl http://localhost:3001/bookings # V2: Mock data

# Ejecutar rollback
.\rollback.ps1
curl http://localhost:8080/health   # nginx: "rollback to v1 completed"
docker-compose ps                   # Solo V1 activo (V2 eliminado)

# 4. VERIFICACIÓN FINAL (30s)
curl http://localhost:8080/bookings # Datos preservados
# Mostrar: persistencia de datos sin pérdida
```

### 🎯 Scripts de Demo Automatizada

```bash
# Demo completa automatizada
.\demo-deferred-binding.ps1 -DemoType complete

# Solo Deferred Binding
.\demo-deferred-binding.ps1 -DemoType pg-to-mock

# Solo Rollback
.\deploy-v2.ps1
.\rollback.ps1
```

### 📝 Puntos Clave para la Presentación

1. **Deferred Binding**: Mismo código, diferente comportamiento según configuración
2. **No recompilación**: Solo cambio de variables de entorno
3. **Rollback sin pérdida**: Base de datos persistente entre versiones
4. **Blue-Green deployment**: V1 y V2 simultáneos con switch instantáneo
5. **Factory Pattern**: Un punto decide qué implementación usar

**¡Sistema listo para demostración del TFU2!** 🚀

---

## 🐛 Troubleshooting y Problemas Comunes

### ❌ Problema: Deferred Binding no cambia tras modificar .env

**Síntoma**: `curl http://localhost:3000/bookings` sigue mostrando el mismo "source"

**Causa**: `docker-compose restart` NO actualiza variables de entorno

**Solución**:

```bash
# ❌ INCORRECTO
docker-compose restart backend_v1

# ✅ CORRECTO
docker-compose up -d --force-recreate backend_v1
```

### ❌ Problema: Variables de entorno con caracteres Unicode

**Síntoma**: "contains non-standard Unicode characters (null bytes or invisible characters)"

**Solución**:

```bash
# Usar script de limpieza
.\set-booking-mode-final.ps1 -Mode pg
```

### ❌ Problema: Puerto ocupado o servicios no responden

**Síntoma**: "Cannot connect to the server" o "Port already in use"

**Solución**:

```bash
# Verificar puertos ocupados (Windows)
netstat -ano | findstr :3000
netstat -ano | findstr :5432

# Limpiar sistema completamente
.\shutdown.ps1
docker system prune -f
.\deploy.ps1
```

### ❌ Problema: V2 no se despliega en deploy-v2.ps1

**Síntoma**: `docker-compose ps` no muestra backend_v2

**Causa**: V2 usa profiles de Docker Compose

**Verificación**:

```bash
# Debe mostrar backend_v2 activo
docker-compose --profile v2 ps

# Si no aparece, revisar logs
docker-compose --profile v2 logs backend_v2
```

### ❌ Problema: Rollback no elimina V2

**Síntoma**: `docker-compose ps` sigue mostrando backend_v2 tras rollback

**Solución**:

```bash
# Forzar eliminación manual
docker-compose --profile v2 down
docker container rm hotel_api_v2 -f
```

### 🔍 Comandos de Diagnóstico

```bash
# Verificar variables de entorno del contenedor
docker exec hotel_api_v1 env | Select-String "BOOKING"

# Ver configuración actual de nginx
docker exec hotel_nginx cat /etc/nginx/nginx.conf

# Estado completo del sistema
docker-compose ps
docker network ls | Select-String "hotel"
docker volume ls | Select-String "hotel"

# Verificar salud de servicios
curl http://localhost:3000/health
curl http://localhost:8080/health
```
