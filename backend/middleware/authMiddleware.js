const authService = require("../services/authService");

/**
 * Middleware para verificar el token JWT
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        error: "Token no proporcionado",
      });
    }

    // Formato esperado: "Bearer <token>"
    const parts = authHeader.split(" ");

    if (parts.length !== 2 || parts[0] !== "Bearer") {
      return res.status(401).json({
        success: false,
        error: "Formato de token inválido",
      });
    }

    const token = parts[1];

    // Verificar token
    const decoded = authService.verifyToken(token);

    // Agregar información del usuario al request
    req.user = decoded;

    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: error.message || "Token inválido",
    });
  }
};

/**
 * Middleware para verificar roles
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: "Usuario no autenticado",
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: "No tienes permisos para acceder a este recurso",
      });
    }

    next();
  };
};

module.exports = {
  authenticate,
  authorize,
};
