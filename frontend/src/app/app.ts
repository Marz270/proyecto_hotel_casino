import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpClientModule } from '@angular/common/http';

interface Room {
  id: number;
  room_number: number;
  room_type: string;
  price_per_night: number;
  max_guests: number;
  available: boolean;
}

interface Reservation {
  id?: number;
  client_name: string;
  room_number: number;
  check_in: string;
  check_out: string;
  total_price: number;
  created_at?: string;
}

interface Reports {
  summary?: {
    total_bookings: number;
    total_rooms: number;
    avg_booking_value: number;
    bookings_last_month: number;
  };
  occupancy?: {
    total_rooms: number;
    occupied_rooms: number;
    occupancy_rate: number;
  };
  revenue?: Array<{
    month: string;
    total_bookings: number;
    total_revenue: number;
  }>;
}

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CommonModule, FormsModule, HttpClientModule],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private http = inject(HttpClient);
  protected readonly title = signal('Hotel & Casino');

  // API Configuration
  private readonly API_BASE_URL = 'http://localhost:3000';

  // State
  activeTab = 'rooms';
  loading = false;
  error = '';
  apiStatus = 'connecting...';

  // Data
  rooms: Room[] = [];
  reservations: Reservation[] = [];
  reports: Reports = {};

  // Filters and Forms
  checkIn = '';
  checkOut = '';
  showReservationForm = false;
  newReservation: Reservation = {
    client_name: '',
    room_number: 0,
    check_in: '',
    check_out: '',
    total_price: 0,
  };

  ngOnInit() {
    this.checkApiStatus();
    this.setActiveTab('rooms');
  }

  async checkApiStatus() {
    try {
      const response = await this.http.get<any>(`${this.API_BASE_URL}/`).toPromise();
      this.apiStatus = `Connected (v${response.version})`;
    } catch (error) {
      this.apiStatus = 'Disconnected';
      this.error = 'Cannot connect to API. Make sure the backend is running.';
    }
  }

  setActiveTab(tab: string) {
    this.activeTab = tab;
    this.clearError();

    switch (tab) {
      case 'rooms':
        this.loadRooms();
        break;
      case 'reservations':
        this.loadReservations();
        break;
      case 'reports':
        this.loadReports();
        break;
    }
  }

  async loadRooms() {
    this.loading = true;
    try {
      const params =
        this.checkIn && this.checkOut ? `?check_in=${this.checkIn}&check_out=${this.checkOut}` : '';

      const response = await this.http.get<any>(`${this.API_BASE_URL}/rooms${params}`).toPromise();
      this.rooms = response.data || [];
    } catch (error) {
      this.handleError('Error loading rooms', error);
    } finally {
      this.loading = false;
    }
  }

  async loadReservations() {
    this.loading = true;
    try {
      const response = await this.http.get<any>(`${this.API_BASE_URL}/bookings`).toPromise();
      this.reservations = response.data || [];
    } catch (error) {
      this.handleError('Error loading reservations', error);
    } finally {
      this.loading = false;
    }
  }

  async loadReports() {
    this.loading = true;
    try {
      const response = await this.http.get<any>(`${this.API_BASE_URL}/reports`).toPromise();
      this.reports = response.data || {};
    } catch (error) {
      this.handleError('Error loading reports', error);
    } finally {
      this.loading = false;
    }
  }

  reserveRoom(room: Room) {
    this.newReservation = {
      client_name: '',
      room_number: room.room_number,
      check_in: this.checkIn || new Date().toISOString().split('T')[0],
      check_out: this.checkOut || new Date(Date.now() + 86400000).toISOString().split('T')[0],
      total_price: room.price_per_night,
    };
    this.showReservationForm = true;
    this.setActiveTab('reservations');
  }

  async createReservation() {
    this.loading = true;
    try {
      const response = await this.http
        .post<any>(`${this.API_BASE_URL}/reservations`, this.newReservation)
        .toPromise();

      if (response.success) {
        this.reservations.unshift(response.data);
        this.cancelReservation();
        this.showSuccess('Reservation created successfully!');
      } else {
        this.handleError('Error creating reservation', response.error);
      }
    } catch (error) {
      this.handleError('Error creating reservation', error);
    } finally {
      this.loading = false;
    }
  }

  cancelReservation() {
    this.showReservationForm = false;
    this.newReservation = {
      client_name: '',
      room_number: 0,
      check_in: '',
      check_out: '',
      total_price: 0,
    };
  }

  async deleteReservation(id: number) {
    if (!confirm('Are you sure you want to delete this reservation?')) {
      return;
    }

    this.loading = true;
    try {
      const response = await this.http
        .delete<any>(`${this.API_BASE_URL}/bookings/${id}`)
        .toPromise();

      if (response.success) {
        this.reservations = this.reservations.filter((r) => r.id !== id);
        this.showSuccess('Reservation deleted successfully!');
      } else {
        this.handleError('Error deleting reservation', response.error);
      }
    } catch (error) {
      this.handleError('Error deleting reservation', error);
    } finally {
      this.loading = false;
    }
  }

  private handleError(message: string, error: any) {
    console.error(message, error);
    this.error = `${message}: ${error?.error?.error || error?.message || 'Unknown error'}`;
  }

  private showSuccess(message: string) {
    // In a real app, we'd use a toast notification
    alert(message);
  }

  clearError() {
    this.error = '';
  }
}
