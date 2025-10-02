import { Component, OnInit, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { RoomsService } from '../../services/rooms-service';
import { AppStateService } from '../../services/app-state-service';
import { Room, RoomSearchParams } from '../../models/room.model';

@Component({
  selector: 'app-rooms',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './rooms.html',
  styleUrl: './rooms.css',
})
export class RoomsComponent implements OnInit {
  private readonly roomsService = inject(RoomsService);
  private readonly appState = inject(AppStateService);
  private readonly router = inject(Router);

  rooms = signal<Room[]>([]);
  isLoading = signal(false);
  checkIn = signal('');
  checkOut = signal('');

  async ngOnInit() {
    await this.loadRooms();
  }

  async loadRooms() {
    this.isLoading.set(true);

    try {
      const params: RoomSearchParams = {};

      if (this.checkIn() && this.checkOut()) {
        params.check_in = this.checkIn();
        params.check_out = this.checkOut();
      }

      const rooms = await firstValueFrom(this.roomsService.getRooms(params));
      this.rooms.set(rooms);
      this.appState.clearError();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Error al cargar habitaciones';
      this.appState.showError(errorMessage);
    } finally {
      this.isLoading.set(false);
    }
  }

  async searchRooms() {
    await this.loadRooms();
  }

  selectRoom(room: Room) {
    // Guardar habitación seleccionada en el estado global
    this.appState.setSelectedRoom(room);

    // Navegar a la página de reservas
    this.router.navigate(['/reservas']);

    // Mostrar mensaje de confirmación
    this.appState.showSuccess(
      `Habitación ${room.room_number} seleccionada. Redirigiendo a reservas...`
    );
  }

  calculateTotalPrice(room: Room): number {
    if (!this.checkIn() || !this.checkOut()) {
      return room.price_per_night;
    }

    return this.roomsService.calculateTotalPrice(room, this.checkIn(), this.checkOut());
  }

  calculateNights(): number {
    if (!this.checkIn() || !this.checkOut()) {
      return 1;
    }

    return this.roomsService.calculateNights(this.checkIn(), this.checkOut());
  }

  updateCheckIn(value: string) {
    this.checkIn.set(value);
  }

  updateCheckOut(value: string) {
    this.checkOut.set(value);
  }

  // Método para limpiar filtros
  clearFilters() {
    this.checkIn.set('');
    this.checkOut.set('');
    this.loadRooms();
  }
}
