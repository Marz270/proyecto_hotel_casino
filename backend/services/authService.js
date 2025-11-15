const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const pool = require("../database/db");

const JWT_SECRET =
  process.env.JWT_SECRET || "your-secret-key-change-in-production";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "24h";
const SALT_ROUNDS = 10;

class AuthService {
  /**
   * Genera un hash de contraseña usando bcrypt
   */
  async hashPassword(password) {
    return await bcrypt.hash(password, SALT_ROUNDS);
  }

  /**
   * Compara una contraseña con su hash
   */
  async comparePassword(password, hash) {
    return await bcrypt.compare(password, hash);
  }

  /**
   * Genera un token JWT
   */
  generateToken(user) {
    const payload = {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
    };

    return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
  }

  /**
   * Verifica un token JWT
   */
  verifyToken(token) {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      throw new Error("Token inválido o expirado");
    }
  }

  /**
   * Autentica un usuario
   */
  async login(username, password) {
    try {
      // Buscar usuario por username o email
      const query = `
        SELECT id, username, email, password_hash, role, created_at
        FROM users
        WHERE username = $1 OR email = $1
      `;
      const result = await pool.query(query, [username]);

      if (result.rows.length === 0) {
        throw new Error("Usuario no encontrado");
      }

      const user = result.rows[0];

      // Verificar contraseña
      const isValidPassword = await this.comparePassword(
        password,
        user.password_hash
      );

      if (!isValidPassword) {
        throw new Error("Contraseña incorrecta");
      }

      // Generar token
      const token = this.generateToken(user);

      // Retornar usuario sin el hash de contraseña
      const { password_hash, ...userWithoutPassword } = user;

      return {
        success: true,
        token,
        user: userWithoutPassword,
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Registra un nuevo usuario
   */
  async register(username, email, password, role = "user") {
    try {
      // Verificar si el usuario ya existe
      const checkQuery = `
        SELECT id FROM users
        WHERE username = $1 OR email = $2
      `;
      const checkResult = await pool.query(checkQuery, [username, email]);

      if (checkResult.rows.length > 0) {
        throw new Error("El usuario o email ya existe");
      }

      // Hashear contraseña
      const passwordHash = await this.hashPassword(password);

      // Insertar usuario
      const insertQuery = `
        INSERT INTO users (username, email, password_hash, role)
        VALUES ($1, $2, $3, $4)
        RETURNING id, username, email, role, created_at
      `;
      const result = await pool.query(insertQuery, [
        username,
        email,
        passwordHash,
        role,
      ]);

      const user = result.rows[0];

      // Generar token
      const token = this.generateToken(user);

      return {
        success: true,
        token,
        user,
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene información del usuario por ID
   */
  async getUserById(userId) {
    try {
      const query = `
        SELECT id, username, email, role, created_at
        FROM users
        WHERE id = $1
      `;
      const result = await pool.query(query, [userId]);

      if (result.rows.length === 0) {
        throw new Error("Usuario no encontrado");
      }

      return result.rows[0];
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new AuthService();
