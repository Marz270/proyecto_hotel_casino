import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { BookingsService } from '../../services/bookings-service';
import { AppStateService } from '../../services/app-state-service';
import { Room } from '../../models/room.model';
import { Booking, CreateBookingRequest } from '../../models/booking.model';

@Component({
  selector: 'app-reservations',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './reservations.html',
  styleUrl: './reservations.css',
})
export class ReservationsComponent implements OnInit {
  private readonly bookingsService = inject(BookingsService);
  private readonly appState = inject(AppStateService);
  private readonly router = inject(Router);

  reservations = signal<Booking[]>([]);
  isLoading = signal(false);
  showForm = signal(false);
  validationErrors = signal<string[]>([]);

  // Habitación seleccionada desde el estado global
  selectedRoom = computed(() => this.appState.selectedRoom());

  // Form data
  formData = signal<CreateBookingRequest>({
    client_name: '',
    room_number: 101,
    check_in: '',
    check_out: '',
    total_price: 0,
  });

  async ngOnInit() {
    await this.loadReservations();

    // Si hay una habitación seleccionada, abrir el formulario automáticamente
    if (this.selectedRoom()) {
      this.openFormWithSelectedRoom();
    }
  }

  async loadReservations() {
    this.isLoading.set(true);

    try {
      const bookings = await firstValueFrom(this.bookingsService.getAllBookings());
      this.reservations.set(bookings);
      this.appState.clearError();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Error al cargar reservas';
      this.appState.showError(errorMessage);
    } finally {
      this.isLoading.set(false);
    }
  }

  openFormWithSelectedRoom() {
    const room = this.selectedRoom();
    if (room) {
      this.showForm.set(true);
      this.updateFormData({
        ...this.formData(),
        room_number: room.room_number,
        total_price: room.price_per_night,
      });
    }
  }

  toggleForm() {
    this.showForm.update((show) => !show);
    if (this.showForm()) {
      this.resetForm();
    }
  }

  showNewReservationForm() {
    this.showForm.set(true);
  }

  resetForm() {
    const room = this.selectedRoom();
    this.updateFormData({
      client_name: '',
      room_number: room?.room_number || 101,
      check_in: '',
      check_out: '',
      total_price: room?.price_per_night || 0,
    });
    this.validationErrors.set([]);
  }

  async createReservation() {
    // Validar datos
    const errors = this.bookingsService.validateBookingData(this.formData());
    this.validationErrors.set(errors);

    if (errors.length > 0) {
      this.appState.showError('Por favor corrige los errores en el formulario');
      return;
    }

    try {
      const newBooking = await firstValueFrom(
        this.bookingsService.createReservation(this.formData())
      );

      this.appState.showSuccess('Reserva creada exitosamente');
      this.showForm.set(false);
      this.resetForm();

      // Limpiar habitación seleccionada después de crear la reserva
      this.appState.setSelectedRoom(null);

      await this.loadReservations();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Error al crear reserva';
      this.appState.showError(errorMessage);
    }
  }

  async deleteReservation(id: number) {
    if (!confirm('¿Estás seguro de que quieres eliminar esta reserva?')) {
      return;
    }

    try {
      await firstValueFrom(this.bookingsService.deleteBooking(id));
      this.appState.showSuccess('Reserva eliminada exitosamente');
      await this.loadReservations();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Error al eliminar reserva';
      this.appState.showError(errorMessage);
    }
  }

  updateFormData(updates: Partial<CreateBookingRequest>) {
    this.formData.update((current) => ({ ...current, ...updates }));
  }

  // Navegar a habitaciones para seleccionar una
  goToRooms() {
    this.router.navigate(['/habitaciones']);
  }

  // Formatear fechas para mostrar
  formatDate(dateString: string): string {
    return this.bookingsService.formatDate(dateString);
  }

  formatDateTime(dateString: string): string {
    return this.bookingsService.formatDateTime(dateString);
  }
}
