/**
 * Test manual del Circuit Breaker
 * 
 * Este script demuestra el funcionamiento del Circuit Breaker
 * sin necesidad de levantar el servidor completo.
 * 
 * Ejecutar con: node backend/patterns/circuit-breaker/test-circuit-breaker.js
 */

const { 
  paymentCircuitBreaker, 
  getCircuitBreakerStatus 
} = require('./paymentCircuitBreaker');

console.log('🧪 Test del Circuit Breaker');
console.log('===========================\n');

// Función para mostrar el estado actual
function showStatus() {
  const status = getCircuitBreakerStatus();
  console.log(`\n📊 Estado actual: ${status.state}`);
  console.log(`   Peticiones totales: ${status.stats.fires}`);
  console.log(`   Éxitos: ${status.stats.successes}`);
  console.log(`   Fallos: ${status.stats.failures}`);
  console.log(`   Rechazos: ${status.stats.rejects}`);
  console.log(`   Timeouts: ${status.stats.timeouts}`);
  console.log(`   Fallbacks: ${status.stats.fallbacks}`);
  if (status.stats.latencyMean > 0) {
    console.log(`   Latencia promedio: ${status.stats.latencyMean.toFixed(2)}ms`);
  }
  console.log('');
}

// Función para enviar una petición de pago
async function sendPayment(id) {
  try {
    const result = await paymentCircuitBreaker.fire({
      reservation_id: id,
      amount: 100,
      payment_method: 'credit_card',
    });

    if (result.queued) {
      console.log(`⚠️  Pago #${id}: ENCOLADO (fallback) - ${result.status}`);
    } else {
      console.log(`✅ Pago #${id}: ${result.status} - TXN: ${result.transaction_id}`);
    }
  } catch (error) {
    console.log(`❌ Pago #${id}: ERROR - ${error.message}`);
  }
}

// Función para esperar un tiempo
function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Test principal
async function runTest() {
  console.log('Fase 1: Enviando peticiones iniciales (algunas fallarán aleatoriamente)');
  console.log('-----------------------------------------------------------------------\n');
  
  showStatus();

  // Enviar 20 peticiones
  for (let i = 1; i <= 20; i++) {
    await sendPayment(i);
    await wait(300); // Esperar 300ms entre peticiones
  }

  showStatus();

  console.log('\nFase 2: Verificar si el circuito se abrió');
  console.log('-----------------------------------------\n');

  const status = getCircuitBreakerStatus();
  
  if (status.state === 'OPEN') {
    console.log('✅ El circuito se ABRIÓ correctamente debido a los fallos.');
    console.log('   Las siguientes peticiones usarán el fallback.\n');
    
    // Enviar más peticiones que deberían usar fallback
    console.log('Enviando peticiones con circuito ABIERTO:');
    for (let i = 21; i <= 25; i++) {
      await sendPayment(i);
      await wait(200);
    }
    
    showStatus();
    
    console.log('\n⏱️  Normalmente, después de 60 segundos, el circuito');
    console.log('   pasaría a estado HALF_OPEN para probar si el servicio');
    console.log('   se recuperó.\n');
    
  } else if (status.state === 'CLOSED') {
    console.log('ℹ️  El circuito permaneció CERRADO.');
    console.log('   No hubo suficientes fallos para abrirlo.');
    console.log('   Esto puede ocurrir si las peticiones fueron exitosas.\n');
    
    const failureRate = (status.stats.failures / status.stats.fires) * 100;
    console.log(`   Tasa de fallos: ${failureRate.toFixed(2)}%`);
    console.log(`   Umbral configurado: 50%\n`);
    
    if (failureRate < 50) {
      console.log('   💡 Tip: El circuito solo se abre si >= 50% de las peticiones fallan');
      console.log('         en una ventana de 10 segundos.\n');
    }
  }

  console.log('Fase 3: Resumen final');
  console.log('--------------------\n');
  
  const finalStatus = getCircuitBreakerStatus();
  console.log('Estado final del Circuit Breaker:');
  console.log(`  Estado: ${finalStatus.state}`);
  console.log(`  Total de peticiones: ${finalStatus.stats.fires}`);
  console.log(`  Tasa de éxito: ${((finalStatus.stats.successes / finalStatus.stats.fires) * 100).toFixed(2)}%`);
  console.log(`  Tasa de fallo: ${((finalStatus.stats.failures / finalStatus.stats.fires) * 100).toFixed(2)}%`);
  
  if (finalStatus.stats.fallbacks > 0) {
    console.log(`  Fallbacks activados: ${finalStatus.stats.fallbacks}`);
  }
  
  console.log('\n✅ Test completado!\n');
  
  console.log('Conclusiones:');
  console.log('- El Circuit Breaker protege contra fallos en cascada');
  console.log('- Cuando se abre, las peticiones fallan rápido (fail-fast)');
  console.log('- El fallback permite encolar pagos para procesarlos después');
  console.log('- El circuito se auto-recupera después del timeout configurado\n');
  
  // Salir del proceso
  process.exit(0);
}

// Ejecutar el test
runTest().catch(error => {
  console.error('Error en el test:', error);
  process.exit(1);
});
