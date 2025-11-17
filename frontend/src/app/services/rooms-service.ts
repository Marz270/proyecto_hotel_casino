import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { HttpService } from './http-service';
import { Room, RoomSearchParams, RoomType } from '../models/room.model';

@Injectable({
  providedIn: 'root',
})
export class RoomsService {
  private readonly httpService = inject(HttpService);

  /**
   * Obtiene los tipos de habitaciones desde la API
   * Retorna la información completa incluyendo image_url desde room_types
   */
  getRoomTypes(): Observable<RoomType[]> {
    return this.httpService.get<RoomType[]>('/rooms/types').pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Error al obtener tipos de habitaciones');
      })
    );
  }

  /**
   * Obtiene todas las habitaciones con disponibilidad calculada
   * @param params Parámetros de filtrado (fechas)
   */
  getRooms(params?: RoomSearchParams): Observable<Room[]> {
    return this.httpService.get<Room[]>('/rooms', params).pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Error al obtener habitaciones');
      })
    );
  }

  /**
   * Obtiene una habitación específica por número
   * @param roomNumber Número de habitación
   */
  getRoomByNumber(roomNumber: number, params?: RoomSearchParams): Observable<Room> {
    return this.getRooms(params).pipe(
      map((rooms) => {
        const room = rooms.find((r) => r.room_number === roomNumber);
        if (!room) {
          throw new Error(`Habitación ${roomNumber} no encontrada`);
        }
        return room;
      })
    );
  }

  /**
   * Filtra habitaciones disponibles para las fechas especificadas
   */
  getAvailableRooms(params?: RoomSearchParams): Observable<Room[]> {
    return this.getRooms(params).pipe(map((rooms) => rooms.filter((room) => room.available)));
  }

  /**
   * Filtra habitaciones por tipo
   */
  getRoomsByType(roomType: string, params?: RoomSearchParams): Observable<Room[]> {
    return this.getRooms(params).pipe(
      map((rooms) =>
        rooms.filter((room) => room.room_type.toLowerCase().includes(roomType.toLowerCase()))
      )
    );
  }

  /**
   * Calcula el precio total para una estadía
   */
  calculateTotalPrice(room: Room, checkIn: string, checkOut: string): number {
    if (!checkIn || !checkOut) {
      return room.price_per_night;
    }

    const startDate = new Date(checkIn);
    const endDate = new Date(checkOut);

    if (startDate >= endDate) {
      return 0;
    }

    const timeDiff = endDate.getTime() - startDate.getTime();
    const nights = Math.ceil(timeDiff / (1000 * 60 * 60 * 24));

    return Math.max(0, nights * room.price_per_night);
  }

  /**
   * Calcula el número de noches entre dos fechas
   */
  calculateNights(checkIn: string, checkOut: string): number {
    if (!checkIn || !checkOut) {
      return 1;
    }

    const startDate = new Date(checkIn);
    const endDate = new Date(checkOut);

    if (startDate >= endDate) {
      return 0;
    }

    const timeDiff = endDate.getTime() - startDate.getTime();
    return Math.ceil(timeDiff / (1000 * 60 * 60 * 24));
  }
}
