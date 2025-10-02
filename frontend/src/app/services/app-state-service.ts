import { Injectable, signal, inject } from '@angular/core';
import { Room } from '../models/room.model';
import { NotificationService } from './notification.service';

@Injectable({
  providedIn: 'root',
})
export class AppStateService {
  private readonly notificationService = inject(NotificationService);

  // Estado compartido entre componentes
  private readonly _selectedRoom = signal<Room | null>(null);
  private readonly _apiStatus = signal('connecting...');
  private readonly _error = signal('');

  // Getters públicos de solo lectura
  readonly selectedRoom = this._selectedRoom.asReadonly();
  readonly apiStatus = this._apiStatus.asReadonly();
  readonly error = this._error.asReadonly();

  // Métodos para actualizar el estado
  setSelectedRoom(room: Room | null) {
    this._selectedRoom.set(room);
  }

  setApiStatus(status: string) {
    this._apiStatus.set(status);
  }

  setError(error: string) {
    this._error.set(error);
    if (error) {
      this.notificationService.showError(error);
    }
  }

  clearError() {
    this._error.set('');
  }

  // Método para notificaciones de éxito
  showSuccess(message: string) {
    this.notificationService.showSuccess(message);
    this.clearError();
  }

  showError(message: string) {
    this.setError(message);
  }

  showInfo(message: string) {
    this.notificationService.showInfo(message);
  }
}
