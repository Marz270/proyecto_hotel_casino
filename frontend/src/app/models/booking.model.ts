export interface Booking {
  id: number;
  client_name: string;
  room_number: number;
  check_in: string; // Formato: "YYYY-MM-DD"
  check_out: string; // Formato: "YYYY-MM-DD"
  total_price: number;
  created_at: string; // Formato ISO string
}

export interface CreateBookingRequest {
  client_name: string;
  room_number: number;
  check_in: string;
  check_out: string;
  total_price: number;
}

// Respuesta de la API para /bookings
export interface BookingsApiResponse {
  success: boolean;
  data: Booking[];
  source: 'PostgreSQL' | 'Mock Service';
  count: number;
}

// Respuesta para crear booking
export interface CreateBookingResponse {
  success: boolean;
  data: Booking;
  source: 'PostgreSQL' | 'Mock Service';
  message: string;
}
