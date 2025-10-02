import { Injectable, signal } from '@angular/core';
import { Room } from '../models/room.model';

@Injectable({
  providedIn: 'root',
})
export class AppStateService {
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
  }

  clearError() {
    this._error.set('');
  }

  // Método para notificaciones de éxito
  showSuccess(message: string) {
    console.log('Success:', message);
    // En una aplicación real, usaríamos un servicio de toasts
    alert(`✅ ${message}`);
    this.clearError();
  }

  showError(message: string) {
    this.setError(message);
    console.error('Application Error:', message);
  }
}
