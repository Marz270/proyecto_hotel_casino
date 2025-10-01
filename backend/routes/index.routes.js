const express = require("express");
const { body, param, validationResult } = require("express-validator");
const BookingServiceFactory = require("../services/bookingServiceFactory");
const router = express.Router();

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
    message: "🏨 Salto Hotel & Casino API",
    version: process.env.APP_VERSION || "1.0",
    booking_mode: process.env.BOOKING_MODE || "pg",
    endpoints: {
      "GET /rooms": "Get available rooms",
      "GET /bookings": "Get all reservations",
      "POST /reservations": "Create new reservation",
      "POST /payments": "Process payment",
      "GET /reports": "Get admin reports",
      "GET /bookings/:id": "Get booking by ID",
      "DELETE /bookings/:id": "Delete booking by ID",
    },
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

// GET /rooms - Obtener habitaciones disponibles
router.get("/rooms", async (req, res) => {
  try {
    const { check_in, check_out } = req.query;

    let query = `
      SELECT r.*, 
        CASE WHEN EXISTS (
          SELECT 1 FROM bookings b 
          WHERE b.room_number = r.room_number 
          AND (
            (b.check_in <= $1 AND b.check_out > $1) OR
            (b.check_in < $2 AND b.check_out >= $2) OR
            (b.check_in >= $1 AND b.check_out <= $2)
          )
        ) THEN false ELSE true END as available
      FROM rooms r
      ORDER BY r.room_number
    `;

    const values =
      check_in && check_out
        ? [check_in, check_out]
        : ["1900-01-01", "1900-01-01"];

    const result = await require("../database/db").query(query, values);

    res.json({
      success: true,
      data: result.rows,
      filters: { check_in, check_out },
      count: result.rows.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Error fetching rooms",
      details: error.message,
    });
  }
});

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

// POST /payments - Procesar pago
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

      // Simular procesamiento de pago
      const paymentResult = {
        id: Math.floor(Math.random() * 10000),
        reservation_id,
        amount,
        payment_method,
        status: "approved",
        transaction_id: `TXN_${Date.now()}`,
        processed_at: new Date().toISOString(),
      };

      res.status(201).json({
        success: true,
        data: paymentResult,
        message: "Payment processed successfully",
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: "Payment processing failed",
        details: error.message,
      });
    }
  }
);

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
