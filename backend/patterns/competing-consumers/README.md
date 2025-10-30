# Competing Consumers Pattern

## 📋 Descripción

El patrón **Competing Consumers** permite que múltiples consumidores (workers) compitan por procesar mensajes de una cola de manera concurrente. Esto maximiza el throughput del sistema al distribuir la carga de trabajo entre varios workers que operan en paralelo.

## 🎯 Problema que Resuelve

### Escenario Común

Una aplicación necesita procesar tareas que consumen mucho tiempo:

- Envío de emails de confirmación
- Procesamiento de pagos
- Generación de reportes
- Notificaciones push
- Procesamiento de imágenes

Si estas tareas se procesan **secuencialmente**, el sistema se vuelve lento y no escala adecuadamente.

### Sin el Patrón

```
Request → [API] → Process Task 1 (5s) → Process Task 2 (5s) → ...
                  ⏱️ 50 segundos para 10 tareas
```

### Con el Patrón

```
                  ┌─→ [Worker 1] → Task 1 (5s)
Request → [Queue] ├─→ [Worker 2] → Task 2 (5s)
                  └─→ [Worker 3] → Task 3 (5s)
                  ⏱️ ~17 segundos para 10 tareas
```

## 🏗️ Implementación

### Arquitectura del Sistema

```
┌─────────────┐
│   API REST  │
│  (Producer) │
└──────┬──────┘
       │ POST /queue/tasks
       ▼
┌─────────────────┐
│   Task Queue    │
│  (In-Memory)    │
└────┬─────┬─────┬┘
     │     │     │
     │     │     └─────────┐
     │     └───────┐       │
     └─────┐       │       │
           ▼       ▼       ▼
      ┌─────┐ ┌─────┐ ┌─────┐
      │  W1 │ │  W2 │ │  W3 │
      └─────┘ └─────┘ └─────┘
    (Consumer) (Consumer) (Consumer)
    2000ms    2500ms    3000ms
    polling   polling   polling
```

### Componentes

#### 1. **Task Queue** (`queueService.js`)

Cola FIFO que almacena tareas pendientes:

```javascript
class TaskQueue {
  constructor() {
    this.tasks = []; // Cola de tareas pendientes
    this.completed = []; // Tareas completadas
    this.failed = []; // Tareas fallidas
    this.processing = new Map(); // Tareas en procesamiento
  }

  enqueue(task) {
    // Agrega tarea a la cola
    this.tasks.push({
      id: `task-${Date.now()}-${randomId}`,
      type: task.type,
      data: task.data,
      status: "pending",
    });
  }

  dequeue() {
    // Obtiene siguiente tarea (FIFO)
    return this.tasks.shift();
  }
}
```

#### 2. **Workers** (`workerService.js`)

Consumidores que procesan tareas concurrentemente:

```javascript
class Worker {
  constructor(id, pollInterval = 2000) {
    this.id = id;
    this.pollInterval = pollInterval;
  }

  start() {
    // Polling continuo para obtener tareas
    this.intervalId = setInterval(async () => {
      const task = taskQueue.dequeue();
      if (task) {
        await processTask(task, this.id);
      }
    }, this.pollInterval);
  }
}

// Pool de 3 workers
const workers = [
  new Worker(1, 2000), // Polling cada 2s
  new Worker(2, 2500), // Polling cada 2.5s
  new Worker(3, 3000), // Polling cada 3s
];
```

#### 3. **Procesamiento de Tareas**

Cada worker procesa diferentes tipos de tareas:

```javascript
async function processTask(task, workerId) {
  try {
    let result;
    switch (task.type) {
      case "email":
        result = await simulateEmailSending(task.data, workerId);
        break;
      case "reservation":
        result = await simulateReservationProcessing(task.data, workerId);
        break;
      case "payment":
        result = await simulatePaymentProcessing(task.data, workerId);
        break;
      case "notification":
        result = await simulateNotificationSending(task.data, workerId);
        break;
    }

    taskQueue.markCompleted(task.id, workerId, result);
  } catch (error) {
    taskQueue.markFailed(task.id, workerId, error);
  }
}
```

## 📡 API Endpoints

### Gestión de Tareas

#### Agregar Tarea Individual

```bash
POST /queue/tasks
Content-Type: application/json

{
  "type": "email",
  "data": {
    "to": "guest@hotel.com",
    "subject": "Confirmación de Reserva",
    "bookingId": "RES-001"
  }
}
```

**Respuesta:**

```json
{
  "success": true,
  "message": "Tarea agregada a la cola exitosamente",
  "task": {
    "id": "task-1698765432-abc123",
    "type": "email",
    "status": "pending",
    "enqueuedAt": "2025-10-30T12:00:00.000Z"
  }
}
```

#### Agregar Batch de Tareas

```bash
POST /queue/tasks/batch
Content-Type: application/json

{
  "tasks": [
    { "type": "email", "data": { "to": "guest1@hotel.com" } },
    { "type": "payment", "data": { "amount": 500 } },
    { "type": "notification", "data": { "userId": "123" } }
  ]
}
```

#### Obtener Estadísticas

```bash
GET /queue/stats
```

**Respuesta:**

```json
{
  "success": true,
  "stats": {
    "pending": 5,
    "processing": 3,
    "completed": 42,
    "failed": 2,
    "total": 50,
    "successRate": "84.00%"
  },
  "processing": [
    {
      "workerId": 1,
      "taskId": "task-123",
      "type": "email",
      "duration": 1234
    }
  ],
  "recentCompleted": [...]
}
```

### Gestión de Workers

#### Iniciar Workers

```bash
POST /queue/workers/start
```

#### Detener Workers

```bash
POST /queue/workers/stop
```

#### Estado de Workers

```bash
GET /queue/workers
```

**Respuesta:**

```json
{
  "success": true,
  "workers": [
    {
      "id": 1,
      "isRunning": true,
      "tasksProcessed": 15,
      "pollInterval": 2000
    },
    {
      "id": 2,
      "isRunning": true,
      "tasksProcessed": 12,
      "pollInterval": 2500
    },
    {
      "id": 3,
      "isRunning": true,
      "tasksProcessed": 10,
      "pollInterval": 3000
    }
  ],
  "totalWorkers": 3,
  "activeWorkers": 3
}
```

## 🎬 Demostración

### Ejecutar Demo

```powershell
# Asegúrate de que Docker esté corriendo
docker-compose up -d

# Ejecutar demo
.\demos\demo-competing-consumers.ps1
```

### Flujo de la Demo

1. **Verificación del Sistema**

   - Verifica que la API esté disponible
   - Muestra versión y modo actual

2. **Preparación**

   - Detiene workers previos
   - Resetea la cola

3. **Inicio de Workers**

   - Inicia pool de 3 workers
   - Muestra estado de cada worker

4. **Agregado Individual**

   - Agrega 5 tareas de diferentes tipos a la cola
   - Muestra confirmación de cada tarea

5. **Monitoreo de Procesamiento**

   - Muestra estadísticas cada 3 segundos (5 checks)
   - Visualiza tareas pendientes, en proceso y completadas
   - Muestra qué worker procesa cada tarea

6. **Agregado Batch**

   - Agrega 10 tareas simultáneamente a la cola
   - Demuestra capacidad de procesamiento masivo

7. **Monitoreo de Batch**

   - Seguimiento durante 20 segundos
   - Muestra progreso de procesamiento
   - Calcula tasa de completitud

8. **Estadísticas Finales**

   - Resumen de tareas procesadas
   - Tasa de éxito/fallo
   - Rendimiento de cada worker

9. **Detención de Workers**

   - Para todos los workers
   - Muestra tareas procesadas por cada uno

10. **Explicación de Beneficios**
    - Lista casos de uso
    - Explica ventajas del patrón

## ✅ Beneficios

### 1. **Procesamiento Paralelo**

Múltiples workers procesan tareas simultáneamente, aumentando el throughput.

**Ejemplo:**

- 1 worker: 10 tareas × 3s = 30 segundos
- 3 workers: 10 tareas × 3s / 3 = ~10 segundos

### 2. **Escalabilidad Horizontal**

Fácil agregar más workers para manejar mayor carga:

```javascript
// Agregar más workers dinámicamente
const newWorker = new Worker(4, 2000);
newWorker.start();
```

### 3. **Tolerancia a Fallos**

Si un worker falla, los demás continúan procesando:

```javascript
// Manejo de errores por tarea
catch (error) {
  taskQueue.markFailed(task.id, workerId, error);
  // Otros workers no se afectan
}
```

### 4. **Desacoplamiento**

Productores (API) y consumidores (workers) no se conocen:

```
Producer: "Aquí hay trabajo" → Queue
Queue → Consumer: "Toma este trabajo"
```

### 5. **Balanceo de Carga Automático**

La cola distribuye tareas automáticamente entre workers disponibles (FIFO).

## 🎯 Casos de Uso

### 1. **Envío de Emails**

```javascript
// Agregar email de confirmación a la cola
POST /queue/tasks
{
  "type": "email",
  "data": {
    "to": "guest@hotel.com",
    "subject": "Confirmación de Reserva #1234",
    "template": "booking-confirmation",
    "bookingId": "RES-1234"
  }
}
```

**Beneficio:** Respuesta inmediata al usuario, email enviado en background.

### 2. **Procesamiento de Reservas**

```javascript
// Agregar reserva compleja a la cola
POST /queue/tasks
{
  "type": "reservation",
  "data": {
    "clientId": 123,
    "roomId": 301,
    "checkIn": "2025-11-01",
    "checkOut": "2025-11-05",
    "services": ["breakfast", "spa", "parking"]
  }
}
```

**Beneficio:** Múltiples reservas procesadas en paralelo.

### 3. **Procesamiento de Pagos**

```javascript
// Agregar pago a la cola
POST /queue/tasks
{
  "type": "payment",
  "data": {
    "amount": 500,
    "currency": "USD",
    "cardLast4": "4242",
    "reservationId": "RES-1234"
  }
}
```

**Beneficio:** Workers dedicados pueden manejar lógica de pago compleja.

### 4. **Notificaciones Push**

```javascript
// Agregar notificaciones masivas a la cola
POST /queue/tasks/batch
{
  "tasks": [
    { "type": "notification", "data": { "userId": "user-1", "message": "Promoción" } },
    { "type": "notification", "data": { "userId": "user-2", "message": "Promoción" } },
    // ... 1000 usuarios
  ]
}
```

**Beneficio:** 3 workers procesan 1000 notificaciones en ~5 minutos vs 15 minutos.

## 🔧 Configuración y Monitoreo

### Ajustar Número de Workers

```javascript
// backend/patterns/competing-consumers/workerService.js
const workers = [
  new Worker(1, 2000),
  new Worker(2, 2000),
  new Worker(3, 2000),
  new Worker(4, 2000), // Agregar más workers
  new Worker(5, 2000),
];
```

### Ajustar Intervalo de Polling

```javascript
// Polling más agresivo (1 segundo)
new Worker(1, 1000);

// Polling más conservador (5 segundos)
new Worker(1, 5000);
```

### Monitoreo en Tiempo Real

```powershell
# Script de monitoreo continuo
while ($true) {
  $stats = Invoke-RestMethod -Uri "http://localhost:3000/queue/stats"
  Write-Host "Pending: $($stats.stats.pending) | Processing: $($stats.stats.processing)"
  Start-Sleep -Seconds 2
}
```

## 🆚 Comparación: Implementación Simple vs Completa

### Implementación Simple (Este Proyecto)

✅ Cola in-memory (Array JavaScript)  
✅ 3 workers con polling  
✅ Sin infraestructura adicional  
✅ Perfecto para demos y proyectos pequeños  
✅ Fácil de entender y debuggear

❌ No persiste tareas si el servidor reinicia  
❌ No escala a múltiples servidores  
❌ Sin garantías de entrega

### Implementación Completa (Producción)

✅ Message broker (RabbitMQ, SQS, Azure Service Bus)  
✅ Persistencia de mensajes  
✅ Garantías de entrega (at-least-once, exactly-once)  
✅ Escala horizontalmente (múltiples servidores)  
✅ Dead letter queues para mensajes fallidos  
✅ Message TTL y prioridades

❌ Infraestructura adicional compleja  
❌ Mayor overhead de configuración  
❌ Más costoso en recursos

## 📊 Métricas de Rendimiento

### Comparación de Throughput

```
1 Worker:
10 tareas × 3s promedio = 30 segundos
Throughput: 0.33 tareas/segundo

3 Workers:
10 tareas × 3s / 3 workers = ~10 segundos
Throughput: 1.00 tareas/segundo (3x mejora)

5 Workers:
10 tareas × 3s / 5 workers = ~6 segundos
Throughput: 1.67 tareas/segundo (5x mejora)
```

### Latencia vs Throughput

```
Sin Queue (Síncrono):
- Latencia: 3s por tarea
- Throughput: 0.33 tareas/s
- Experiencia: Usuario espera 3s

Con Queue (Asíncrono):
- Latencia: 50ms (encolar)
- Throughput: 1.00 tareas/s (3 workers)
- Experiencia: Respuesta inmediata
```

## 🔗 Relación con Otros Patrones

### Circuit Breaker

Protege a los workers de fallos en servicios externos:

```javascript
async function processTask(task, workerId) {
  try {
    // Usar Circuit Breaker para llamadas externas
    const result = await paymentCircuitBreaker.fire({
      amount: task.data.amount,
    });
  } catch (error) {
    taskQueue.markFailed(task.id, workerId, error);
  }
}
```

### Retry Pattern

Reintentar tareas fallidas:

```javascript
class TaskQueue {
  markFailed(taskId, workerId, error) {
    const task = this.failed.find((t) => t.id === taskId);

    if (task.attempts < 3) {
      // Reencolar con backoff
      setTimeout(() => {
        this.enqueue({ ...task, attempts: task.attempts + 1 });
      }, Math.pow(2, task.attempts) * 1000);
    }
  }
}
```

### Cache-Aside

Workers pueden cachear resultados:

```javascript
async function processTask(task, workerId) {
  const cacheKey = `task:result:${task.id}`;
  const cached = cacheService.get(cacheKey);

  if (cached) return cached;

  const result = await doHeavyWork(task);
  cacheService.set(cacheKey, result, 3600);

  return result;
}
```

## 📚 Referencias

- **Patrón Original:** Microsoft Cloud Design Patterns
- **Categoría:** Performance, Scalability
- **Relacionados:** Queue-Based Load Leveling, Priority Queue
- **Message Brokers:** RabbitMQ, AWS SQS, Azure Service Bus, Redis Pub/Sub

## 🎓 Conclusión

El patrón **Competing Consumers** es esencial para aplicaciones que necesitan procesar tareas de manera eficiente y escalable. Esta implementación simplificada demuestra el concepto de manera clara sin requerir infraestructura compleja, haciéndola ideal para proyectos académicos y prototipos.

**Ventajas Clave:**

- ✅ Procesamiento paralelo → Mayor throughput
- ✅ Escalabilidad horizontal → Agregar workers fácilmente
- ✅ Desacoplamiento → Productores y consumidores independientes
- ✅ Tolerancia a fallos → Workers independientes

**Casos de Uso Reales:**

- Envío de emails y notificaciones
- Procesamiento de pagos y transacciones
- Generación de reportes
- Procesamiento de imágenes/videos
- Integraciones con APIs externas

---

**Para producción**, considera migrar a un message broker como RabbitMQ para obtener persistencia, garantías de entrega y escalabilidad a múltiples servidores.
