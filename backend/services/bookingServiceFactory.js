const BookingServicePG = require("./bookingService.pg");
const BookingServiceMock = require("./bookingService.mock");

/**
 * Factory para crear instancias del BookingService
 * Demuestra "Deferred Binding" - la implementación se selecciona en runtime
 * basada en variables de entorno
 */
class BookingServiceFactory {
  static createBookingService() {
    const mode = process.env.BOOKING_MODE || "pg";

    console.log(
      `🔗 Deferred Binding: Creating BookingService in mode: ${mode}`
    );

    switch (mode.toLowerCase()) {
      case "mock":
        return new BookingServiceMock();
      case "pg":
      case "postgresql":
        return new BookingServicePG();
      default:
        console.warn(
          `Unknown BOOKING_MODE: ${mode}. Defaulting to PostgreSQL.`
        );
        return new BookingServicePG();
    }
  }

  static getSupportedModes() {
    return ["pg", "postgresql", "mock"];
  }
}

module.exports = BookingServiceFactory;
