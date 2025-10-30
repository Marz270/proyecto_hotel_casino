# 🎯 Guía de Ejecución - TFU3 Demo

**Análisis y Diseño de Aplicaciones II - Trabajo Final Unidad 3**  
**Sistema de Reservas Salto Hotel & Casino**

## 📋 Prerrequisitos

Antes de ejecutar la demo, asegúrate de tener instalado:

- ✅ **Docker Desktop** (versión 4.0 o superior)
- ✅ **Docker Compose** (incluido con Docker Desktop)
- ✅ **PowerShell** (Windows) o **Bash** (Linux/macOS)
- ✅ Puertos disponibles: **3000, 3001, 4200, 5432, 8080**

## 🚀 Inicio Rápido (5 minutos)

### 1. Clonar y Preparar el Proyecto

```powershell
# Navegar al directorio del proyecto
cd proyecto_hotel_casino

# Verificar que todos los archivos estén presentes
ls
```

### 2. Despliegue Inicial

```powershell
# Desplegar todo el stack
.\deploy.ps1

# O manualmente:
docker-compose up -d
```

**⏳ Tiempo estimado:** 2-3 minutos para la primera ejecución

### 3. Verificar el Sistema

```powershell
# Ejecutar demo completa
.\demo-tfu3.ps1
```

### 4. Acceder a las Interfaces

- 🖥️ **Frontend Angular:** http://localhost:4200
- 🔧 **API Backend:** http://localhost:3000
- ⚖️ **Load Balancer:** http://localhost:8080
- 📊 **Base de datos:** localhost:5432

---

## 🎭 Demos Especializadas

### Demo 1: Arquitectura de Componentes

```powershell
# Ejecutar demo principal
.\demo-tfu3.ps1
```

**Qué demuestra:**

- ✅ Consulta de habitaciones disponibles
- ✅ Creación de reservas
- ✅ Procesamiento de pagos
- ✅ Generación de reportes administrativos
- ✅ Integración frontend-backend

### Demo 2: Diferir Binding (Táctica de Arquitectura)

```powershell
# Demo de cambio de implementación
.\demo-binding.ps1
```

**Qué demuestra:**

- 🔗 Factory Pattern en acción
- 🔧 Cambio PostgreSQL ↔ Mock sin recompilación
- ⚙️ Configuración externa via variables de entorno
- 🔄 Reinicio sin pérdida de servicio

### Demo 3: Escalado Horizontal

```powershell
# Demo de escalabilidad
.\demo-escalado.ps1
```

**Qué demuestra:**

- 📈 Escalado de 1 a 3 instancias
- ⚖️ Load balancing automático
- 📊 Monitoreo de recursos
- ⬇️ Escalado hacia abajo

### Demo 4: Rollback (Disponibilidad)

```powershell
# Desplegar versión 2
.\deploy-v2.ps1

# Probar nueva versión en puerto 3001
curl http://localhost:3001

# Ejecutar rollback
.\rollback.ps1
```

**Qué demuestra:**

- 🔄 Despliegue de múltiples versiones
- 🛡️ Rollback sin pérdida de datos
- 🗄️ Base de datos compartida entre versiones

---

## 🌐 Interfaces de Usuario

### Frontend Angular (http://localhost:4200)

**Pestañas disponibles:**

1. **🏠 Habitaciones**

   - Consultar disponibilidad por fechas
   - Ver detalles de habitaciones
   - Iniciar proceso de reserva

2. **📅 Reservas**

   - Listar todas las reservas
   - Crear nueva reserva
   - Eliminar reservas existentes

3. **📊 Reportes**
   - Resumen ejecutivo
   - Tasa de ocupación
   - Ingresos por mes

### API REST (http://localhost:3000)

**Endpoints principales:**

```http
GET    /                    # Info de la API
GET    /rooms              # Habitaciones disponibles
GET    /bookings           # Listar reservas
POST   /reservations       # Crear reserva
POST   /payments           # Procesar pago
GET    /reports            # Reportes administrativos
DELETE /bookings/:id       # Eliminar reserva
```

**Ejemplo de uso con curl:**

```powershell
# Consultar habitaciones
curl http://localhost:3000/rooms

# Crear reserva
curl -X POST http://localhost:3000/reservations `
  -H "Content-Type: application/json" `
  -d '{"client_name": "Juan Pérez", "room_number": 101, "check_in": "2024-12-25", "check_out": "2024-12-27", "total_price": 300.00}'

# Ver reportes
curl http://localhost:3000/reports
```

---

## 🧪 Casos de Prueba Recomendados

### Prueba 1: Flujo Completo de Reserva

1. Abrir frontend en http://localhost:4200
2. Ir a pestaña **Habitaciones**
3. Seleccionar fechas check-in y check-out
4. Hacer clic en **Buscar**
5. Hacer clic en **Reservar** en una habitación disponible
6. Completar formulario de reserva
7. Verificar reserva en pestaña **Reservas**

### Prueba 2: Reportes Administrativos

1. Ir a pestaña **Reportes**
2. Hacer clic en **Actualizar Reportes**
3. Verificar métricas de ocupación
4. Revisar ingresos por mes
5. Observar resumen ejecutivo

### Prueba 3: Cambio de Implementación

1. Ejecutar `.\demo-binding.ps1`
2. Observar cambio de "PostgreSQL" a "Mock Service"
3. Verificar que datos cambian según la implementación
4. Confirmar que el sistema funciona en ambos modos

### Prueba 4: Escalado y Performance

1. Ejecutar `.\demo-escalado.ps1`
2. Observar múltiples instancias de backend
3. Hacer requests y verificar distribución de carga
4. Monitorear uso de recursos

---

## 🐛 Solución de Problemas

### Problema: Puertos ocupados

```powershell
# Verificar puertos en uso
netstat -an | findstr "3000\|4200\|5432"

# Detener servicios conflictivos
docker-compose down
```

### Problema: Contenedores no inician

```powershell
# Ver logs detallados
docker-compose logs -f

# Reconstruir contenedores
docker-compose build --no-cache
docker-compose up -d
```

### Problema: Frontend no carga

```powershell
# Verificar estado del contenedor frontend
docker-compose ps frontend

# Ver logs de Angular
docker-compose logs frontend
```

### Problema: Base de datos no conecta

```powershell
# Verificar PostgreSQL
docker-compose ps db

# Conectar manualmente a la BD
docker-compose exec db psql -U hoteluser -d hotel_casino
```

---

## 📊 Métricas y Monitoreo

### Verificar Estado del Sistema

```powershell
# Estado de todos los contenedores
docker-compose ps

# Uso de recursos
docker stats --no-stream

# Logs en tiempo real
docker-compose logs -f
```

### Métricas de Performance

```powershell
# Tiempo de respuesta de la API
Measure-Command { curl http://localhost:3000/ }

# Verificar conectividad
Test-NetConnection localhost -Port 3000
```

---

## 🔧 Configuración Avanzada

### Variables de Entorno (.env)

```env
# Modo de servicio de reservas
BOOKING_MODE=pg          # pg | mock

# Base de datos
DB_HOST=db
DB_USER=hoteluser
DB_PASSWORD=casino123
DB_DATABASE=hotel_casino

# Aplicación
NODE_ENV=production
APP_VERSION=1.0.0
```

### Escalado Manual

```powershell
# Escalar backend a N instancias
docker-compose up --scale backend_v1=N -d

# Volver a 1 instancia
docker-compose up --scale backend_v1=1 -d
```

---

## 📚 Documentación Adicional

### Archivos de Referencia

- 📄 `TFU3_ENTREGABLE.md` - Documento principal del TFU3
- 📄 `README.md` - Documentación del proyecto
- 📄 `MANUAL_USUARIO.md` - Manual detallado de usuario
- 🧪 `Hotel-Casino-API-Fixed.postman_collection.json` - Colección Postman

### Estructura del Proyecto

```
proyecto_hotel_casino/
├── 📄 TFU3_ENTREGABLE.md           # ← DOCUMENTO PRINCIPAL TFU3
├── 🐳 docker-compose.yaml         # Orquestación de servicios
├── 🧪 demo-tfu3.ps1               # Demo principal
├── 🧪 demo-binding.ps1             # Demo diferir binding
├── 🧪 demo-escalado.ps1            # Demo escalado horizontal
├── 📁 backend/                     # API Node.js + Express
├── 📁 frontend/                    # SPA Angular
└── 📁 nginx/                       # Load balancer
```

---

## 🎯 Puntos Clave para la Presentación

### 1. Arquitectura de Componentes

- Mostrar diagrama UML del documento
- Explicar partición por dominio vs técnica
- Demostrar interfaces entre componentes

### 2. Decisiones Arquitectónicas

- Justificar contenedores vs VMs
- Explicar ACID vs BASE para reservas
- Mostrar beneficios de cada decisión

### 3. Tácticas Implementadas

- **Diferir Binding:** Factory Pattern + config externa
- **Rollback:** Versionado + BD compartida
- **Escalado:** Docker Compose scaling

### 4. Demo en Vivo

- Frontend funcionando completamente
- API REST respondiendo
- Cambio de implementación en vivo
- Escalado horizontal en tiempo real

---

## ✅ Checklist de Preparación

**Antes de la presentación:**

- [ ] ✅ Docker Desktop ejecutándose
- [ ] ✅ Puertos 3000, 4200, 5432, 8080 disponibles
- [ ] ✅ Proyecto clonado y navegado al directorio
- [ ] ✅ Ejecutado `.\deploy.ps1` exitosamente
- [ ] ✅ Frontend accesible en http://localhost:4200
- [ ] ✅ API respondiendo en http://localhost:3000
- [ ] ✅ Scripts de demo probados
- [ ] ✅ Documento `TFU3_ENTREGABLE.md` revisado

**Durante la demo:**

1. ⏱️ **5 min** - Explicar arquitectura (documento + diagrama)
2. ⏱️ **3 min** - Mostrar frontend funcionando
3. ⏱️ **2 min** - Ejecutar `.\demo-binding.ps1`
4. ⏱️ **2 min** - Ejecutar `.\demo-escalado.ps1`
5. ⏱️ **3 min** - Preguntas y respuestas

---

## 🎓 Entregables del TFU3

✅ **Documento Principal:** `TFU3_ENTREGABLE.md`  
✅ **Código Completo:** Backend + Frontend + Docker  
✅ **Scripts de Demo:** PowerShell para Windows  
✅ **Arquitectura Funcional:** Sistema ejecutándose

---

**🎉 ¡Sistema listo para demostración del TFU3!**

_Análisis y Diseño de Aplicaciones II - 2025_
