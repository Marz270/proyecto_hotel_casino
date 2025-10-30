/**
 * Competing Consumers Pattern - API Routes
 *
 * Endpoints REST para gestionar la cola y los workers
 */

const express = require("express");
const router = express.Router();
const { taskQueue } = require("../patterns/competing-consumers/queueService");
const {
  startAllWorkers,
  stopAllWorkers,
  getWorkersStatus,
} = require("../patterns/competing-consumers/workerService");

/**
 * POST /queue/tasks
 * Agrega una nueva tarea a la cola
 */
router.post("/queue/tasks", (req, res) => {
  try {
    const { type, data } = req.body;

    if (!type) {
      return res.status(400).json({
        error: 'El campo "type" es requerido',
        validTypes: ["email", "reservation", "payment", "notification"],
      });
    }

    const task = taskQueue.enqueue({ type, data: data || {} });

    res.status(201).json({
      success: true,
      message: "Tarea agregada a la cola exitosamente",
      task,
    });
  } catch (error) {
    console.error("[API] Error al agregar tarea a la cola:", error);
    res.status(500).json({
      error: "Error al agregar tarea a la cola",
      details: error.message,
    });
  }
});

/**
 * POST /queue/tasks/batch
 * Agrega múltiples tareas a la cola de una vez
 */
router.post("/queue/tasks/batch", (req, res) => {
  try {
    const { tasks } = req.body;

    if (!Array.isArray(tasks) || tasks.length === 0) {
      return res.status(400).json({
        error: "Se requiere un array de tareas no vacío",
      });
    }

    const addedTasks = tasks.map((task) =>
      taskQueue.enqueue({ type: task.type, data: task.data || {} })
    );

    res.status(201).json({
      success: true,
      message: `${addedTasks.length} tareas agregadas a la cola exitosamente`,
      tasks: addedTasks,
    });
  } catch (error) {
    console.error("[API] Error al agregar tareas en batch:", error);
    res.status(500).json({
      error: "Error al agregar tareas a la cola",
      details: error.message,
    });
  }
});

/**
 * GET /queue/stats
 * Obtiene estadísticas de la cola
 */
router.get("/queue/stats", (req, res) => {
  try {
    const stats = taskQueue.getStats();
    const processingDetails = taskQueue.getProcessingDetails();
    const recentCompleted = taskQueue.getRecentCompleted(5);

    res.json({
      success: true,
      stats,
      processing: processingDetails,
      recentCompleted,
    });
  } catch (error) {
    console.error("[API] Error al obtener estadísticas:", error);
    res.status(500).json({
      error: "Error al obtener estadísticas",
      details: error.message,
    });
  }
});

/**
 * GET /queue/workers
 * Obtiene estado de los workers
 */
router.get("/queue/workers", (req, res) => {
  try {
    const workersStatus = getWorkersStatus();

    res.json({
      success: true,
      workers: workersStatus,
      totalWorkers: workersStatus.length,
      activeWorkers: workersStatus.filter((w) => w.isRunning).length,
    });
  } catch (error) {
    console.error("[API] Error al obtener estado de workers:", error);
    res.status(500).json({
      error: "Error al obtener estado de workers",
      details: error.message,
    });
  }
});

/**
 * POST /queue/workers/start
 * Inicia todos los workers
 */
router.post("/queue/workers/start", (req, res) => {
  try {
    startAllWorkers();

    res.json({
      success: true,
      message: "Workers iniciados exitosamente",
      workers: getWorkersStatus(),
    });
  } catch (error) {
    console.error("[API] Error al iniciar workers:", error);
    res.status(500).json({
      error: "Error al iniciar workers",
      details: error.message,
    });
  }
});

/**
 * POST /queue/workers/stop
 * Detiene todos los workers
 */
router.post("/queue/workers/stop", (req, res) => {
  try {
    stopAllWorkers();

    res.json({
      success: true,
      message: "Workers detenidos exitosamente",
      workers: getWorkersStatus(),
    });
  } catch (error) {
    console.error("[API] Error al detener workers:", error);
    res.status(500).json({
      error: "Error al detener workers",
      details: error.message,
    });
  }
});

/**
 * DELETE /queue/clear
 * Limpia tareas completadas y fallidas
 */
router.delete("/queue/clear", (req, res) => {
  try {
    taskQueue.clear();

    res.json({
      success: true,
      message: "Tareas completadas y fallidas limpiadas",
      stats: taskQueue.getStats(),
    });
  } catch (error) {
    console.error("[API] Error al limpiar cola:", error);
    res.status(500).json({
      error: "Error al limpiar cola",
      details: error.message,
    });
  }
});

/**
 * DELETE /queue/reset
 * Reinicia completamente la cola
 */
router.delete("/queue/reset", (req, res) => {
  try {
    stopAllWorkers();
    taskQueue.reset();

    res.json({
      success: true,
      message: "Cola reiniciada completamente",
      stats: taskQueue.getStats(),
    });
  } catch (error) {
    console.error("[API] Error al reiniciar cola:", error);
    res.status(500).json({
      error: "Error al reiniciar cola",
      details: error.message,
    });
  }
});

module.exports = router;
