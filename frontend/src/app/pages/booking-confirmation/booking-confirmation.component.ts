import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, ActivatedRoute } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-booking-confirmation',
  standalone: true,
  imports: [CommonModule, MatButtonModule, MatIconModule, MatCardModule],
  templateUrl: './booking-confirmation.component.html',
  styleUrl: './booking-confirmation.component.css',
})
export class BookingConfirmationComponent implements OnInit {
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  bookingDetails: any = null;

  ngOnInit(): void {
    // Obtener detalles de la reserva desde el state de la navegación
    const navigation = this.router.getCurrentNavigation();
    if (navigation?.extras?.state) {
      this.bookingDetails = navigation.extras.state['booking'];
    }

    // También intentar obtener desde queryParams por si se recarga la página
    this.route.queryParams.subscribe((params) => {
      if (params['clientName']) {
        this.bookingDetails = {
          client_name: params['clientName'],
          room_number: params['roomNumber'],
          check_in: params['checkIn'],
          check_out: params['checkOut'],
          total_price: params['totalPrice'],
        };
      }
    });
  }

  goToHome(): void {
    this.router.navigate(['/']);
  }

  goToRooms(): void {
    this.router.navigate(['/rooms']);
  }
}
