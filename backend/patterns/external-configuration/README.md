# External Configuration Store Pattern

## Descripción

El patrón **External Configuration Store** separa la configuración de la aplicación del código fuente, almacenándola en un repositorio externo (variables de entorno, archivos .env, servicios de configuración centralizados). Esto permite modificar el comportamiento de la aplicación sin recompilar ni redesplegar el código.

## Problema que Resuelve

En sistemas distribuidos y aplicaciones en múltiples entornos (desarrollo, staging, producción), es crucial:

- **Evitar hardcoding**: No incluir credenciales, URLs o configuraciones en el código
- **Facilitar cambios**: Modificar comportamiento sin rebuild/redeploy
- **Gestionar secretos**: Almacenar credenciales de forma segura
- **Soportar múltiples entornos**: Misma aplicación, diferentes configuraciones
- **Habilitar feature toggles**: Activar/desactivar funcionalidades dinámicamente

Sin este patrón:

- Cada cambio de configuración requiere recompilar y redesplegar
- Imposible hacer canary deployments o A/B testing
- Riesgo de exponer secretos en el código fuente
- Dificulta rollback (requiere rebuild de versión anterior)

## Implementación en Hotel & Casino API

### Variables de Configuración Externa

#### 1. Database Configuration

```bash
# PostgreSQL connection
PGHOST=db
PGPORT=5432
PGUSER=hoteluser
PGPASSWORD=casino123
PGDATABASE=hotel_casino
```

#### 2. Application Configuration

```bash
# API Settings
API_BASE_URL=http://localhost:3000
NODE_ENV=production
PORT=3000
APP_VERSION=1.0.0
```

#### 3. Feature Toggle - BOOKING_MODE

```bash
# Deferred Binding: Switch booking service implementation
BOOKING_MODE=pg     # Options: pg | mock
```

### Arquitectura de Deferred Binding

```
┌─────────────────────────────────────────┐
│   Environment Variables (.env)          │
│   BOOKING_MODE=pg                       │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│   BookingServiceFactory                 │
│   (Runtime Dependency Resolution)       │
└─────────────────┬───────────────────────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
┌─────────────────┐  ┌─────────────────┐
│ bookingService  │  │ bookingService  │
│     .pg.js      │  │    .mock.js     │
│ (PostgreSQL)    │  │ (In-Memory)     │
└─────────────────┘  └─────────────────┘
```

## Código de Implementación

### Factory Pattern con External Configuration

**`backend/services/bookingServiceFactory.js`**:

```javascript
const BookingServiceFactory = {
  createBookingService() {
    // Read configuration from environment
    const mode = process.env.BOOKING_MODE || "pg";

    console.log(
      `🔗 Deferred Binding: Creating BookingService in mode: ${mode}`
    );

    // Resolve dependency at runtime based on configuration
    if (mode === "mock") {
      return require("./bookingService.mock");
    } else {
      return require("./bookingService.pg");
    }
  },
};

module.exports = BookingServiceFactory;
```

### Uso en Routes

**`backend/routes/index.routes.js`**:

```javascript
const BookingServiceFactory = require("../services/bookingServiceFactory");

// Dependency injected at runtime based on BOOKING_MODE
const bookingService = BookingServiceFactory.createBookingService();

router.get("/bookings", async (req, res) => {
  const result = await bookingService.getAllBookings();
  // Service implementation depends on environment configuration
});
```

## Casos de Uso

### 1. Desarrollo Local (Mock Mode)

```bash
# .env.development
BOOKING_MODE=mock
NODE_ENV=development
```

- Sin necesidad de PostgreSQL
- Datos en memoria para testing rápido
- Útil para frontend development

### 2. Testing/CI (Mock Mode)

```bash
# .env.test
BOOKING_MODE=mock
NODE_ENV=test
```

- Tests unitarios sin dependencias externas
- CI/CD pipelines más rápidos
- Sin necesidad de base de datos real

### 3. Producción (PostgreSQL Mode)

```bash
# .env.production
BOOKING_MODE=pg
NODE_ENV=production
PGHOST=prod-db.example.com
PGUSER=prod_user
PGPASSWORD=${SECRET_PASSWORD}
```

- Persistencia real en PostgreSQL
- Configuración segura desde secretos
- Escalabilidad y durabilidad

### 4. Canary Deployment

```bash
# 90% traffic → v1 (pg mode)
# 10% traffic → v2 (new feature with pg mode)
```

- Probar nuevas features con configuración específica
- Rollback instantáneo cambiando variable

## Beneficios

### Operacionales

- ✅ **Zero Downtime Configuration**: Cambios sin redeploy
- ✅ **Rollback Instantáneo**: Revertir configuración sin rebuild
- ✅ **A/B Testing**: Diferentes configuraciones por usuario/región
- ✅ **Canary Deployments**: Validar cambios con % de tráfico

### Seguridad

- ✅ **Secretos Externalizados**: Credenciales fuera del código
- ✅ **Rotación de Credenciales**: Cambiar passwords sin redeploy
- ✅ **Auditoría**: Historial de cambios en configuración
- ✅ **Separation of Concerns**: Devs no tienen acceso a secrets de prod

### Desarrollo

- ✅ **Múltiples Entornos**: Dev, staging, prod con mismo código
- ✅ **Testing Simplificado**: Mock mode sin dependencias
- ✅ **Feature Toggles**: Activar/desactivar features dinámicamente
- ✅ **Hotfix Configuration**: Corregir problemas ajustando config

## Niveles de External Configuration

### Nivel 1: Variables de Entorno (Actual)

```bash
# .env file
BOOKING_MODE=pg
NODE_ENV=production
```

- ✅ Implementado
- Simple y directo
- Requiere restart del servicio

### Nivel 2: Docker Secrets (Producción)

```yaml
# docker-compose.yml
services:
  backend:
    secrets:
      - db_password
      - api_key
    environment:
      PGPASSWORD_FILE: /run/secrets/db_password
```

- Seguro para producción
- Encriptado en tránsito y reposo

### Nivel 3: Kubernetes ConfigMaps (Orquestación)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: hotel-config
data:
  BOOKING_MODE: "pg"
  NODE_ENV: "production"
```

- Gestión centralizada
- Hot reload sin restart

### Nivel 4: Azure App Configuration / AWS Systems Manager (Enterprise)

```javascript
const { AppConfigurationClient } = require("@azure/app-configuration");

const client = new AppConfigurationClient(connectionString);
const bookingMode = await client.getConfigurationSetting({
  key: "booking_mode",
});
```

- Configuración dinámica
- Feature flags avanzados
- Auditoría completa

## Integración con Docker Compose

**`docker-compose.yaml`**:

```yaml
backend_v1:
  environment:
    - NODE_ENV=${NODE_ENV:-production}
    - BOOKING_MODE=${BOOKING_MODE:-pg}
    - PGUSER=${DB_USER:-hoteluser}
    - PGPASSWORD=${DB_PASSWORD:-casino123}
```

### Cambiar Configuración sin Rebuild

```bash
# Método 1: Variable de entorno
export BOOKING_MODE=mock
docker-compose up -d --force-recreate backend_v1

# Método 2: Archivo .env
echo "BOOKING_MODE=mock" > .env
docker-compose up -d --force-recreate backend_v1

# Método 3: Inline override
BOOKING_MODE=mock docker-compose up -d --force-recreate backend_v1
```

## Relación con Tácticas de Arquitectura

### Facilidad de Modificación (TFU2)

- **Deferred Binding**: Factory resuelve dependencias en runtime según configuración
- **Separation of Concerns**: Configuración separada del código lógico
- **Open/Closed Principle**: Agregar nuevos modos sin modificar factory

### Facilidad de Despliegue (TFU2)

- **Configuración Externalizada**: Mismo artefacto para todos los entornos
- **Feature Toggles**: Activar features sin redeploy
- **Rollback Simplificado**: Revertir configuración instantáneamente

### Seguridad (TFU2)

- **Secretos Externalizados**: Credenciales nunca en código fuente
- **Least Privilege**: Diferentes configs por entorno con permisos mínimos

## Testing del Patrón

### Test 1: Verificar Factory con Mock Mode

```bash
BOOKING_MODE=mock node -e "
const factory = require('./backend/services/bookingServiceFactory');
const service = factory.createBookingService();
console.log(service.getAllBookings());
"
```

### Test 2: Verificar Factory con PostgreSQL Mode

```bash
BOOKING_MODE=pg node -e "
const factory = require('./backend/services/bookingServiceFactory');
const service = factory.createBookingService();
console.log('Service:', service);
"
```

### Test 3: Hot Configuration Change

```bash
# Terminal 1: Start with pg mode
BOOKING_MODE=pg docker-compose up backend_v1

# Terminal 2: Switch to mock mode
docker-compose stop backend_v1
BOOKING_MODE=mock docker-compose up -d backend_v1
curl http://localhost:3000/bookings
```

## Mejores Prácticas Implementadas

### 1. Default Values

```javascript
const mode = process.env.BOOKING_MODE || "pg";
const port = process.env.PORT || 3000;
```

- Siempre proveer valores por defecto
- Aplicación funcional sin configuración explícita

### 2. Validation

```javascript
const validModes = ["pg", "mock"];
if (!validModes.includes(mode)) {
  throw new Error(`Invalid BOOKING_MODE: ${mode}`);
}
```

- Validar configuración al inicio
- Fail fast ante errores

### 3. Logging

```javascript
console.log(`🔗 Deferred Binding: Creating BookingService in mode: ${mode}`);
```

- Registrar configuración activa
- Facilita debugging y auditoría

### 4. Type Safety (TypeScript)

```typescript
type BookingMode = "pg" | "mock";
const mode: BookingMode = (process.env.BOOKING_MODE as BookingMode) || "pg";
```

- Prevenir errores tipográficos
- Autocompletado en IDE

## Monitoreo y Observabilidad

### Métricas Recomendadas

- Configuration reload events
- Active configuration per service
- Configuration validation errors
- Time since last configuration change

### Alertas Sugeridas

```yaml
# Production using mock mode (unexpected)
- alert: ProductionUsingMockMode
  expr: booking_mode{env="production"} == "mock"
  severity: critical
  annotations:
    summary: "Production is using mock booking mode"

# Configuration out of sync
- alert: ConfigurationMismatch
  expr: count(booking_mode) by (mode) > 1
  severity: warning
  annotations:
    summary: "Multiple booking modes active simultaneously"
```

## Demo Completo

**PowerShell**: `demos/demo-external-configuration.ps1`
**Bash**: `demos/demo-external-configuration.sh`

El demo demuestra:

1. Estado actual de configuración
2. Cambio de mock → pg mode
3. Verificación de persistencia (pg guarda, mock no)
4. Cambio de pg → mock mode
5. Restauración a configuración original
6. Métricas de configuración

## Referencias

- [Microsoft: External Configuration Store Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/external-configuration-store)
- [12-Factor App: III. Config](https://12factor.net/config)
- [Azure App Configuration](https://azure.microsoft.com/en-us/services/app-configuration/)
- [Kubernetes ConfigMaps and Secrets](https://kubernetes.io/docs/concepts/configuration/)

---

**Implementado**: 30 de octubre de 2025  
**Patrón**: External Configuration Store (Facilidad de Modificación/Despliegue)  
**Demo**: `demos/demo-external-configuration.ps1`
