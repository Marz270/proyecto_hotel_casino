import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { RoomsService } from '../../services/rooms-service';
import { RoomType } from '../../models/room.model';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterLink, MatIconModule, MatButtonModule, MatCardModule],
  templateUrl: './home.html',
  styleUrls: ['./home.css'],
})
export class HomeComponent implements OnInit {
  private readonly roomsService = inject(RoomsService);
  private readonly cdr = inject(ChangeDetectorRef);

  rooms: RoomType[] = [];
  loading = true;

  async ngOnInit() {
    await this.loadRoomTypes();
  }

  async loadRoomTypes() {
    try {
      this.rooms = await firstValueFrom(this.roomsService.getRoomTypes());
    } catch (error) {
      console.error('Error loading room types:', error);
      // Fallback a datos estáticos si hay error
      this.rooms = [
        {
          id: 1,
          type_name: 'Standard',
          description:
            'Habitación ideal para viajeros que buscan alojarse en un hotel 4 estrellas en el punto más céntrico de la ciudad, cerca de todo lo que necesitan para una estadía productiva.',
          image_url:
            'https://saltohotelcasino.uy/wp-content/uploads/2022/09/saltohotelcasino_standard_001-1024x682.jpg',
          price_per_night: 150,
          max_guests: 2,
        },
        {
          id: 2,
          type_name: 'Classic',
          description:
            'Habitación cómoda e iluminada con vista a la ciudad. Ideal para descansar luego de una jornada de turismo o trabajo en Salto.',
          image_url:
            'https://saltohotelcasino.uy/wp-content/uploads/2022/08/saltohotelcasino_classic_simple_005-1024x682.jpg',
          price_per_night: 180,
          max_guests: 2,
        },
        {
          id: 3,
          type_name: 'Suite',
          description:
            'La habitación más amplia y elegante del complejo, con jacuzzi y todas las comodidades necesarias para vivir una experiencia única. En ella podrás tener el privilegio de estar en uno de los puntos más altos de Salto observando toda la ciudad y disfrutando de unos atardeceres imperdibles.',
          image_url:
            'https://saltohotelcasino.uy/wp-content/uploads/2022/09/saltohotelcasino_suite_001-1024x682.jpg',
          price_per_night: 250,
          max_guests: 3,
        },
        {
          id: 4,
          type_name: 'Superior',
          description:
            'Habitación de alta categoría, espaciosa y sumamente confortable. Posee balcón para apreciar el centro y la plaza principal de la ciudad.',
          image_url:
            'https://saltohotelcasino.uy/wp-content/uploads/2022/09/saltohotelcasino_superior_001-1024x682.jpg',
          price_per_night: 400,
          max_guests: 4,
        },
      ];
    } finally {
      this.loading = false;
      this.cdr.detectChanges();
    }
  }
}
