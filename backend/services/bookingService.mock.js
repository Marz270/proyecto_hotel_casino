class BookingServiceMock {
  constructor() {
    // Mock data para demostración
    this.bookings = [
      {
        id: 1,
        client_name: "Juan Pérez",
        room_number: 101,
        check_in: "2025-09-15",
        check_out: "2025-09-17",
        total_price: 350.0,
        created_at: new Date().toISOString(),
      },
      {
        id: 2,
        client_name: "María González",
        room_number: 205,
        check_in: "2025-09-20",
        check_out: "2025-09-22",
        total_price: 480.0,
        created_at: new Date().toISOString(),
      },
    ];
    this.nextId = 3;
  }

  async getAllBookings() {
    return {
      success: true,
      data: [...this.bookings],
      source: "Mock Service",
    };
  }

  async createBooking(bookingData) {
    const newBooking = {
      id: this.nextId++,
      ...bookingData,
      created_at: new Date().toISOString(),
    };

    this.bookings.push(newBooking);

    return {
      success: true,
      data: newBooking,
      source: "Mock Service",
    };
  }

  async getBookingById(id) {
    const booking = this.bookings.find((b) => b.id == id);

    if (!booking) {
      return {
        success: false,
        error: "Booking not found",
        source: "Mock Service",
      };
    }

    return {
      success: true,
      data: booking,
      source: "Mock Service",
    };
  }

  async deleteBooking(id) {
    const bookingIndex = this.bookings.findIndex((b) => b.id == id);

    if (bookingIndex === -1) {
      return {
        success: false,
        error: "Booking not found",
        source: "Mock Service",
      };
    }

    const deletedBooking = this.bookings.splice(bookingIndex, 1)[0];

    return {
      success: true,
      data: deletedBooking,
      source: "Mock Service",
    };
  }
}

module.exports = BookingServiceMock;
