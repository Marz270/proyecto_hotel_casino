# Patron Cache-Aside

## Descripcion

Cache-Aside es un patron de rendimiento que mejora la eficiencia de acceso a datos mediante el uso de una capa de cache. La aplicacion es responsable de mantener la consistencia entre el cache y el almacenamiento persistente.

## Categoria

**Patron de Rendimiento / Performance**

## Problema que Resuelve

- Consultas repetitivas a la base de datos que generan carga innecesaria
- Tiempos de respuesta lentos en operaciones de lectura frecuentes
- Escalabilidad limitada debido a cuellos de botella en la base de datos
- Latencia alta en consultas complejas con joins y agregaciones

## Como Funciona

### Flujo de Lectura (Cache-Aside)

1. **Verificar Cache**: La aplicacion primero consulta el cache
2. **Cache Hit**: Si los datos estan en cache, se retornan inmediatamente
3. **Cache Miss**: Si no estan en cache:
   - Consultar la base de datos
   - Almacenar el resultado en cache con TTL
   - Retornar los datos al cliente

### Flujo de Escritura (Write-Through con Invalidacion)

1. **Modificar Datos**: Al crear/actualizar/eliminar datos
2. **Invalidar Cache**: Eliminar las entradas de cache relacionadas
3. **Proxima Lectura**: Sera un Cache Miss y recargara datos actualizados

## Implementacion en el Proyecto

### Componentes

#### 1. CacheService (`backend/services/cacheService.js`)

Servicio singleton de cache en memoria basado en Map de JavaScript:

```javascript
class CacheService {
  constructor() {
    this.cache = new Map();
    this.defaultTTL = 5 * 60 * 1000; // 5 minutos
    this.startCleanupInterval(); // Limpieza automatica
  }

  get(key) {
    /* ... */
  }
  set(key, value, ttl) {
    /* ... */
  }
  invalidate(key) {
    /* ... */
  }
  invalidatePattern(pattern) {
    /* ... */
  }
  getStats() {
    /* ... */
  }
}
```

**Caracteristicas:**

- TTL (Time To Live) configurable por entrada
- Limpieza automatica de items expirados cada 60 segundos
- Soporte para invalidacion por patron (wildcards)
- Estadisticas de uso (items activos, expirados, hit rate)

#### 2. Rutas con Cache (`backend/routes/rooms.routes.js`)

**GET /rooms/availability?month=YYYY-MM**

Consulta disponibilidad de habitaciones con capa de cache:

```javascript
router.get("/rooms/availability", async (req, res) => {
  const cacheKey = `rooms:availability:month:${month}`;

  // PASO 1: Intentar obtener del cache
  const cachedData = cacheService.get(cacheKey);
  if (cachedData) {
    return res.json({ source: "cache", data: cachedData });
  }

  // PASO 2: Cache Miss - Consultar BD
  const result = await pool.query(query, params);

  // PASO 3: Almacenar en cache
  cacheService.set(cacheKey, result.rows, 5 * 60 * 1000);

  return res.json({ source: "database", data: result.rows });
});
```

**GET /cache/stats**

Retorna estadisticas del cache para monitoreo:

- Total de items
- Items activos vs expirados
- TTL configurado

#### 3. Invalidacion Automatica (`backend/routes/index.routes.js`)

Al crear o eliminar reservas, el cache se invalida automaticamente:

```javascript
// POST /bookings - Crear reserva
router.post("/bookings", async (req, res) => {
  const result = await bookingService.createBooking(req.body);

  if (result.success) {
    // Invalidar cache de disponibilidad
    cacheService.invalidatePattern("rooms:availability:*");
  }

  return res.json(result);
});
```

### Estructura de Claves de Cache

Patron de nomenclatura:

```
rooms:availability:month:YYYY-MM
```

Ejemplos:

- `rooms:availability:month:2025-01`
- `rooms:availability:month:2025-02`

## Beneficios Demostrados

### Mejora de Rendimiento

Resultados de la demo:

- **Primera consulta (Cache Miss)**: ~173ms - Consulta a PostgreSQL
- **Segunda consulta (Cache Hit)**: ~33ms - Datos del cache
- **Mejora**: 81% reduccion en tiempo de respuesta
- **Promedio con cache**: ~16ms en consultas repetidas

### Reduccion de Carga

- 5-6 consultas adicionales no impactan la base de datos
- PostgreSQL solo se consulta en Cache Miss
- Escalabilidad horizontal mas facil

### Transparencia

- Mismo endpoint API para cliente
- No requiere cambios en frontend
- Compatible con sistemas existentes

## Ejecucion del Demo

```powershell
# Desde la raiz del proyecto
.\demos\demo-cache-aside-final.ps1
```

### Escenarios Demostrados

1. **Cache Miss inicial**: Primera consulta va a BD
2. **Cache Hit**: Consultas subsecuentes usan cache
3. **Consistencia**: Multiples consultas retornan mismos datos
4. **Estadisticas**: Monitoreo de uso del cache
5. **Invalidacion**: Al crear reserva, cache se invalida automaticamente

## Consideraciones de Produccion

### Limitaciones de la Implementacion Actual

- **Cache en memoria**: Se pierde al reiniciar servidor
- **No distribuido**: Solo funciona en instancia unica
- **Sin persistencia**: TTL fijo sin configuracion externa

### Mejoras Recomendadas para Produccion

#### 1. Redis como Cache Distribuido

```javascript
const redis = require("redis");
const client = redis.createClient({ url: process.env.REDIS_URL });

class CacheService {
  async get(key) {
    return await client.get(key);
  }

  async set(key, value, ttl) {
    await client.setEx(key, ttl, JSON.stringify(value));
  }
}
```

**Ventajas:**

- Compartido entre multiples instancias del backend
- Persistencia opcional (AOF/RDB)
- Escalabilidad horizontal
- Comandos atomicos

#### 2. Estrategias de Invalidacion Avanzadas

- **Cache Warming**: Pre-cargar cache con datos frecuentes
- **Lazy Loading**: Cargar bajo demanda (actual)
- **Write-Behind**: Escritura asincrona a BD
- **TTL Adaptativo**: Ajustar TTL segun patron de acceso

#### 3. Monitoreo y Metricas

```javascript
class CacheService {
  getDetailedStats() {
    return {
      hitRate: this.hits / (this.hits + this.misses),
      avgResponseTime: this.totalTime / this.requests,
      evictionRate: this.evictions / this.sets,
      memoryUsage: process.memoryUsage().heapUsed,
    };
  }
}
```

#### 4. Configuracion Externa

```javascript
// Cargar desde variables de entorno
const CACHE_CONFIG = {
  ttl: process.env.CACHE_TTL || 300000, // 5 min
  maxSize: process.env.CACHE_MAX_SIZE || 1000,
  cleanupInterval: process.env.CACHE_CLEANUP_INTERVAL || 60000,
};
```

## Patrones Relacionados

- **Circuit Breaker**: Protege el cache de fallos en cascada
- **Gateway Offloading**: Cache en capa de gateway (nginx, API Gateway)
- **CQRS**: Separar cache de lectura vs escritura
- **Event Sourcing**: Invalidacion basada en eventos

## Referencias

- [Microsoft - Cache-Aside Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/cache-aside)
- [AWS - Caching Best Practices](https://aws.amazon.com/caching/best-practices/)
- [Redis Documentation](https://redis.io/docs/manual/patterns/)
- Fowler, Martin. "Patterns of Enterprise Application Architecture" (2002)

## Diagrama de Secuencia

```
Cliente -> API: GET /rooms/availability?month=2025-01
API -> Cache: get("rooms:availability:month:2025-01")
alt Cache Hit
    Cache --> API: {data}
    API --> Cliente: {source: "cache", data}
else Cache Miss
    API -> PostgreSQL: SELECT * FROM rooms...
    PostgreSQL --> API: {rows}
    API -> Cache: set("rooms:availability:month:2025-01", rows, 300s)
    API --> Cliente: {source: "database", data}
end

Cliente -> API: POST /bookings
API -> PostgreSQL: INSERT INTO bookings...
API -> Cache: invalidatePattern("rooms:availability:*")
Cache --> API: invalidated 1 key(s)
API --> Cliente: {success: true}

Cliente -> API: GET /rooms/availability?month=2025-01
API -> Cache: get("rooms:availability:month:2025-01")
Note: Cache Miss (fue invalidado)
API -> PostgreSQL: SELECT * FROM rooms...
PostgreSQL --> API: {rows actualizados}
API -> Cache: set("rooms:availability:month:2025-01", rows, 300s)
API --> Cliente: {source: "database", data}
```
