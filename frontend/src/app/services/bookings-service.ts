import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { HttpService } from './http-service';
import { Booking, CreateBookingRequest } from '../models/booking.model';

@Injectable({
  providedIn: 'root',
})
export class BookingsService {
  private readonly httpService = inject(HttpService);

  /**
   * Obtiene todas las reservas
   */
  getAllBookings(): Observable<Booking[]> {
    return this.httpService.get<Booking[]>('/bookings').pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Error al obtener reservas');
      })
    );
  }

  /**
   * Obtiene una reserva específica por ID
   */
  getBookingById(id: number): Observable<Booking> {
    return this.httpService.get<Booking>(`/bookings/${id}`).pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Reserva no encontrada');
      })
    );
  }

  /**
   * Crea una nueva reserva usando el endpoint /bookings
   */
  createBooking(bookingData: CreateBookingRequest): Observable<Booking> {
    return this.httpService.post<Booking>('/bookings', bookingData).pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Error al crear reserva');
      })
    );
  }

  /**
   * Crea una reserva usando el endpoint alternativo /reservations
   */
  createReservation(bookingData: CreateBookingRequest): Observable<Booking> {
    return this.httpService.post<Booking>('/reservations', bookingData).pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Error al crear reserva');
      })
    );
  }

  /**
   * Elimina una reserva
   */
  deleteBooking(id: number): Observable<boolean> {
    return this.httpService.delete(`/bookings/${id}`).pipe(
      map((response) => {
        if (response.success) {
          return true;
        }
        throw new Error(response.error || 'Error al eliminar reserva');
      })
    );
  }

  /**
   * Verifica si una habitación está disponible en un rango de fechas
   */
  checkRoomAvailability(roomNumber: number, checkIn: Date, checkOut: Date): Observable<boolean> {
    return this.getAllBookings().pipe(
      map((bookings) => {
        // Filtrar reservas de la misma habitación
        const roomBookings = bookings.filter((b) => b.room_number === roomNumber);

        console.log(`Validando habitación ${roomNumber}:`, {
          checkIn: checkIn,
          checkOut: checkOut,
          reservasExistentes: roomBookings.length,
        });

        // Verificar si hay conflicto de fechas
        const hasConflict = roomBookings.some((booking) => {
          // Extraer fechas del backend sin conversión de zona horaria
          const bookingCheckInStr = this.extractDateFromISO(booking.check_in);
          const bookingCheckOutStr = this.extractDateFromISO(booking.check_out);

          // Convertir las fechas del formulario a strings YYYY-MM-DD
          const newCheckInStr = this.dateToYYYYMMDD(checkIn);
          const newCheckOutStr = this.dateToYYYYMMDD(checkOut);

          // Lógica de solapamiento en hotelería:
          // Una habitación está ocupada desde check-in (inclusive) hasta check-out (exclusive)
          // Es decir, el día de check-out la habitación se considera libre
          //
          // NO hay solapamiento si:
          // 1. La nueva reserva termina en o antes del día que empieza la existente (newCheckOut <= bookingCheckIn)
          //    Ej: Nueva 16-20, Existente 20-23 → OK (20 es check-out de una y check-in de otra)
          // 2. La nueva reserva empieza en o después del día que termina la existente (newCheckIn >= bookingCheckOut)
          //    Ej: Existente 16-20, Nueva 20-23 → OK (20 es check-out de una y check-in de otra)
          const noOverlap =
            newCheckOutStr <= bookingCheckInStr || newCheckInStr >= bookingCheckOutStr;

          console.log('Validando disponibilidad:', {
            reservaExistente: `${bookingCheckInStr} a ${bookingCheckOutStr}`,
            nuevaReserva: `${newCheckInStr} a ${newCheckOutStr}`,
            condicion1: `${newCheckOutStr} <= ${bookingCheckInStr} = ${
              newCheckOutStr <= bookingCheckInStr
            }`,
            condicion2: `${newCheckInStr} >= ${bookingCheckOutStr} = ${
              newCheckInStr >= bookingCheckOutStr
            }`,
            noOverlap,
            hayConflicto: !noOverlap,
          });

          return !noOverlap; // Si NO hay no-solapamiento, entonces HAY conflicto
        });

        console.log(`Resultado final: ${hasConflict ? 'NO DISPONIBLE' : 'DISPONIBLE'}`);
        return !hasConflict; // Retorna true si NO hay conflicto (está disponible)
      })
    );
  }

  /**
   * Extrae la parte de fecha de un string ISO sin conversión de zona horaria
   */
  private extractDateFromISO(dateString: string): string {
    if (dateString.includes('T')) {
      return dateString.split('T')[0]; // Retorna YYYY-MM-DD
    }
    return dateString;
  }

  /**
   * Convierte un objeto Date a string YYYY-MM-DD
   */
  private dateToYYYYMMDD(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * Valida datos de reserva antes de enviar
   */
  validateBookingData(bookingData: CreateBookingRequest): string[] {
    const errors: string[] = [];

    if (!bookingData.client_name?.trim()) {
      errors.push('El nombre del cliente es requerido');
    }

    if (bookingData.client_name?.trim().length < 2) {
      errors.push('El nombre del cliente debe tener al menos 2 caracteres');
    }

    if (!bookingData.room_number || bookingData.room_number < 1) {
      errors.push('Número de habitación inválido');
    }

    if (!bookingData.check_in) {
      errors.push('Fecha de check-in es requerida');
    }

    if (!bookingData.check_out) {
      errors.push('Fecha de check-out es requerida');
    }

    if (bookingData.check_in && bookingData.check_out) {
      const checkIn = new Date(bookingData.check_in);
      const checkOut = new Date(bookingData.check_out);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      if (checkIn >= checkOut) {
        errors.push('La fecha de check-out debe ser posterior al check-in');
      }

      if (checkIn < today) {
        errors.push('La fecha de check-in no puede ser en el pasado');
      }
    }

    if (!bookingData.total_price || bookingData.total_price <= 0) {
      errors.push('El precio total debe ser mayor a 0');
    }

    return errors;
  }

  /**
   * Formatea fecha para mostrar en la UI
   * Extrae la fecha UTC sin conversión de zona horaria
   */
  formatDate(dateString: string): string {
    // Si la fecha viene en formato ISO (YYYY-MM-DDTHH:mm:ss.sssZ),
    // extraemos solo la parte de la fecha
    if (dateString.includes('T')) {
      const [datePart] = dateString.split('T');
      const [year, month, day] = datePart.split('-');
      return `${day}/${month}/${year}`;
    }

    // Fallback para otros formatos
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  }

  /**
   * Formatea fecha y hora para mostrar en la UI
   */
  formatDateTime(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}
