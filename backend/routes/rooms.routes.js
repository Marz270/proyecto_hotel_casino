// backend/routes/rooms.routes.js
const express = require("express");
const { query } = require("express-validator");
const router = express.Router();
const pool = require("../database/db");
const cacheService = require("../services/cacheService");

// GET /rooms - Obtener habitaciones disponibles
router.get("/rooms", async (req, res) => {
  try {
    const { check_in, check_out } = req.query;

    let query = `
      SELECT r.*, 
        rt.type_name as room_type,
        rt.price_per_night,
        rt.max_guests,
        rt.description,
        rt.image_url,
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
      JOIN room_types rt ON r.room_type_id = rt.id
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

// GET /rooms/types - Obtener tipos de habitaciones únicos para la página principal
router.get("/rooms/types", async (req, res) => {
  try {
    const query = `
      SELECT 
        id,
        type_name,
        description,
        image_url,
        price_per_night,
        max_guests
      FROM room_types
      ORDER BY price_per_night
    `;

    const result = await pool.query(query);

    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Error fetching room types",
      details: error.message,
    });
  }
});

/**
 * GET /rooms/availability
 * Consulta disponibilidad de habitaciones (CON CACHE-ASIDE)
 */
router.get(
  "/rooms/availability",
  [
    query("check_in")
      .optional()
      .isISO8601()
      .withMessage("Fecha check_in inválida"),
    query("check_out")
      .optional()
      .isISO8601()
      .withMessage("Fecha check_out inválida"),
    query("month")
      .optional()
      .matches(/^\d{4}-\d{2}$/)
      .withMessage("Formato de mes inválido (YYYY-MM)"),
  ],
  async (req, res) => {
    try {
      const { check_in, check_out, month } = req.query;

      // Generar clave de cache basada en los parámetros
      const cacheKey = month
        ? `rooms:availability:month:${month}`
        : `rooms:availability:${check_in}:${check_out}`;

      // PASO 1: Intentar obtener del cache (CACHE-ASIDE)
      const cachedData = cacheService.get(cacheKey);

      if (cachedData) {
        return res.json({
          success: true,
          data: cachedData,
          source: "cache",
          message: "Data retrieved from cache",
        });
      }

      // PASO 2: Cache MISS - Consultar base de datos
      console.log(`[DB QUERY] Fetching room availability from PostgreSQL`);

      let query;
      let params;

      if (month) {
        // Consulta por mes
        query = `
          SELECT 
            r.id, 
            r.room_number, 
            rt.type_name as room_type, 
            rt.price_per_night,
            rt.max_guests,
            COALESCE(
              (SELECT COUNT(*) 
               FROM bookings b 
               WHERE b.room_id = r.id
                 AND TO_CHAR(b.check_in, 'YYYY-MM') = $1), 
              0
            ) as reservations_count
          FROM rooms r
          JOIN room_types rt ON r.room_type_id = rt.id
          ORDER BY r.room_number
        `;
        params = [month];
      } else {
        // Consulta por rango de fechas
        query = `
          SELECT 
            r.id, 
            r.room_number, 
            rt.type_name as room_type, 
            rt.price_per_night,
            rt.max_guests,
            CASE 
              WHEN EXISTS (
                SELECT 1 
                FROM bookings b 
                WHERE b.room_id = r.id
                  AND (
                    (b.check_in, b.check_out) OVERLAPS ($1::date, $2::date)
                  )
              ) THEN false
              ELSE true
            END as available
          FROM rooms r
          JOIN room_types rt ON r.room_type_id = rt.id
          ORDER BY r.room_number
        `;
        params = [check_in, check_out];
      }

      const result = await pool.query(query, params);

      // PASO 3: Almacenar en cache antes de responder
      cacheService.set(cacheKey, result.rows);

      res.json({
        success: true,
        data: result.rows,
        source: "database",
        message: "Data retrieved from database and cached",
      });
    } catch (error) {
      console.error("[ERROR] Error fetching room availability:", error);
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * GET /cache/stats
 * Obtener estadísticas del cache (para demostración)
 */
router.get("/cache/stats", (req, res) => {
  const stats = cacheService.getStats();
  res.json({
    success: true,
    data: stats,
  });
});

/**
 * POST /cache/clear
 * Limpiar todo el cache (para demostración)
 */
router.post("/cache/clear", (req, res) => {
  cacheService.clear();
  res.json({
    success: true,
    message: "Cache cleared successfully",
  });
});

module.exports = router;
