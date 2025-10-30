/**
 * Competing Consumers Pattern - Worker Implementation
 *
 * Workers que procesan tareas de la cola concurrentemente.
 * Cada worker simula procesamiento de diferentes tipos de tareas.
 */

const { taskQueue } = require("./queueService");

/**
 * Simula el procesamiento de diferentes tipos de tareas
 */
async function processTask(task, workerId) {
  const processingTime = Math.random() * 3000 + 1000; // 1-4 segundos

  console.log(`[WORKER ${workerId}] Iniciando tarea ${task.id} (${task.type})`);

  try {
    // Simular procesamiento según el tipo de tarea
    await new Promise((resolve) => setTimeout(resolve, processingTime));

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
      default:
        result = { success: true, message: "Tarea genérica procesada" };
    }

    taskQueue.markCompleted(task.id, workerId, result);
    console.log(
      `[WORKER ${workerId}] ✓ Completado ${task.id} en ${(
        processingTime / 1000
      ).toFixed(2)}s`
    );
  } catch (error) {
    taskQueue.markFailed(task.id, workerId, error);
    console.error(
      `[WORKER ${workerId}] ✗ Error en ${task.id}: ${error.message}`
    );
  }
}

/**
 * Simula envío de email
 */
async function simulateEmailSending(data, workerId) {
  const { to, subject, bookingId } = data;

  // Simular fallo ocasional (10% de probabilidad)
  if (Math.random() < 0.1) {
    throw new Error("SMTP connection timeout");
  }

  return {
    success: true,
    type: "email",
    to: to || "guest@example.com",
    subject: subject || "Confirmación de Reserva",
    bookingId,
    sentAt: new Date().toISOString(),
    processedBy: `worker-${workerId}`,
  };
}

/**
 * Simula procesamiento de reserva
 */
async function simulateReservationProcessing(data, workerId) {
  const { clientId, roomId, checkIn, checkOut } = data;

  // Simular validaciones
  if (!clientId || !roomId) {
    throw new Error("Datos de reserva incompletos");
  }

  return {
    success: true,
    type: "reservation",
    reservationId: `RES-${Date.now()}`,
    clientId,
    roomId,
    checkIn: checkIn || new Date().toISOString(),
    checkOut: checkOut || new Date(Date.now() + 86400000).toISOString(),
    status: "confirmed",
    processedBy: `worker-${workerId}`,
  };
}

/**
 * Simula procesamiento de pago
 */
async function simulatePaymentProcessing(data, workerId) {
  const { amount, currency, cardLast4 } = data;

  // Simular fallo ocasional (5% de probabilidad)
  if (Math.random() < 0.05) {
    throw new Error("Payment gateway error");
  }

  return {
    success: true,
    type: "payment",
    transactionId: `TXN-${Date.now()}`,
    amount: amount || 100,
    currency: currency || "USD",
    cardLast4: cardLast4 || "1234",
    status: "approved",
    processedBy: `worker-${workerId}`,
  };
}

/**
 * Simula envío de notificación
 */
async function simulateNotificationSending(data, workerId) {
  const { userId, message, channel } = data;

  return {
    success: true,
    type: "notification",
    notificationId: `NOT-${Date.now()}`,
    userId: userId || "user-123",
    message: message || "Nueva actualización disponible",
    channel: channel || "push",
    deliveredAt: new Date().toISOString(),
    processedBy: `worker-${workerId}`,
  };
}

/**
 * Worker que procesa tareas continuamente
 */
class Worker {
  constructor(id, pollInterval = 2000) {
    this.id = id;
    this.pollInterval = pollInterval;
    this.intervalId = null;
    this.isRunning = false;
    this.tasksProcessed = 0;
  }

  /**
   * Inicia el worker
   */
  start() {
    if (this.isRunning) {
      console.log(`[WORKER ${this.id}] Ya está ejecutándose`);
      return;
    }

    this.isRunning = true;
    console.log(
      `[WORKER ${this.id}] Iniciado - Polling cada ${this.pollInterval}ms`
    );

    this.intervalId = setInterval(async () => {
      const task = taskQueue.dequeue();

      if (task) {
        this.tasksProcessed++;
        taskQueue.setProcessing(this.id, task);
        await processTask(task, this.id);
      }
    }, this.pollInterval);
  }

  /**
   * Detiene el worker
   */
  stop() {
    if (!this.isRunning) {
      console.log(`[WORKER ${this.id}] Ya está detenido`);
      return;
    }

    clearInterval(this.intervalId);
    this.isRunning = false;
    console.log(
      `[WORKER ${this.id}] Detenido - Tareas procesadas: ${this.tasksProcessed}`
    );
  }

  /**
   * Obtiene estado del worker
   */
  getStatus() {
    return {
      id: this.id,
      isRunning: this.isRunning,
      tasksProcessed: this.tasksProcessed,
      pollInterval: this.pollInterval,
    };
  }
}

// Crear pool de 3 workers
const workers = [new Worker(1, 2000), new Worker(2, 2500), new Worker(3, 3000)];

/**
 * Inicia todos los workers
 */
function startAllWorkers() {
  console.log("\n[COMPETING CONSUMERS] Iniciando pool de workers...\n");
  workers.forEach((worker) => worker.start());
}

/**
 * Detiene todos los workers
 */
function stopAllWorkers() {
  console.log("\n[COMPETING CONSUMERS] Deteniendo pool de workers...\n");
  workers.forEach((worker) => worker.stop());
}

/**
 * Obtiene estado de todos los workers
 */
function getWorkersStatus() {
  return workers.map((worker) => worker.getStatus());
}

module.exports = {
  Worker,
  workers,
  startAllWorkers,
  stopAllWorkers,
  getWorkersStatus,
  processTask,
};
