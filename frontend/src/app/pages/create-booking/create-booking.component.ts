import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatSelectModule } from '@angular/material/select';
import { BookingsService } from '../../services/bookings-service';
import { NotificationService } from '../../services/notification.service';
import { RoomsService } from '../../services/rooms-service';
import { Room } from '../../models/room.model';

@Component({
  selector: 'app-create-booking',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatSelectModule,
  ],
  templateUrl: './create-booking.component.html',
  styleUrl: './create-booking.component.css',
})
export class CreateBookingComponent implements OnInit {
  private fb = inject(FormBuilder);
  private bookingsService = inject(BookingsService);
  private notificationService = inject(NotificationService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private roomsService = inject(RoomsService);

  bookingForm!: FormGroup;
  isSubmitting = false;
  minDate = new Date();
  minCheckOutDate: Date | null = null;
  selectedRoomType: string | null = null;

  rooms: Room[] = [];
  filteredRooms: Room[] = [];

  ngOnInit(): void {
    // Obtener roomType del queryParam si existe
    this.route.queryParams.subscribe((params) => {
      this.selectedRoomType = params['roomType'] || null;
      this.loadRooms();
    });

    this.bookingForm = this.fb.group({
      client_name: ['', [Validators.required, Validators.minLength(2)]],
      room_number: ['', Validators.required],
      check_in: ['', Validators.required],
      check_out: ['', Validators.required],
    });

    // Escuchar cambios en check_in para actualizar la fecha mínima de check_out
    this.bookingForm.get('check_in')?.valueChanges.subscribe((checkInDate) => {
      if (checkInDate) {
        const nextDay = new Date(checkInDate);
        nextDay.setDate(nextDay.getDate() + 1);
        this.minCheckOutDate = nextDay;

        // Si ya hay una fecha de check_out seleccionada y es anterior a la nueva mínima, limpiarla
        const currentCheckOut = this.bookingForm.get('check_out')?.value;
        if (currentCheckOut && new Date(currentCheckOut) < nextDay) {
          this.bookingForm.get('check_out')?.setValue(null);
        }
      } else {
        this.minCheckOutDate = null;
      }
    });
  }

  loadRooms(): void {
    this.roomsService.getRooms().subscribe({
      next: (rooms) => {
        this.rooms = rooms;
        this.filterRoomsByType();
      },
      error: (error) => {
        console.error('Error al cargar habitaciones:', error);
        this.notificationService.showError('Error al cargar habitaciones');
      },
    });
  }

  filterRoomsByType(): void {
    if (this.selectedRoomType) {
      this.filteredRooms = this.rooms.filter(
        (room) => room.room_type.toLowerCase() === this.selectedRoomType!.toLowerCase()
      );
    } else {
      this.filteredRooms = this.rooms;
    }
  }

  onRoomChange(roomNumber: number): void {
    const room = this.filteredRooms.find((r) => r.room_number === roomNumber);
    if (room) {
      this.calculateTotal();
    }
  }

  onDateChange(): void {
    this.calculateTotal();
  }

  calculateTotal(): number {
    const checkIn = this.bookingForm.get('check_in')?.value;
    const checkOut = this.bookingForm.get('check_out')?.value;
    const roomNumber = this.bookingForm.get('room_number')?.value;

    if (!checkIn || !checkOut || !roomNumber) return 0;

    const room = this.filteredRooms.find((r) => r.room_number === roomNumber);
    if (!room) return 0;

    const nights = Math.ceil(
      (new Date(checkOut).getTime() - new Date(checkIn).getTime()) / (1000 * 60 * 60 * 24)
    );
    return nights > 0 ? nights * room.price_per_night : 0;
  }

  onSubmit(): void {
    if (this.bookingForm.invalid) {
      this.bookingForm.markAllAsTouched();
      this.notificationService.showError('Por favor completa todos los campos requeridos');
      return;
    }

    // Obtener las fechas del formulario directamente como Date
    const checkIn = this.bookingForm.get('check_in')?.value;
    const checkOut = this.bookingForm.get('check_out')?.value;
    const roomNumber = this.bookingForm.get('room_number')?.value;

    if (checkOut <= checkIn) {
      this.notificationService.showError(
        'La fecha de salida debe ser posterior a la fecha de entrada'
      );
      return;
    }

    this.isSubmitting = true;

    // Verificar disponibilidad de la habitación
    this.bookingsService.checkRoomAvailability(roomNumber, checkIn, checkOut).subscribe({
      next: (isAvailable) => {
        if (!isAvailable) {
          this.isSubmitting = false;
          this.notificationService.showError(
            'La habitación seleccionada no está disponible en las fechas indicadas'
          );
          return;
        }

        // Si está disponible, proceder a crear la reserva
        const bookingData = {
          client_name: this.bookingForm.get('client_name')?.value,
          room_number: roomNumber,
          check_in: this.formatDateForBackend(checkIn),
          check_out: this.formatDateForBackend(checkOut),
          total_price: this.calculateTotal(),
        };

        this.bookingsService.createBooking(bookingData).subscribe({
          next: (response) => {
            this.isSubmitting = false;
            // Redirigir a la página de confirmación con los detalles de la reserva
            this.router.navigate(['/bookings/confirmation'], {
              state: { booking: bookingData },
              queryParams: {
                clientName: bookingData.client_name,
                roomNumber: bookingData.room_number,
                checkIn: bookingData.check_in,
                checkOut: bookingData.check_out,
                totalPrice: bookingData.total_price,
              },
            });
          },
          error: (error) => {
            this.isSubmitting = false;
            this.notificationService.showError(error.message || 'Error al crear la reserva');
          },
        });
      },
      error: (error) => {
        this.isSubmitting = false;
        this.notificationService.showError('Error al verificar disponibilidad de la habitación');
      },
    });
  }

  onCancel(): void {
    this.router.navigate(['/']);
  }

  /**
   * Formatea una fecha al formato YYYY-MM-DD
   * Ajusta por el offset de zona horaria para evitar cambios de día
   */
  private formatDateForBackend(date: Date): string {
    // Ajustar por el offset de zona horaria para obtener la fecha local correcta
    const localDate = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
    const year = localDate.getUTCFullYear();
    const month = String(localDate.getUTCMonth() + 1).padStart(2, '0');
    const day = String(localDate.getUTCDate()).padStart(2, '0');

    const formatted = `${year}-${month}-${day}`;
    console.log('Fecha del datepicker:', date);
    console.log('Offset aplicado (minutos):', date.getTimezoneOffset());
    console.log('Fecha ajustada:', localDate);
    console.log('Fecha formateada:', formatted);

    return formatted;
  }

  getErrorMessage(fieldName: string): string {
    const field = this.bookingForm.get(fieldName);
    if (!field) return '';

    if (field.hasError('required')) return 'Este campo es requerido';
    if (field.hasError('email')) return 'Email inválido';
    if (field.hasError('minlength'))
      return `Mínimo ${field.errors?.['minlength'].requiredLength} caracteres`;
    if (field.hasError('pattern')) return 'Formato inválido';
    if (field.hasError('min')) return `Mínimo ${field.errors?.['min'].min}`;
    if (field.hasError('max')) return `Máximo ${field.errors?.['max'].max}`;

    return '';
  }
}
