// backend/services/valetKeyService.js
const crypto = require("crypto");
const pool = require("../database/db");

const TOKEN_EXPIRY_MINUTES = 15;

/**
 * Genera un token temporal para upload de documentos
 */
async function generateUploadToken(bookingId, documentType) {
  // Validar que la reserva existe
  const bookingCheck = await pool.query(
    "SELECT id FROM bookings WHERE id = $1",
    [bookingId]
  );

  if (bookingCheck.rows.length === 0) {
    throw new Error("Booking not found");
  }

  // Generar token aleatorio seguro
  const token = crypto.randomBytes(32).toString("hex");
  const expiresAt = new Date(Date.now() + TOKEN_EXPIRY_MINUTES * 60 * 1000);

  // Guardar en BD
  await pool.query(
    `INSERT INTO upload_tokens (booking_id, token, document_type, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [bookingId, token, documentType, expiresAt]
  );

  return {
    token,
    uploadUrl: `${
      process.env.API_BASE_URL || "http://localhost:3000"
    }/upload/${token}`,
    expiresAt: expiresAt.toISOString(),
    allowedTypes: ["pdf", "jpg", "png"],
    maxSizeMB: 5,
  };
}

/**
 * Valida un token de upload
 */
async function validateToken(token) {
  const result = await pool.query(
    `SELECT booking_id, document_type, expires_at, used
     FROM upload_tokens
     WHERE token = $1`,
    [token]
  );

  if (result.rows.length === 0) {
    return { valid: false, error: "Token not found" };
  }

  const tokenData = result.rows[0];

  // Verificar si ya fue usado
  if (tokenData.used) {
    return { valid: false, error: "Token already used" };
  }

  // Verificar expiración
  if (new Date(tokenData.expires_at) < new Date()) {
    return { valid: false, error: "Token expired" };
  }

  return {
    valid: true,
    bookingId: tokenData.booking_id,
    documentType: tokenData.document_type,
  };
}

/**
 * Marca un token como usado
 */
async function markTokenAsUsed(token) {
  await pool.query("UPDATE upload_tokens SET used = true WHERE token = $1", [
    token,
  ]);
}

module.exports = {
  generateUploadToken,
  validateToken,
  markTokenAsUsed,
};
