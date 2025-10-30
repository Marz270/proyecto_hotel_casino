/**
 * Circuit Breaker para el servicio de pagos externos
 * 
 * Patrón de disponibilidad que protege al sistema de fallos en cascada
 * cuando el servicio de pagos está experimentando problemas.
 * 
 * Estados:
 * - CLOSED: Funcionamiento normal, todas las peticiones pasan
 * - OPEN: Circuito abierto, peticiones fallan inmediatamente sin intentar la operación
 * - HALF_OPEN: Estado de prueba, permite una petición para verificar si el servicio se recuperó
 * 
 * Configuración:
 * - Umbral de errores: 5 fallos consecutivos
 * - Timeout: 60 segundos antes de pasar a HALF_OPEN
 * - Timeout de petición: 3000ms
 */

const CircuitBreaker = require('opossum');

// Opciones del Circuit Breaker
const circuitBreakerOptions = {
  timeout: 3000, // Si la operación tarda más de 3s, se considera fallo
  errorThresholdPercentage: 50, // % de errores para abrir el circuito
  resetTimeout: 60000, // 60s antes de intentar cerrar el circuito (pasar a HALF_OPEN)
  rollingCountTimeout: 10000, // Ventana de tiempo para contar errores (10s)
  rollingCountBuckets: 10, // Número de buckets para estadísticas
  name: 'PaymentServiceBreaker', // Nombre del breaker para logging
  volumeThreshold: 5, // Mínimo de peticiones antes de calcular porcentaje de error
};

/**
 * Simula una llamada a un servicio de pagos externo (pasarela de pagos)
 * En producción, esto sería una llamada HTTP a una API real (Stripe, PayPal, etc.)
 * 
 * @param {Object} paymentData - Datos del pago
 * @returns {Promise<Object>} - Resultado del procesamiento
 */
async function processPaymentExternal(paymentData) {
  const { reservation_id, amount, payment_method } = paymentData;

  // Simular llamada a API externa con posibilidad de fallo
  // En producción: await axios.post('https://payment-gateway.com/process', paymentData)
  
  return new Promise((resolve, reject) => {
    // Simular latencia de red
    const delay = Math.random() * 2000 + 500; // 500ms - 2500ms
    
    setTimeout(() => {
      // Simular fallo aleatorio (15% de probabilidad para demostración)
      // En producción, los fallos vendrían del servicio externo real
      const shouldFail = Math.random() < 0.15;
      
      if (shouldFail) {
        const error = new Error('Payment gateway temporarily unavailable');
        error.code = 'PAYMENT_GATEWAY_ERROR';
        error.statusCode = 503;
        reject(error);
      } else {
        // Pago exitoso
        resolve({
          id: Math.floor(Math.random() * 10000),
          reservation_id,
          amount,
          payment_method,
          status: 'approved',
          transaction_id: `TXN_${Date.now()}`,
          processed_at: new Date().toISOString(),
          gateway: 'simulated-payment-gateway',
        });
      }
    }, delay);
  });
}

// Crear instancia del Circuit Breaker envolviendo la función de pago
const paymentCircuitBreaker = new CircuitBreaker(processPaymentExternal, circuitBreakerOptions);

// Event listeners para logging y monitoreo

paymentCircuitBreaker.on('open', () => {
  console.warn('⚠️  Circuit Breaker OPENED - Payment service appears to be down');
  console.warn('   Subsequent requests will fail fast without attempting payment processing');
});

paymentCircuitBreaker.on('halfOpen', () => {
  console.info('🔄 Circuit Breaker HALF-OPEN - Testing if payment service recovered');
});

paymentCircuitBreaker.on('close', () => {
  console.info('✅ Circuit Breaker CLOSED - Payment service is healthy again');
});

paymentCircuitBreaker.on('success', (result) => {
  console.log(`✅ Payment processed successfully: ${result.transaction_id}`);
});

paymentCircuitBreaker.on('failure', (error) => {
  console.error(`❌ Payment processing failed: ${error.message}`);
});

paymentCircuitBreaker.on('timeout', () => {
  console.error('⏱️  Payment processing timeout exceeded');
});

paymentCircuitBreaker.on('fallback', (result) => {
  console.info('🔄 Fallback triggered, returning cached/default response');
});

paymentCircuitBreaker.on('reject', () => {
  console.warn('🚫 Request rejected - Circuit is OPEN');
});

// Función de fallback: qué hacer cuando el circuito está abierto
paymentCircuitBreaker.fallback((paymentData) => {
  console.warn('📋 Using fallback: queuing payment for later processing');
  
  // En un sistema real, aquí podrías:
  // 1. Encolar el pago en una cola de mensajes (RabbitMQ, Redis Queue)
  // 2. Guardar en BD con estado 'pending' para reintento posterior
  // 3. Retornar un código de pago provisional
  
  return {
    id: null,
    reservation_id: paymentData.reservation_id,
    amount: paymentData.amount,
    payment_method: paymentData.payment_method,
    status: 'pending',
    transaction_id: `PENDING_${Date.now()}`,
    processed_at: new Date().toISOString(),
    message: 'Payment queued for processing. Payment gateway is temporarily unavailable.',
    queued: true,
  };
});

/**
 * Obtiene el estado actual del Circuit Breaker
 * @returns {Object} Estado y estadísticas del breaker
 */
function getCircuitBreakerStatus() {
  const stats = paymentCircuitBreaker.stats;
  
  return {
    state: paymentCircuitBreaker.opened ? 'OPEN' : 
           paymentCircuitBreaker.halfOpen ? 'HALF_OPEN' : 'CLOSED',
    stats: {
      fires: stats.fires, // Total de peticiones
      successes: stats.successes,
      failures: stats.failures,
      rejects: stats.rejects, // Rechazadas por circuito abierto
      timeouts: stats.timeouts,
      fallbacks: stats.fallbacks,
      latencyMean: stats.latencyMean, // Latencia promedio en ms
      percentiles: {
        p50: stats.percentiles['0.5'],
        p90: stats.percentiles['0.9'],
        p99: stats.percentiles['0.99'],
      },
    },
    options: {
      timeout: circuitBreakerOptions.timeout,
      errorThreshold: circuitBreakerOptions.errorThresholdPercentage,
      resetTimeout: circuitBreakerOptions.resetTimeout,
    },
  };
}

/**
 * Resetea manualmente el Circuit Breaker (para testing o admin)
 */
function resetCircuitBreaker() {
  paymentCircuitBreaker.close();
  console.info('🔧 Circuit Breaker manually reset to CLOSED state');
}

module.exports = {
  paymentCircuitBreaker,
  getCircuitBreakerStatus,
  resetCircuitBreaker,
};
