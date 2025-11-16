import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatTooltipModule } from '@angular/material/tooltip';
import { BookingsService } from '../../services/bookings-service';
import { NotificationService } from '../../services/notification.service';
import { Booking } from '../../models/booking.model';

@Component({
  selector: 'app-bookings-list',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatTableModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatCardModule,
    MatProgressSpinnerModule,
    MatTooltipModule,
  ],
  templateUrl: './bookings-list.html',
  styleUrls: ['./bookings-list.css'],
})
export class BookingsListComponent implements OnInit {
  private readonly bookingsService = inject(BookingsService);
  private readonly notificationService = inject(NotificationService);

  // Señales para gestión de estado
  bookings = signal<Booking[]>([]);
  filteredBookings = signal<Booking[]>([]);
  loading = signal<boolean>(false);

  // Controles de filtros
  searchControl = new FormControl('');
  yearControl = new FormControl('all');

  // Columnas de la tabla
  displayedColumns: string[] = [
    'id',
    'created_at',
    'client_name',
    'room_number',
    'check_in',
    'check_out',
    'total_price',
    'status',
    'actions',
  ];

  // Años disponibles para filtro
  availableYears = ['2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025'];

  ngOnInit(): void {
    this.loadBookings();
    this.setupFilters();
  }

  /**
   * Carga todas las reservas desde el backend
   */
  loadBookings(): void {
    this.loading.set(true);
    this.bookingsService.getAllBookings().subscribe({
      next: (bookings) => {
        this.bookings.set(bookings);
        this.filteredBookings.set(bookings);
        this.loading.set(false);
      },
      error: (error) => {
        this.notificationService.showError(
          'Error al cargar las reservas. Por favor, intente nuevamente.'
        );
        this.loading.set(false);
      },
    });
  }

  /**
   * Configura los listeners para los filtros
   */
  setupFilters(): void {
    this.searchControl.valueChanges.subscribe(() => this.applyFilters());
    this.yearControl.valueChanges.subscribe(() => this.applyFilters());
  }

  /**
   * Aplica todos los filtros activos
   */
  applyFilters(): void {
    let filtered = [...this.bookings()];

    // Filtro de búsqueda por nombre de cliente
    const searchTerm = this.searchControl.value?.toLowerCase() || '';
    if (searchTerm) {
      filtered = filtered.filter((booking) =>
        booking.client_name.toLowerCase().includes(searchTerm)
      );
    }

    // Filtro por año
    const selectedYear = this.yearControl.value;
    if (selectedYear && selectedYear !== 'all') {
      filtered = filtered.filter((booking) => booking.created_at.startsWith(selectedYear));
    }

    this.filteredBookings.set(filtered);
  }

  /**
   * Formatea fecha para mostrar
   */
  formatDate(dateString: string): string {
    return this.bookingsService.formatDate(dateString);
  }

  /**
   * Formatea precio para mostrar
   */
  formatPrice(price: any): string {
    const numPrice = typeof price === 'number' ? price : parseFloat(price) || 0;
    return numPrice.toFixed(2);
  }

  /**
   * Edita una reserva
   */
  editBooking(booking: Booking): void {
    this.notificationService.showInfo(`Editando reserva #${booking.id}`);
    // TODO: Implementar edición de reserva
  }

  /**
   * Elimina una reserva
   */
  deleteBooking(booking: Booking): void {
    if (confirm(`¿Está seguro de eliminar la reserva de ${booking.client_name}?`)) {
      this.loading.set(true);
      this.bookingsService.deleteBooking(booking.id).subscribe({
        next: () => {
          this.notificationService.showSuccess('Reserva eliminada correctamente');
          this.loadBookings();
        },
        error: (error) => {
          this.notificationService.showError('Error al eliminar la reserva');
          this.loading.set(false);
        },
      });
    }
  }

  /**
   * Determina el estado de pago basado en la fecha de check-out
   */
  getPaymentStatus(booking: Booking): 'paid' | 'pending' {
    const checkOutDate = new Date(booking.check_out);
    const today = new Date();
    return checkOutDate < today ? 'paid' : 'pending';
  }
}
