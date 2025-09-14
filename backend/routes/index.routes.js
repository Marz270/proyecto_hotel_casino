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
      "GET /bookings": "Get all bookings",
      "POST /bookings": "Create new booking",
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

module.exports = router;
