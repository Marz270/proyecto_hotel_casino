/**
 * Competing Consumers Pattern - Simple In-Memory Implementation
 *
 * Simula un sistema de colas con múltiples workers procesando tareas concurrentemente.
 * Ideal para demostración académica sin infraestructura adicional.
 */

class TaskQueue {
  constructor() {
    this.tasks = [];
    this.completed = [];
    this.failed = [];
    this.processing = new Map(); // workerId -> task
    this.stats = {
      totalEnqueued: 0,
      totalProcessed: 0,
      totalFailed: 0,
    };
  }

  /**
   * Agrega una tarea a la cola
   */
  enqueue(task) {
    const queuedTask = {
      id: `task-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      type: task.type || "email",
      data: task.data || {},
      status: "pending",
      enqueuedAt: new Date().toISOString(),
      attempts: 0,
    };

    this.tasks.push(queuedTask);
    this.stats.totalEnqueued++;

    console.log(
      `[QUEUE] Tarea agregada a la cola: ${queuedTask.id} (${queuedTask.type})`
    );
    return queuedTask;
  }

  /**
   * Obtiene la siguiente tarea disponible (FIFO)
   */
  dequeue() {
    if (this.tasks.length === 0) {
      return null;
    }

    const task = this.tasks.shift();
    task.status = "processing";
    task.dequeuedAt = new Date().toISOString();

    return task;
  }

  /**
   * Marca una tarea como completada
   */
  markCompleted(taskId, workerId, result) {
    this.processing.delete(workerId);

    const task = {
      id: taskId,
      workerId,
      completedAt: new Date().toISOString(),
      result,
    };

    this.completed.push(task);
    this.stats.totalProcessed++;

    console.log(`[QUEUE] Tarea completada: ${taskId} por Worker ${workerId}`);
  }

  /**
   * Marca una tarea como fallida
   */
  markFailed(taskId, workerId, error) {
    this.processing.delete(workerId);

    const task = {
      id: taskId,
      workerId,
      failedAt: new Date().toISOString(),
      error: error.message || error,
    };

    this.failed.push(task);
    this.stats.totalFailed++;

    console.log(
      `[QUEUE] Tarea fallida: ${taskId} por Worker ${workerId} - ${error}`
    );
  }

  /**
   * Registra que un worker está procesando una tarea
   */
  setProcessing(workerId, task) {
    this.processing.set(workerId, {
      taskId: task.id,
      startedAt: new Date().toISOString(),
      type: task.type,
    });
  }

  /**
   * Obtiene estadísticas de la cola
   */
  getStats() {
    return {
      pending: this.tasks.length,
      processing: this.processing.size,
      completed: this.completed.length,
      failed: this.failed.length,
      total: this.stats.totalEnqueued,
      successRate:
        this.stats.totalEnqueued > 0
          ? (
              (this.stats.totalProcessed / this.stats.totalEnqueued) *
              100
            ).toFixed(2) + "%"
          : "N/A",
    };
  }

  /**
   * Obtiene detalles de tareas en procesamiento
   */
  getProcessingDetails() {
    const details = [];
    this.processing.forEach((task, workerId) => {
      details.push({
        workerId,
        taskId: task.taskId,
        type: task.type,
        startedAt: task.startedAt,
        duration: Date.now() - new Date(task.startedAt).getTime(),
      });
    });
    return details;
  }

  /**
   * Obtiene las últimas tareas completadas
   */
  getRecentCompleted(limit = 10) {
    return this.completed.slice(-limit);
  }

  /**
   * Limpia todas las tareas completadas y fallidas
   */
  clear() {
    this.completed = [];
    this.failed = [];
    console.log("[QUEUE] Tareas completadas y fallidas limpiadas");
  }

  /**
   * Reinicia completamente la cola
   */
  reset() {
    this.tasks = [];
    this.completed = [];
    this.failed = [];
    this.processing.clear();
    this.stats = {
      totalEnqueued: 0,
      totalProcessed: 0,
      totalFailed: 0,
    };
    console.log("[QUEUE] Cola reiniciada completamente");
  }
}

// Singleton instance
const taskQueue = new TaskQueue();

module.exports = { taskQueue, TaskQueue };
