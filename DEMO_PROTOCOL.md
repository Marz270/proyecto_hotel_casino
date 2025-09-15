# 🎯 Protocolo de Demostración TFU2 - 5 Minutos

## ⏰ Timeline de Demostración

**Total: 5 minutos**  
**Objetivo**: Demostrar tácticas **Deferred Binding** y **Rollback** para NFRs

---

## 📋 Pre-Demo Checklist (30 segundos)

```powershell
# Verificar prerequeritos
docker --version
docker-compose --version
Get-Content .env | Select-String "BOOKING_MODE"  # Debe ser: BOOKING_MODE=pg
```

✅ Docker Desktop corriendo  
✅ Puertos libres: 3000, 3001, 8080, 5432  
✅ PowerShell con permisos de ejecución

---

## 🎬 DEMOSTRACIÓN

### ⏱️ Minuto 1: Setup Inicial + Táctica "Deferred Binding"

```powershell
# [15s] Despliegue completo
Write-Host "🚀 Desplegando sistema completo..."
.\deploy.ps1

# [10s] Verificar funcionamiento
Write-Host "✅ Sistema activo - Verificando PostgreSQL..."
curl http://localhost:3000/bookings

# [35s] Demostrar Factory Pattern - PostgreSQL → Mock
Write-Host "🔄 Demostrando Deferred Binding: PostgreSQL → Mock Service"
Write-Host "📊 Estado inicial:" -ForegroundColor Yellow
curl http://localhost:3000/bookings | ConvertFrom-Json | Select-Object source, count

Write-Host "🔧 Cambiando configuración (sin recompilar código)..." -ForegroundColor Yellow
.\set-booking-mode-final.ps1 -Mode mock
docker-compose up -d --force-recreate backend_v1

Write-Host "📊 Nuevo estado:" -ForegroundColor Green
curl http://localhost:3000/bookings | ConvertFrom-Json | Select-Object source, count
```

**Puntos clave a mencionar:**

- ✨ **Mismo código ejecutándose**
- 🔀 **Diferentes implementaciones** (PostgreSQL vs Mock)
- ⚙️ **Factory Pattern** decide qué servicio usar
- 🌐 **Configuración externa** - sin recompilar

---

### ⏱️ Minuto 2: Regresar a PostgreSQL

```powershell
# [25s] Cambio de vuelta a PostgreSQL
Write-Host "🔄 Regresando a PostgreSQL..."
.\set-booking-mode-final.ps1 -Mode pg
docker-compose up -d --force-recreate backend_v1

Write-Host "📊 Datos reales preservados:" -ForegroundColor Green
curl http://localhost:3000/bookings | ConvertFrom-Json | Select-Object source, count

# [35s] Preparar para Rollback
Write-Host "🎯 Preparando demostración de Rollback..."
Write-Host "V1 estable funcionando en PostgreSQL" -ForegroundColor Green
```

**Puntos clave a mencionar:**

- 💾 **Datos persistentes** - PostgreSQL mantuvo toda la información
- ⚡ **Cambio instantáneo** - sin downtime
- 🏗️ **NFR: Modifiability** - sistema flexible ante cambios

---

### ⏱️ Minuto 3-4: Táctica "Rollback" (Blue-Green)

```powershell
# [30s] Desplegar V2 (Blue-Green)
Write-Host "🚀 Desplegando V2 (Blue-Green deployment)..." -ForegroundColor Cyan
.\deploy-v2.ps1

Write-Host "📊 Estado del sistema - Ambas versiones activas:"
docker-compose ps | Select-String "hotel_api"

# [30s] Verificar ambas versiones
Write-Host "🔍 Verificando ambas versiones paralelas:" -ForegroundColor Yellow
Write-Host "V1 (directo):" -NoNewline
curl http://localhost:3000/health

Write-Host "V2 (directo):" -NoNewline
curl http://localhost:3001/health

Write-Host "Nginx (load balancer - apunta a V2):" -NoNewline
curl http://localhost:8080/health

# [30s] Mostrar diferencia de datos
Write-Host "📊 Comparando fuentes de datos:" -ForegroundColor Yellow
Write-Host "V1 (PostgreSQL):" -NoNewline
curl http://localhost:3000/bookings | ConvertFrom-Json | Select-Object source

Write-Host "V2 (Mock Service):" -NoNewline
curl http://localhost:3001/bookings | ConvertFrom-Json | Select-Object source

# [30s] Simular problema con V2
Write-Host "🚨 PROBLEMA: V2 presenta issues - ejecutando rollback..." -ForegroundColor Red
.\rollback.ps1
```

**Puntos clave a mencionar:**

- 🔄 **Blue-Green deployment** - dos versiones paralelas
- 🌐 **nginx load balancer** - routing transparente
- 📊 **V1: PostgreSQL real** vs **V2: Mock data**
- 🚨 **Problema simulado** - necesidad de rollback

---

### ⏱️ Minuto 5: Verificación Post-Rollback

```powershell
# [30s] Verificar rollback exitoso
Write-Host "✅ Verificando rollback exitoso:" -ForegroundColor Green

Write-Host "Estado del sistema (V2 eliminado):"
docker-compose ps | Select-String "hotel_api"

Write-Host "nginx apunta de vuelta a V1:"
curl http://localhost:8080/health

Write-Host "Datos preservados en PostgreSQL:"
curl http://localhost:8080/bookings | ConvertFrom-Json | Select-Object source, count

Write-Host "V2 no responde (eliminado):" -ForegroundColor Red
try { curl http://localhost:3001/health } catch { Write-Host "❌ Connection refused (esperado)" }

# [30s] Resumen de NFRs cumplidos
Write-Host "🎯 RESUMEN - NFRs DEMOSTRADOS:" -ForegroundColor Green -BackgroundColor Black
Write-Host "✅ MODIFIABILITY: Factory Pattern + Deferred Binding"
Write-Host "✅ DEPLOYABILITY: Blue-Green + Rollback automático"
Write-Host "✅ SECURITY: Input validation (express-validator)"
Write-Host "✅ PERFORMANCE: Connection pooling PostgreSQL"
```

**Puntos clave finales:**

- 🚀 **Zero downtime** - sistema disponible siempre
- 💾 **Data integrity** - datos preservados
- ⚡ **Rollback rápido** - segundos, no minutos
- 🏗️ **Architectural tactics** - cumplidos exitosamente

---

## 🎤 Script de Narrativa para Presentador

### Introducción (Paralelo al Minuto 1)

> "Buenos días. Voy a demostrar las tácticas de arquitectura implementadas en nuestro TFU2. Tenemos un sistema de reservas de hotel que debe cumplir requerimientos no funcionales críticos: **modifiability** y **deployability**."

### Durante Deferred Binding (Minuto 1-2)

> "Observen cómo el mismo código puede usar diferentes implementaciones. Inicialmente usa PostgreSQL con datos reales. Ahora cambio la configuración externa - sin recompilar - y usa un Mock Service. Esto es **Deferred Binding** mediante Factory Pattern."

### Durante Blue-Green (Minuto 3-4)

> "Ahora demostramos **Rollback**. Despliego la versión 2 en paralelo a la versión 1. Ambas comparten la base de datos pero V2 usa datos ficticios para esta demo. El load balancer nginx dirige tráfico a V2."

### Durante Rollback (Minuto 4-5)

> "V2 presenta problemas - ejecuto rollback automático. En segundos, nginx vuelve a dirigir tráfico a V1, elimina V2, y todos los datos reales se preservan. Zero downtime, data integrity completa."

### Conclusión (Minuto 5)

> "Hemos demostrado exitosamente ambas tácticas: **Modifiability** via Deferred Binding y **Deployability** via Rollback, cumpliendo los NFRs del sistema."

---

## ⚠️ Troubleshooting Durante Demo

### Si falla el force-recreate

```powershell
# Fallback: detener y levantar
docker-compose down backend_v1
docker-compose up -d backend_v1
```

### Si puertos están ocupados

```powershell
# Check rápido
netstat -an | Select-String ":3000|:3001|:8080"
# Matar proceso si es necesario
```

### Si V2 no se levanta

```powershell
# Logs rápidos
docker-compose logs backend_v2 | Select-Object -Last 10
```

---

## 📊 Métricas de Éxito de la Demo

**✅ Deferred Binding:**

- Campo "source" cambia de "PostgreSQL" → "Mock Service" → "PostgreSQL"
- Mismo endpoint, diferentes implementaciones
- Sin recompilar código

**✅ Rollback:**

- V1 y V2 ejecutándose paralelas
- nginx switching de V2 a V1
- V2 eliminado, datos preservados en V1

**✅ NFRs Validados:**

- Modifiability ✅
- Deployability ✅
- Security ✅ (validation)
- Performance ✅ (pooling)

---

**Protocolo actualizado - Septiembre 2025**  
**Duración total: 5 minutos** ⏰
