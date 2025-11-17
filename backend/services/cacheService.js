// backend/services/cacheService.js
/**
 * Servicio de Cache en memoria (implementación simplificada de Cache-Aside)
 * En producción, usar Redis con node-redis
 */

class CacheService {
  constructor() {
    // Map para almacenar cache en memoria
    this.cache = new Map();

    // Configuración por defecto
    this.defaultTTL = 5 * 60 * 1000; // 5 minutos en milisegundos

    // Limpiar cache expirado cada minuto
    this.startCleanupInterval();
  }

  /**
   * Obtiene un valor del cache
   * @param {string} key - Clave del cache
   * @returns {*} Valor cacheado o null si no existe/expiró
   */
  get(key) {
    const item = this.cache.get(key);

    if (!item) {
      console.log(`[CACHE MISS] Key: ${key}`);
      return null;
    }

    // Verificar si expiró
    if (Date.now() > item.expiresAt) {
      console.log(`[CACHE EXPIRED] Key: ${key}`);
      this.cache.delete(key);
      return null;
    }

    console.log(`[CACHE HIT] Key: ${key}`);
    return item.value;
  }

  /**
   * Almacena un valor en cache
   * @param {string} key - Clave del cache
   * @param {*} value - Valor a cachear
   * @param {number} ttl - Tiempo de vida en milisegundos (opcional)
   */
  set(key, value, ttl = this.defaultTTL) {
    const expiresAt = Date.now() + ttl;

    this.cache.set(key, {
      value,
      expiresAt,
      createdAt: new Date().toISOString(),
    });

    console.log(
      `[CACHE SET] Key: ${key}, Expires: ${new Date(expiresAt).toISOString()}`
    );
  }

  /**
   * Invalida (elimina) una clave del cache
   * @param {string} key - Clave a invalidar
   */
  invalidate(key) {
    const deleted = this.cache.delete(key);
    if (deleted) {
      console.log(`[CACHE INVALIDATED] Key: ${key}`);
    }
    return deleted;
  }

  /**
   * Invalida múltiples claves que coincidan con un patrón
   * @param {string} pattern - Patrón de búsqueda (ej: "rooms:*")
   */
  invalidatePattern(pattern) {
    const regex = new RegExp(pattern.replace("*", ".*"));
    let count = 0;

    for (const key of this.cache.keys()) {
      if (regex.test(key)) {
        this.cache.delete(key);
        count++;
      }
    }

    console.log(
      `[CACHE INVALIDATED PATTERN] Pattern: ${pattern}, Count: ${count}`
    );
    return count;
  }

  /**
   * Limpia todo el cache
   */
  clear() {
    const size = this.cache.size;
    this.cache.clear();
    console.log(`[CACHE CLEARED] Removed ${size} items`);
  }

  /**
   * Obtiene estadísticas del cache
   */
  getStats() {
    const now = Date.now();
    let expired = 0;
    let active = 0;

    for (const [key, item] of this.cache.entries()) {
      if (now > item.expiresAt) {
        expired++;
      } else {
        active++;
      }
    }

    return {
      totalItems: this.cache.size,
      activeItems: active,
      expiredItems: expired,
      defaultTTL: this.defaultTTL,
    };
  }

  /**
   * Limpia items expirados automáticamente
   */
  startCleanupInterval() {
    setInterval(() => {
      const now = Date.now();
      let cleaned = 0;

      for (const [key, item] of this.cache.entries()) {
        if (now > item.expiresAt) {
          this.cache.delete(key);
          cleaned++;
        }
      }

      if (cleaned > 0) {
        console.log(`[CACHE CLEANUP] Removed ${cleaned} expired items`);
      }
    }, 60 * 1000); // Cada 60 segundos
  }
}

// Singleton
const cacheService = new CacheService();

module.exports = cacheService;
