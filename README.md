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
# Respuesta: "source": "PostgreSQL"

# 2. Cambiar a modo Mock
echo "BOOKING_MODE=mock" > .env
docker-compose restart backend_v1

# 3. Verificar cambio de implementación
curl http://localhost:3000/bookings
# Respuesta: "source": "Mock Service"
```

### 2. Demostración de "Rollback"

```bash
# 1. Desplegar v2
./deploy-v2.sh  # o .\deploy-v2.ps1 en Windows

# 2. Verificar ambas versiones
curl http://localhost:3000  # v1: "version": "1.0.0"
curl http://localhost:3001  # v2: "version": "2.0.0"

# 3. Crear datos en v2
curl -X POST http://localhost:3001/bookings -H "Content-Type: application/json" -d '{"client_name": "Test Rollback", "room_number": 999, "check_in": "2025-12-01", "check_out": "2025-12-02", "total_price": 100.00}'

# 4. Ejecutar rollback
./rollback.sh  # o .\rollback.ps1 en Windows

# 5. Verificar datos preservados
curl http://localhost:3000/bookings  # Los datos creados en v2 siguen ahí
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
├── docker-compose.yaml        # Orquestación multi-versión
├── deploy.sh / deploy.ps1     # Scripts de despliegue inicial
├── deploy-v2.sh / deploy-v2.ps1     # Scripts de despliegue v2
├── rollback.sh / rollback.ps1 # Scripts de rollback
├── MANUAL_USUARIO.md          # Manual completo con ejemplos curl
└── Hotel-Casino-API.postman_collection.json  # Colección Postman
```

---

## 🎯 Endpoints de la API

| Método | Endpoint        | Descripción                   |
| ------ | --------------- | ----------------------------- |
| GET    | `/`             | Información general de la API |
| GET    | `/bookings`     | Listar todas las reservas     |
| POST   | `/bookings`     | Crear nueva reserva           |
| GET    | `/bookings/:id` | Obtener reserva por ID        |
| DELETE | `/bookings/:id` | Eliminar reserva              |

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

```bash
# Ver logs en tiempo real
docker-compose logs -f

# Estado de contenedores
docker-compose ps

# Acceder a base de datos
docker-compose exec db psql -U hoteluser -d hotel_casino

# Limpiar todo el sistema
docker-compose down --volumes --remove-orphans

# Cambiar modo de binding (editar .env)
echo "BOOKING_MODE=mock" > .env
docker-compose restart backend_v1
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

## 🎉 Demo Rápida (5 minutos)

```bash
# 1. Desplegar sistema (30s)
./deploy.sh

# 2. Probar Diferir Binding (60s)
curl http://localhost:3000/bookings  # PostgreSQL
echo "BOOKING_MODE=mock" > .env && docker-compose restart backend_v1
curl http://localhost:3000/bookings  # Mock

# 3. Resetear y demo Rollback (150s)
echo "BOOKING_MODE=pg" > .env && docker-compose restart backend_v1
./deploy-v2.sh  # Desplegar v2
curl http://localhost:3001/bookings  # Probar v2
./rollback.sh   # Rollback sin pérdida

# 4. Verificar datos preservados (30s)
curl http://localhost:3000/bookings  # Datos intactos
```

**¡Sistema listo para demostración del TFU2!** 🚀
