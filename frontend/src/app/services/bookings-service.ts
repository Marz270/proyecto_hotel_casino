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
   */
  formatDate(dateString: string): string {
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
