const express = require("express");
const { body, validationResult } = require("express-validator");
const router = express.Router();
const authService = require("../services/authService");
const { authenticate } = require("../middleware/authMiddleware");

/**
 * POST /login
 * Iniciar sesión
 */
router.post(
  "/login",
  [
    body("username").notEmpty().withMessage("Usuario o email requerido"),
    body("password").notEmpty().withMessage("Contraseña requerida"),
  ],
  async (req, res) => {
    try {
      // Validar errores
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array(),
        });
      }

      const { username, password } = req.body;

      const result = await authService.login(username, password);

      res.json(result);
    } catch (error) {
      console.error("[AUTH] Login error:", error);
      res.status(401).json({
        success: false,
        error: error.message || "Error al iniciar sesión",
      });
    }
  }
);

/**
 * POST /register
 * Registrar nuevo usuario
 */
router.post(
  "/register",
  [
    body("username")
      .isLength({ min: 3, max: 50 })
      .withMessage("El username debe tener entre 3 y 50 caracteres"),
    body("email").isEmail().withMessage("Email inválido"),
    body("password")
      .isLength({ min: 6 })
      .withMessage("La contraseña debe tener al menos 6 caracteres"),
  ],
  async (req, res) => {
    try {
      // Validar errores
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array(),
        });
      }

      const { username, email, password, role } = req.body;

      const result = await authService.register(
        username,
        email,
        password,
        role
      );

      res.status(201).json(result);
    } catch (error) {
      console.error("[AUTH] Register error:", error);
      res.status(400).json({
        success: false,
        error: error.message || "Error al registrar usuario",
      });
    }
  }
);

/**
 * GET /me
 * Obtener información del usuario autenticado
 */
router.get("/me", authenticate, async (req, res) => {
  try {
    const user = await authService.getUserById(req.user.id);

    res.json({
      success: true,
      user,
    });
  } catch (error) {
    console.error("[AUTH] Get user error:", error);
    res.status(404).json({
      success: false,
      error: error.message || "Usuario no encontrado",
    });
  }
});

/**
 * POST /verify
 * Verificar si un token es válido
 */
router.post("/verify", authenticate, (req, res) => {
  res.json({
    success: true,
    user: req.user,
  });
});

module.exports = router;
