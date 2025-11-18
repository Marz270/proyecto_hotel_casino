const soap = require("soap");
const fs = require("fs");
const path = require("path");
const pool = require("../database/db");

// Servicio SOAP simple: consulta de disponibilidad
const bookingService = {
  BookingService: {
    BookingServicePort: {
      GetAvailability: async function (args) {
        try {
          const { checkIn, checkOut } = args;

          const query = `
            SELECT 
              r.room_number as "roomNumber",
              rt.type_name as "roomType",
              rt.price_per_night as "pricePerNight"
            FROM rooms r
            JOIN room_types rt ON r.room_type_id = rt.id
            WHERE NOT EXISTS (
              SELECT 1 FROM bookings b 
              WHERE b.room_number = r.room_number
                AND (
                  (b.check_in <= $1::date AND b.check_out > $1::date) OR
                  (b.check_in < $2::date AND b.check_out >= $2::date) OR
                  (b.check_in >= $1::date AND b.check_out <= $2::date)
                )
            )
            ORDER BY r.room_number
          `;

          const result = await pool.query(query, [checkIn, checkOut]);

          return {
            availableRooms: {
              room: result.rows.map((room) => ({
                roomNumber: room.roomNumber,
                roomType: room.roomType,
                pricePerNight: parseFloat(room.pricePerNight),
              })),
            },
          };
        } catch (error) {
          throw {
            Fault: {
              Code: { Value: "soap:Server" },
              Reason: { Text: error.message },
            },
          };
        }
      },
    },
  },
};

function initSoapServer(app) {
  const wsdlPath = path.join(__dirname, "bookingService.wsdl");
  const xml = fs.readFileSync(wsdlPath, "utf8");

  soap.listen(app, "/soap/booking", bookingService, xml, function () {
    console.log(
      "[SOAP] Service available at http://localhost:3000/soap/booking?wsdl"
    );
  });
}

module.exports = { initSoapServer };
