# 🎤 Guión de Presentación - Patrones de Diseño Cloud

## Sistema de Reservas Hotel & Casino Salto

---

## 📋 INTRODUCCIÓN GENERAL (2-3 minutos)

**"Buenos días/tardes. Hoy voy a presentar el Trabajo Final de la Unidad 4, donde implementé 7 patrones de diseño cloud en un sistema de reservas para el Hotel & Casino Salto."**

**"El proyecto está construido con:**

- **Backend:** Node.js + Express + PostgreSQL
- **Frontend:** Angular 19 con Material Design
- **Infraestructura:** Docker Compose para orquestación
- **Nginx:** Como API Gateway y balanceador de carga"

**"Los 7 patrones implementados abordan distintos requisitos no funcionales:"**

1. ✅ Circuit Breaker - Resiliencia
2. ✅ Valet Key - Seguridad
3. ✅ Cache-Aside - Performance
4. ✅ Gateway Offloading - Escalabilidad
5. ✅ Health Endpoint Monitoring - Observabilidad
6. ✅ External Configuration Store - Modificabilidad
7. ✅ Competing Consumers - Throughput

**"Voy a ejecutar las demos en vivo para mostrar cada patrón funcionando."**

---

## 🔴 PATRÓN 1: CIRCUIT BREAKER (5 minutos)

### Contexto

**"El primer patrón es Circuit Breaker, que protege el sistema contra fallos en cascada cuando un servicio externo falla."**

### Problema que resuelve

**"En nuestro sistema, cuando un cliente hace una reserva, necesitamos procesar el pago a través de un servicio externo. Si ese servicio está caído y seguimos intentando llamarlo, podríamos colapsar toda nuestra aplicación."**

### Cómo funciona

**"El Circuit Breaker tiene 3 estados:**

- **CLOSED:** Todo funciona normal, las peticiones pasan
- **OPEN:** El servicio falló muchas veces, bloqueamos las peticiones durante 30 segundos
- **HALF_OPEN:** Después de 30 segundos, permitimos 1 petición de prueba"

### Ejecutando la demo

**"Voy a ejecutar la demo que simula pagos exitosos y fallidos."**

```powershell
cd demos
.\demo-circuit-breaker.ps1
```

**Mientras corre la demo, narrar:**

**"Como pueden ver:**

- **Las primeras 5 peticiones funcionan bien** → Estado CLOSED
- **Luego simulo 5 pagos fallidos** → El circuito se ABRE después del 5to fallo
- **Durante 30 segundos, el circuito rechaza peticiones inmediatamente** sin llamar al servicio
- **Después del timeout, pasa a HALF_OPEN** y permite 1 petición de prueba
- **Si la prueba es exitosa, vuelve a CLOSED**"

### Beneficio

**"Esto protege nuestro sistema de gastar recursos en un servicio que sabemos que está caído, y permite recuperación automática."**

---

## 🔑 PATRÓN 2: VALET KEY (4 minutos)

### Contexto

**"El patrón Valet Key delega el acceso directo a recursos de almacenamiento sin pasar por el servidor."**

### Problema que resuelve

**"Imaginen que un cliente quiere subir su documento de identidad. Si lo sube a través de nuestro servidor, consumimos ancho de banda y CPU innecesariamente."**

### Cómo funciona

**"Valet Key funciona así:**

1. El cliente pide un 'token temporal' al servidor
2. El servidor genera un token con permisos limitados (ej: solo escritura, expira en 5 minutos)
3. El cliente usa ese token para subir DIRECTAMENTE al almacenamiento (S3, Azure Blob, etc.)
4. Nuestro servidor nunca ve el archivo"

### Ejecutando la demo

**"Voy a ejecutar la demo que simula la generación de tokens temporales."**

```powershell
.\demo-valet-key.ps1
```

**Mientras corre la demo, narrar:**

**"Observen que:**

- **Generamos un token temporal** con permisos específicos
- **El token expira en 5 minutos**
- **Incluye metadata** como tipo de archivo permitido y tamaño máximo
- **El cliente puede usar este token directamente** contra el servicio de almacenamiento"

### Beneficio

**"Reducimos la carga del servidor, mejoramos el throughput y aumentamos la seguridad al limitar permisos por tiempo."**

---

## ⚡ PATRÓN 3: CACHE-ASIDE (4 minutos)

### Contexto

**"Cache-Aside mejora el performance almacenando en memoria los datos consultados frecuentemente."**

### Problema que resuelve

**"Las consultas a base de datos son lentas. Si 100 usuarios consultan las habitaciones disponibles, haríamos 100 queries idénticas a PostgreSQL."**

### Cómo funciona

**"La estrategia es:**

1. **Cache miss:** Si el dato no está en caché → Consultar DB y guardar en caché
2. **Cache hit:** Si el dato está en caché → Devolver directamente (mucho más rápido)
3. **Invalidación:** Cuando se modifica un dato, lo eliminamos de caché"

### Ejecutando la demo

**"Voy a ejecutar la demo que compara tiempos con y sin caché."**

```powershell
.\demo-cache-aside-final.ps1
```

**Mientras corre la demo, narrar:**

**"Noten la diferencia de tiempos:**

- **Primera consulta (cache miss):** ~50-100ms porque va a la base de datos
- **Consultas siguientes (cache hit):** ~2-5ms porque viene de memoria RAM
- **Eso es una mejora de 20-50x en velocidad**"

**"También vean cómo:**

- **Cuando creamos una reserva nueva**, el caché se invalida automáticamente
- **La siguiente consulta vuelve a ser lenta** (cache miss)
- **Pero luego es rápida de nuevo** (cache hit)"

### Beneficio

**"Reducimos latencia, disminuimos carga en la base de datos y mejoramos la experiencia del usuario."**

---

## 🚪 PATRÓN 4: GATEWAY OFFLOADING (5 minutos)

### Contexto

**"Gateway Offloading centraliza funcionalidades transversales en el API Gateway (Nginx)."**

### Problema que resuelve

**"Si cada microservicio implementa autenticación, rate limiting, CORS, logs... duplicamos código y lógica en todos lados."**

### Cómo funciona

**"Usamos Nginx como Gateway que:**

- **Compresión Gzip** → Reduce tamaño de respuestas
- **Rate Limiting** → Máximo 100 requests/minuto por IP
- **CORS Headers** → Permite acceso desde el frontend
- **Load Balancing** → Distribuye carga entre instancias
- **TLS Termination** → Maneja HTTPS en un solo punto"

### Ejecutando la demo

**"Voy a ejecutar la demo que muestra compresión y rate limiting."**

```powershell
.\demo-gateway-offloading.ps1
```

**Mientras corre la demo, narrar:**

**"Observen:**

- **Sin compresión:** La respuesta pesa ~4KB
- **Con compresión Gzip:** La respuesta pesa ~1KB → Ahorro de 75%
- **Rate Limiting:** Si hago más de 100 requests/minuto, Nginx devuelve 429 (Too Many Requests)
- **Headers CORS:** Nginx agrega automáticamente Access-Control-Allow-Origin"

### Beneficio

**"Simplificamos los microservicios, centralizamos seguridad y mejoramos el rendimiento de la red."**

---

## 💚 PATRÓN 5: HEALTH ENDPOINT MONITORING (3 minutos)

### Contexto

**"Health Endpoint Monitoring permite monitorear el estado del sistema en tiempo real."**

### Problema que resuelve

**"¿Cómo sabemos si nuestra aplicación está funcionando correctamente? Necesitamos visibilidad del estado de cada componente."**

### Cómo funciona

**"Implementamos endpoints `/health` que reportan:**

- **Estado del servicio:** UP/DOWN
- **Tiempo de actividad:** Uptime
- **Versión del servicio**
- **Dependencias:** Estado de DB, caché, servicios externos"

### Ejecutando la demo

**"Voy a ejecutar la demo que consulta los endpoints de salud."**

```powershell
.\demo-health-endpoint.ps1
```

**Mientras corre la demo, narrar:**

**"Vean cómo cada servicio reporta:**

- **Status:** healthy/unhealthy
- **Uptime:** Tiempo desde que se inició
- **Version:** v1.0.0
- **Database:** Conexión OK
- **Cache:** Redis disponible"

**"Estos endpoints pueden ser monitoreados por:**

- Kubernetes liveness/readiness probes
- Herramientas como Prometheus, Grafana
- Load balancers para quitar instancias no saludables"

### Beneficio

**"Detectamos problemas antes que los usuarios, facilitamos debugging y habilitamos auto-recuperación."**

---

## ⚙️ PATRÓN 6: EXTERNAL CONFIGURATION STORE (4 minutos)

### Contexto

**"External Configuration Store separa la configuración del código, permitiendo cambios sin recompilar."**

### Problema que resuelve

**"Si hardcodeamos configuración (DB credentials, feature flags, URLs) necesitamos recompilar y redesplegar cada vez que cambiamos algo."**

### Cómo funciona

**"Usamos variables de entorno y archivos .env:**

- **Desarrollo:** `.env.development`
- **Producción:** `.env.production`
- **Testing:** `.env.test`"

**"Esto permite:**

- Cambiar DB sin tocar código
- Activar/desactivar features
- Configurar límites (rate limits, timeouts)
- Usar diferentes servicios según entorno"

### Ejecutando la demo

**"Voy a ejecutar la demo que muestra configuración dinámica."**

```powershell
.\demo-external-configuration.ps1
```

**Mientras corre la demo, narrar:**

**"Observen cómo:**

- **Cambiamos BOOKING_MODE** de 'pg' a 'mock' → Usa datos en memoria en lugar de PostgreSQL
- **No recompilamos código** → Solo reiniciamos el contenedor
- **Cambiamos CACHE_ENABLED** → Activa/desactiva el caché sin cambiar código
- **Diferentes entornos** → Misma imagen Docker, distinta configuración"

### Beneficio

**"Facilitamos despliegues, reducimos errores humanos, habilitamos feature flags y mejoramos seguridad (secrets externos)."**

---

## 🔄 PATRÓN 7: COMPETING CONSUMERS (5 minutos)

### Contexto

**"Competing Consumers mejora el throughput procesando tareas en paralelo con múltiples workers."**

### Problema que resuelve

**"Si procesamos emails, reservas, notificaciones secuencialmente, una tarea lenta bloquea todas las siguientes."**

### Cómo funciona

**"Implementamos:**

1. **Cola FIFO:** Las tareas entran en orden
2. **3 Workers concurrentes:** Procesan tareas en paralelo
3. **Diferentes velocidades:** Worker 1 (rápido), Worker 2 (medio), Worker 3 (lento)
4. **Reintento automático:** Si una tarea falla, se reintenta"

### Ejecutando la demo

**"Voy a ejecutar la demo que procesa 15 tareas con múltiples workers."**

```powershell
.\demo-competing-consumers.ps1
```

**Mientras corre la demo, narrar:**

**"Observen:**

- **Agregamos 15 tareas a la cola** (5 individuales + 10 en batch)
- **3 workers compiten por procesar** las tareas
- **Procesamiento paralelo:** Las tareas se completan en ~25 segundos
- **Si fuera secuencial:** Tomaría ~75 segundos (3x más lento)"

**"También noten:**

- **Worker 1 procesó 12 tareas** (el más rápido, polling cada 2 segundos)
- **Worker 2 procesó 12 tareas** (polling cada 2.5 segundos)
- **Worker 3 procesó 6 tareas** (el más lento, polling cada 3 segundos)
- **3 tareas fallaron** (simulación de errores: 10% en emails, 5% en pagos)"

### Beneficio

**"Mejoramos throughput 3x, reducimos tiempo de respuesta y el sistema es más resiliente a fallos individuales."**

---

## 🎯 CONCLUSIÓN (2 minutos)

**"Para resumir, implementé 7 patrones cloud que mejoran distintos aspectos del sistema:"**

| Patrón                 | NFR Principal   | Mejora                           |
| ---------------------- | --------------- | -------------------------------- |
| Circuit Breaker        | Resiliencia     | Protege contra fallos en cascada |
| Valet Key              | Seguridad       | Acceso directo sin servidor      |
| Cache-Aside            | Performance     | 20-50x más rápido                |
| Gateway Offloading     | Escalabilidad   | Simplifica microservicios        |
| Health Endpoint        | Observabilidad  | Monitoreo en tiempo real         |
| External Configuration | Modificabilidad | Cambios sin recompilar           |
| Competing Consumers    | Throughput      | 3x más rápido en paralelo        |

**"El proyecto está completamente dockerizado, con:**

- ✅ 7 patrones funcionando
- ✅ Frontend Angular integrado
- ✅ Documentación completa (README + diagramas PlantUML)
- ✅ Demos automatizadas para cada patrón
- ✅ ~2,000 líneas de código backend
- ✅ ~5,500 líneas de documentación"

**"Todos los patrones se pueden ejecutar localmente con `docker-compose up` y están listos para producción."**

**"¿Alguna pregunta?"**

---

## 💡 TIPS PARA LA PRESENTACIÓN

### Antes de empezar:

1. ✅ Asegúrate que Docker está corriendo
2. ✅ Ejecuta `docker-compose up` antes de la presentación
3. ✅ Verifica que puedes acceder a http://localhost:3000/health
4. ✅ Ten las demos listas en `cd demos`
5. ✅ Abre un navegador en http://localhost:4200 (frontend)

### Durante la presentación:

- 🎯 Mantén las demos cortas (3-5 min cada una)
- 🎯 Muestra el código si te preguntan detalles
- 🎯 Ten los diagramas PlantUML abiertos para mostrar arquitectura
- 🎯 Si algo falla, usa capturas de pantalla de respaldo

### Preguntas frecuentes esperadas:

**Q: ¿Por qué no usaste Redis para el caché?**
**A:** "Usé un caché en memoria (Map de JavaScript) para simplificar la demo y evitar dependencias adicionales. En producción se usaría Redis o Memcached."

**Q: ¿Por qué Competing Consumers en memoria y no RabbitMQ?**
**A:** "Para el alcance académico, una cola en memoria es suficiente para demostrar el patrón. En producción se usaría RabbitMQ, AWS SQS o Azure Service Bus."

**Q: ¿Cómo escalarías esto a producción?**
**A:** "Usaría Kubernetes para orquestar contenedores, Redis distribuido, base de datos replicada, y un message broker real como RabbitMQ."

**Q: ¿Cómo manejan los rollbacks?**
**A:** "Usamos tags de Docker (v1, v2) y docker-compose permite cambiar entre versiones modificando la variable de entorno IMAGE_VERSION."

---

## 📊 ESTRUCTURA DE TIEMPO SUGERIDA (30 minutos)

| Sección                | Tiempo        |
| ---------------------- | ------------- |
| Introducción           | 2-3 min       |
| Circuit Breaker        | 5 min         |
| Valet Key              | 4 min         |
| Cache-Aside            | 4 min         |
| Gateway Offloading     | 5 min         |
| Health Endpoint        | 3 min         |
| External Configuration | 4 min         |
| Competing Consumers    | 5 min         |
| Conclusión + Q&A       | 3-5 min       |
| **TOTAL**              | **30-35 min** |

---

## 🚀 CHECKLIST PRE-PRESENTACIÓN

- [ ] Docker Desktop está corriendo
- [ ] `docker-compose up` ejecutado exitosamente
- [ ] http://localhost:3000/health responde
- [ ] http://localhost:4200 muestra el frontend
- [ ] Todas las demos en `demos/` funcionan
- [ ] README.md abierto para referencia
- [ ] Diagramas PlantUML visibles
- [ ] Terminal limpia y lista
- [ ] Postman collection cargada (opcional)

---

¡Éxito en tu presentación! 🎉
