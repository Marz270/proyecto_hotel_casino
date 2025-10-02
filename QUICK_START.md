# 🚀 Quick Start - TFU3 Demo

## Sistema de Reservas Salto Hotel & Casino

### ⚡ Inicio Rápido (3 pasos)

#### 1️⃣ Levantar los Servicios

```powershell
# Desde el directorio del proyecto
docker-compose up -d --build
```

**Esperar:** 2-3 minutos para que todos los servicios inicien.

#### 2️⃣ Verificar que Todo Funciona

```powershell
# Ejecutar el script de demostración
.\demo-tfu3.ps1
```

**¿Qué verás?**
- ✅ Estado del Backend API (conectado en puerto 3000)
- ✅ Estado del Frontend Angular (disponible en puerto 4200)
- ✅ Consulta de habitaciones disponibles
- ✅ Creación de reserva de ejemplo
- ✅ Listado de todas las reservas
- ✅ Simulación de pago
- ✅ Reportes administrativos
- 🌐 El navegador se abrirá automáticamente en http://localhost:4200

#### 3️⃣ Explorar el Frontend

Abre tu navegador en: **http://localhost:4200**

**Pestañas disponibles:**
- 🏠 **Habitaciones** - Ver disponibilidad y crear reservas
- 📋 **Reservas** - Gestionar reservas existentes
- 📊 **Reportes** - Dashboard administrativo con métricas

---

## 🔧 Servicios Disponibles

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Frontend Angular | http://localhost:4200 | Interfaz de usuario |
| Backend API | http://localhost:3000 | API REST principal |
| Load Balancer (Nginx) | http://localhost:8080 | Proxy inverso |
| PostgreSQL | localhost:5432 | Base de datos |

---

## 🎭 Demos Adicionales

### Demo de Diferir Binding (Cambio de implementación)
```powershell
.\demo-binding.ps1
```
Demuestra cómo cambiar entre PostgreSQL y Mock sin recompilar.

### Demo de Escalado Horizontal
```powershell
.\demo-escalado.ps1
```
Muestra cómo escalar el backend a múltiples instancias.

### Demo de Rollback (Versión 2 y vuelta a Versión 1)
```powershell
# Desplegar versión 2
.\deploy-v2.ps1

# Hacer rollback a versión 1
.\rollback.ps1
```

---

## 🐛 Solución de Problemas

### ❌ Error: "docker-compose: command not found"
**Solución:** Instala Docker Desktop desde https://www.docker.com/products/docker-desktop

### ❌ Error: "port is already allocated"
**Solución:** Detén los servicios existentes
```powershell
docker-compose down
# Espera unos segundos
docker-compose up -d
```

### ❌ Frontend no se abre automáticamente
**Solución:** Abre manualmente http://localhost:4200 en tu navegador. 
El frontend puede tardar 2-3 minutos en compilar la primera vez.

### ❌ API retorna 404
**Solución:** Verifica que el backend esté corriendo:
```powershell
docker-compose ps
# Deberías ver hotel_api_v1 con estado "Up"

# Ver logs del backend
docker-compose logs -f backend_v1
```

---

## 📚 Documentación Completa

- **TFU3_ENTREGABLE.md** - Documento académico completo con justificaciones
- **GUIA_EJECUCION_TFU3.md** - Guía detallada de ejecución
- **README.md** - Información general del proyecto

---

## ✅ Checklist para la Presentación

- [ ] Docker Desktop está corriendo
- [ ] Ejecuté `docker-compose up -d --build` con éxito
- [ ] Ejecuté `.\demo-tfu3.ps1` y vi resultados positivos
- [ ] Puedo abrir http://localhost:4200 y ver el frontend
- [ ] Puedo crear una reserva desde el frontend
- [ ] Puedo ver reportes en la pestaña de Reportes
- [ ] Revisé el documento TFU3_ENTREGABLE.md

---

## 🎓 Para la Presentación

**Orden sugerido:**

1. **Mostrar Arquitectura** (5 min)
   - Abrir TFU3_ENTREGABLE.md
   - Explicar diagrama de componentes
   - Justificar partición por dominio

2. **Demo en Vivo** (10 min)
   - Ejecutar `.\demo-tfu3.ps1`
   - Abrir frontend en http://localhost:4200
   - Crear reserva desde interfaz web
   - Mostrar reportes administrativos

3. **Tácticas de Arquitectura** (5 min)
   - Demo de Diferir Binding: `.\demo-binding.ps1`
   - Explicar ACID vs BASE (TFU3_ENTREGABLE.md sección 5)
   - Mostrar Contenedores vs VMs (TFU3_ENTREGABLE.md sección 4)

**Tiempo total:** ~20 minutos

---

## 🎯 Endpoints de la API para Testing Manual

```bash
# Info de la API
curl http://localhost:3000/

# Ver habitaciones
curl http://localhost:3000/rooms

# Ver reservas
curl http://localhost:3000/bookings

# Crear reserva
curl -X POST http://localhost:3000/reservations \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Test User",
    "room_number": 101,
    "check_in": "2025-12-20",
    "check_out": "2025-12-22",
    "total_price": 400.00
  }'

# Ver reportes
curl http://localhost:3000/reports
```

---

**¡Éxito en tu presentación! 🎓**
