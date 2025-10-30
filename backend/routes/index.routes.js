const express = require("express");
const cacheService = require("../services/cacheService");
const { body, param, validationResult } = require("express-validator");
const BookingServiceFactory = require("../services/bookingServiceFactory");
const {
  paymentCircuitBreaker,
  getCircuitBreakerStatus,
  resetCircuitBreaker,
} = require("../patterns/circuit-breaker/paymentCircuitBreaker");
const router = express.Router();

// Competing Consumers Pattern - Queue routes
const queueRoutes = require("./queue.routes");
router.use(queueRoutes);

// Inyección de dependencia - el servicio se resuelve en runtime
const bookingService = BookingServiceFactory.createBookingService();

// Middleware para validar errores de express-validator
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: "Validation failed",
      details: errors.array(),
    });
  }
  next();
};

// Root endpoint
router.get("/", (req, res) => {
  res.json({
    success: true,
    data: {
      message: "🏨 Salto Hotel & Casino API",
      version: process.env.APP_VERSION || "1.0",
      booking_mode: process.env.BOOKING_MODE || "pg",
      endpoints: {
        "GET /health": "Health check endpoint",
        "GET /rooms": "Get available rooms",
        "GET /bookings": "Get all reservations",
        "POST /reservations": "Create new reservation",
        "POST /payments": "Process payment (with Circuit Breaker)",
        "GET /payments/circuit-status": "Get Circuit Breaker status",
        "POST /payments/circuit-reset": "Reset Circuit Breaker (admin)",
        "GET /reports": "Get admin reports",
        "GET /bookings/:id": "Get booking by ID",
        "DELETE /bookings/:id": "Delete booking by ID",
      },
    },
  });
});

// Health check endpoint - Health Endpoint Monitoring Pattern
router.get("/health", async (req, res) => {
  const healthCheck = {
    status: "healthy",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || "development",
    version: process.env.APP_VERSION || "1.0.0",
    checks: {
      database: { status: "unknown" },
      memory: { status: "unknown" },
      circuitBreaker: { status: "unknown" },
    },
  };

  let isHealthy = true;

  // 1. Check database connection
  try {
    const db = require("../database/db");
    const result = await db.query("SELECT 1 as health");

    if (result.rows && result.rows[0].health === 1) {
      healthCheck.checks.database = {
        status: "healthy",
        responseTime: "< 10ms",
      };
    } else {
      throw new Error("Database check failed");
    }
  } catch (error) {
    isHealthy = false;
    healthCheck.checks.database = {
      status: "unhealthy",
      error: error.message,
    };
  }

  // 2. Check memory usage
  try {
    const memUsage = process.memoryUsage();
    const memoryUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
    const memoryTotalMB = Math.round(memUsage.heapTotal / 1024 / 1024);
    const memoryPercentage = Math.round(
      (memUsage.heapUsed / memUsage.heapTotal) * 100
    );

    healthCheck.checks.memory = {
      status: memoryPercentage < 90 ? "healthy" : "warning",
      used: `${memoryUsedMB} MB`,
      total: `${memoryTotalMB} MB`,
      percentage: `${memoryPercentage}%`,
    };

    if (memoryPercentage >= 95) {
      isHealthy = false;
      healthCheck.checks.memory.status = "unhealthy";
    }
  } catch (error) {
    healthCheck.checks.memory = {
      status: "unhealthy",
      error: error.message,
    };
  }

  // 3. Check Circuit Breaker status
  try {
    const cbStatus = getCircuitBreakerStatus();
    healthCheck.checks.circuitBreaker = {
      status: cbStatus.state === "OPEN" ? "degraded" : "healthy",
      state: cbStatus.state,
      stats: {
        totalRequests: cbStatus.stats.fires,
        failures: cbStatus.stats.failures,
        successRate: cbStatus.stats.successRate,
      },
    };

    // Circuit breaker OPEN no es crítico para health general
    if (cbStatus.state === "OPEN") {
      healthCheck.checks.circuitBreaker.message =
        "Payment service circuit is open (degraded mode)";
    }
  } catch (error) {
    healthCheck.checks.circuitBreaker = {
      status: "unknown",
      error: error.message,
    };
  }

  // Set overall status
  healthCheck.status = isHealthy ? "healthy" : "unhealthy";

  // Return appropriate HTTP status code
  const statusCode = isHealthy ? 200 : 503;

  res.status(statusCode).json({
    success: isHealthy,
    data: healthCheck,
  });
});

// GET /bookings - Obtener todas las reservas
router.get("/bookings", async (req, res) => {
  try {
    const result = await bookingService.getAllBookings();

    if (result.success) {
      res.json({
        success: true,
        data: result.data,
        source: result.source,
        count: result.data.length,
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error,
        source: result.source,
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Internal server error",
      details: error.message,
    });
  }
});

// POST /bookings - Crear nueva reserva
router.post(
  "/bookings",
  [
    body("client_name")
      .notEmpty()
      .withMessage("Client name is required")
      .isLength({ min: 2 })
      .withMessage("Client name must be at least 2 characters"),
    body("room_number")
      .isInt({ min: 1 })
      .withMessage("Room number must be a positive integer"),
    body("check_in").isDate().withMessage("Check-in must be a valid date"),
    body("check_out").isDate().withMessage("Check-out must be a valid date"),
    body("total_price")
      .isFloat({ min: 0 })
      .withMessage("Total price must be a positive number"),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const result = await bookingService.createBooking(req.body);

      if (result.success) {
        // CACHE-ASIDE: Invalidar cache de disponibilidad al crear reserva
        // Esto garantiza que las próximas consultas obtengan datos actualizados
        cacheService.invalidatePattern("rooms:availability:*");
        console.log("[CACHE INVALIDATION] Booking created, cache invalidated");

        res.status(201).json({
          success: true,
          data: result.data,
          source: result.source,
          message: "Booking created successfully",
        });
      } else {
        res.status(400).json({
          success: false,
          error: result.error,
          source: result.source,
        });
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        error: "Internal server error",
        details: error.message,
      });
    }
  }
);

// GET /bookings/:id - Obtener reserva por ID
router.get(
  "/bookings/:id",
  [
    param("id").isInt({ min: 1 }).withMessage("ID must be a positive integer"),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const result = await bookingService.getBookingById(req.params.id);

      if (result.success) {
        res.json({
          success: true,
          data: result.data,
          source: result.source,
        });
      } else {
        res.status(404).json({
          success: false,
          error: result.error,
          source: result.source,
        });
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        error: "Internal server error",
        details: error.message,
      });
    }
  }
);

// DELETE /bookings/:id - Eliminar reserva por ID
router.delete(
  "/bookings/:id",
  [
    param("id").isInt({ min: 1 }).withMessage("ID must be a positive integer"),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const result = await bookingService.deleteBooking(req.params.id);

      if (result.success) {
        // CACHE-ASIDE: Invalidar cache de disponibilidad al eliminar reserva
        // Esto garantiza que las próximas consultas obtengan datos actualizados
        cacheService.invalidatePattern("rooms:availability:*");
        console.log("[CACHE INVALIDATION] Booking deleted, cache invalidated");

        res.json({
          success: true,
          data: result.data,
          source: result.source,
          message: "Booking deleted successfully",
        });
      } else {
        res.status(404).json({
          success: false,
          error: result.error,
          source: result.source,
        });
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        error: "Internal server error",
        details: error.message,
      });
    }
  }
);

// POST /reservations - Crear nueva reserva (alias para /bookings)
router.post(
  "/reservations",
  [
    body("client_name")
      .notEmpty()
      .withMessage("Client name is required")
      .isLength({ min: 2 })
      .withMessage("Client name must be at least 2 characters"),
    body("room_number")
      .isInt({ min: 1 })
      .withMessage("Room number must be a positive integer"),
    body("check_in").isDate().withMessage("Check-in must be a valid date"),
    body("check_out").isDate().withMessage("Check-out must be a valid date"),
    body("total_price")
      .isFloat({ min: 0 })
      .withMessage("Total price must be a positive number"),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const result = await bookingService.createBooking(req.body);

      if (result.success) {
        // CACHE-ASIDE: Invalidar cache de disponibilidad al crear reserva
        // Esto garantiza que las próximas consultas obtengan datos actualizados
        cacheService.invalidatePattern("rooms:availability:*");
        console.log(
          "[CACHE INVALIDATION] Reservation created, cache invalidated"
        );

        res.status(201).json({
          success: true,
          data: result.data,
          source: result.source,
          message: "Reservation created successfully",
        });
      } else {
        res.status(400).json({
          success: false,
          error: result.error,
          source: result.source,
        });
      }
    } catch (error) {
      res.status(500).json({
        success: false,
        error: "Internal server error",
        details: error.message,
      });
    }
  }
);

// POST /payments - Procesar pago con Circuit Breaker
router.post(
  "/payments",
  [
    body("reservation_id")
      .isInt({ min: 1 })
      .withMessage("Reservation ID must be a positive integer"),
    body("amount")
      .isFloat({ min: 0 })
      .withMessage("Amount must be a positive number"),
    body("payment_method")
      .isIn(["credit_card", "debit_card", "cash", "transfer"])
      .withMessage("Invalid payment method"),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const { reservation_id, amount, payment_method } = req.body;

      // Procesar pago a través del Circuit Breaker
      // El circuit breaker protege de fallos en cascada del servicio de pagos
      const paymentResult = await paymentCircuitBreaker.fire({
        reservation_id,
        amount,
        payment_method,
      });

      // Si el pago está en cola (fallback), responder con 202 Accepted
      if (paymentResult.queued) {
        return res.status(202).json({
          success: true,
          data: paymentResult,
          message: paymentResult.message,
          warning:
            "Payment service is temporarily unavailable. Payment queued for processing.",
        });
      }

      // Pago procesado exitosamente
      res.status(201).json({
        success: true,
        data: paymentResult,
        message: "Payment processed successfully",
      });
    } catch (error) {
      // Error no manejado por el circuit breaker
      console.error("Payment error:", error);

      res.status(500).json({
        success: false,
        error: "Payment processing failed",
        details: error.message,
        code: error.code || "PAYMENT_ERROR",
      });
    }
  }
);

// GET /payments/circuit-status - Obtener estado del Circuit Breaker
router.get("/payments/circuit-status", (req, res) => {
  try {
    const status = getCircuitBreakerStatus();

    res.json({
      success: true,
      data: status,
      message: "Circuit Breaker status retrieved successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Failed to get circuit breaker status",
      details: error.message,
    });
  }
});

// POST /payments/circuit-reset - Resetear Circuit Breaker manualmente (admin)
router.post("/payments/circuit-reset", (req, res) => {
  try {
    resetCircuitBreaker();

    res.json({
      success: true,
      message: "Circuit Breaker reset to CLOSED state",
      data: getCircuitBreakerStatus(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Failed to reset circuit breaker",
      details: error.message,
    });
  }
});

// GET /reports - Obtener reportes administrativos
router.get("/reports", async (req, res) => {
  try {
    const { type } = req.query;

    let reportData = {};

    if (!type || type === "occupancy") {
      // Reporte de ocupación
      const occupancyQuery = `
        SELECT 
          COUNT(DISTINCT room_number) as total_rooms,
          COUNT(CASE WHEN check_out > CURRENT_DATE THEN 1 END) as occupied_rooms,
          ROUND(
            (COUNT(CASE WHEN check_out > CURRENT_DATE THEN 1 END) * 100.0 / COUNT(DISTINCT room_number)), 2
          ) as occupancy_rate
        FROM rooms r
        LEFT JOIN bookings b ON r.room_number = b.room_number
      `;

      const occupancyResult = await require("../database/db").query(
        occupancyQuery
      );
      reportData.occupancy = occupancyResult.rows[0];
    }

    if (!type || type === "revenue") {
      // Reporte de ingresos
      const revenueQuery = `
        SELECT 
          DATE_TRUNC('month', created_at) as month,
          COUNT(*) as total_bookings,
          SUM(total_price) as total_revenue
        FROM bookings 
        WHERE created_at >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY month DESC
      `;

      const revenueResult = await require("../database/db").query(revenueQuery);
      reportData.revenue = revenueResult.rows;
    }

    if (!type || type === "summary") {
      // Resumen general
      const summaryQuery = `
        SELECT 
          (SELECT COUNT(*) FROM bookings) as total_bookings,
          (SELECT COUNT(*) FROM rooms) as total_rooms,
          (SELECT AVG(total_price) FROM bookings) as avg_booking_value,
          (SELECT COUNT(*) FROM bookings WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as bookings_last_month
      `;

      const summaryResult = await require("../database/db").query(summaryQuery);
      reportData.summary = summaryResult.rows[0];
    }

    res.json({
      success: true,
      data: reportData,
      generated_at: new Date().toISOString(),
      report_type: type || "all",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Error generating reports",
      details: error.message,
    });
  }
});

module.exports = router;
