const pool = require("../database/db");

class BookingServicePG {
  async getAllBookings() {
    try {
      const result = await pool.query(
        "SELECT * FROM bookings ORDER BY created_at DESC"
      );
      return {
        success: true,
        data: result.rows,
        source: "PostgreSQL",
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        source: "PostgreSQL",
      };
    }
  }

  async createBooking(bookingData) {
    const { client_name, room_number, check_in, check_out, total_price } =
      bookingData;

    try {
      const result = await pool.query(
        "INSERT INTO bookings (client_name, room_number, check_in, check_out, total_price) VALUES ($1, $2, $3, $4, $5) RETURNING *",
        [client_name, room_number, check_in, check_out, total_price]
      );

      return {
        success: true,
        data: result.rows[0],
        source: "PostgreSQL",
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        source: "PostgreSQL",
      };
    }
  }

  async getBookingById(id) {
    try {
      const result = await pool.query("SELECT * FROM bookings WHERE id = $1", [
        id,
      ]);

      if (result.rows.length === 0) {
        return {
          success: false,
          error: "Booking not found",
          source: "PostgreSQL",
        };
      }

      return {
        success: true,
        data: result.rows[0],
        source: "PostgreSQL",
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        source: "PostgreSQL",
      };
    }
  }

  async deleteBooking(id) {
    try {
      const result = await pool.query(
        "DELETE FROM bookings WHERE id = $1 RETURNING *",
        [id]
      );

      if (result.rows.length === 0) {
        return {
          success: false,
          error: "Booking not found",
          source: "PostgreSQL",
        };
      }

      return {
        success: true,
        data: result.rows[0],
        source: "PostgreSQL",
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        source: "PostgreSQL",
      };
    }
  }
}

module.exports = BookingServicePG;
