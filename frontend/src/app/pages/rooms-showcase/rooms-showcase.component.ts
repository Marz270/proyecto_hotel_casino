import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { RoomsService } from '../../services/rooms-service';
import { RoomType } from '../../models/room.model';

@Component({
  selector: 'app-rooms-showcase',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    RouterLink,
  ],
  templateUrl: './rooms-showcase.component.html',
  styleUrl: './rooms-showcase.component.css',
})
export class RoomsShowcaseComponent implements OnInit {
  private roomsService = inject(RoomsService);
  private route = inject(ActivatedRoute);

  roomTypesDisplay = signal<RoomType[]>([]);
  loading = signal<boolean>(true);
  selectedType = signal<string | null>(null);

  ngOnInit(): void {
    this.route.queryParams.subscribe((params) => {
      this.selectedType.set(params['type'] || null);
      this.loadRooms();
    });
  }

  loadRooms(): void {
    this.loading.set(true);
    this.roomsService.getRoomTypes().subscribe({
      next: (roomTypes) => {
        const filtered = this.filterRoomTypes(roomTypes);
        this.roomTypesDisplay.set(filtered);
        this.loading.set(false);
      },
      error: (error) => {
        console.error('Error al cargar habitaciones:', error);
        this.loading.set(false);
      },
    });
  }

  private filterRoomTypes(roomTypes: RoomType[]): RoomType[] {
    const selectedType = this.selectedType()?.toLowerCase();

    if (!selectedType) {
      return roomTypes;
    }

    return roomTypes.filter((rt) => rt.type_name.toLowerCase() === selectedType);
  }
}
