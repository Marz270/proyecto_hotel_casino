// backend/routes/valetKey.routes.js
const express = require("express");
const { body, param } = require("express-validator");
const valetKeyService = require("../services/valetKeyService");
const router = express.Router();

// Middleware de validación (reutilizar del proyecto)
const handleValidationErrors = (req, res, next) => {
  const { validationResult } = require("express-validator");
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

/**
 * POST /bookings/:id/upload-token
 * Solicitar token temporal para subir documento
 */
router.post(
  "/bookings/:id/upload-token",
  [
    param("id").isInt({ min: 1 }),
    body("documentType").isIn(["passport", "id_card", "payment_proof"]),
    handleValidationErrors,
  ],
  async (req, res) => {
    try {
      const { id } = req.params;
      const { documentType } = req.body;

      const tokenInfo = await valetKeyService.generateUploadToken(
        parseInt(id),
        documentType
      );

      res.json({
        success: true,
        data: tokenInfo,
        message: "Upload token generated successfully",
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message,
      });
    }
  }
);

/**
 * PUT /upload/:token
 * Simular upload usando el token (demo simplificada)
 */
router.put("/upload/:token", async (req, res) => {
  try {
    const { token } = req.params;

    // Validar token
    const validation = await valetKeyService.validateToken(token);

    if (!validation.valid) {
      return res.status(403).json({
        success: false,
        error: validation.error,
      });
    }

    // Simular procesamiento del archivo
    // En producción, aquí se subiría a S3/Azure
    const uploadResult = {
      bookingId: validation.bookingId,
      documentType: validation.documentType,
      filename: req.headers["x-filename"] || "document.pdf",
      uploadedAt: new Date().toISOString(),
      status: "uploaded",
    };

    // Marcar token como usado
    await valetKeyService.markTokenAsUsed(token);

    res.json({
      success: true,
      data: uploadResult,
      message: "Document uploaded successfully",
      note: "DEMO MODE: En producción, el archivo se subiría a S3 sin pasar por el backend",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /upload/:token/validate
 * Verificar validez de un token (para debugging)
 */
router.get("/upload/:token/validate", async (req, res) => {
  try {
    const { token } = req.params;
    const validation = await valetKeyService.validateToken(token);

    res.json({
      success: true,
      data: validation,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

module.exports = router;
