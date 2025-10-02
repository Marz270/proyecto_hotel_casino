import { Component, OnInit, inject, signal } from '@angular/core';
import { Router, RouterOutlet, NavigationEnd } from '@angular/router';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { filter, firstValueFrom } from 'rxjs';

import { HttpService } from './services/http-service';
import { AppStateService } from './services/app-state-service';
import { ApiInfo } from './models/api.model';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, CommonModule, HttpClientModule],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private readonly httpService = inject(HttpService);
  private readonly router = inject(Router);
  protected readonly appState = inject(AppStateService);

  protected readonly title = signal('Hotel & Casino');
  protected readonly currentRoute = signal('habitaciones');

  // Configuración de navegación
  protected readonly navItems = [
    {
      path: '/habitaciones',
      label: '🏠 Habitaciones',
      description: 'Consultar disponibilidad',
    },
    {
      path: '/reservas',
      label: '📅 Reservas',
      description: 'Gestionar reservas',
    },
    {
      path: '/reportes',
      label: '📊 Reportes',
      description: 'Estadísticas y análisis',
    },
  ];

  async ngOnInit() {
    await this.checkApiStatus();
    this.setupRouteTracking();
  }

  private setupRouteTracking() {
    // Rastrear cambios de ruta para actualizar navegación activa
    this.router.events
      .pipe(filter((event) => event instanceof NavigationEnd))
      .subscribe((event: NavigationEnd) => {
        const route = event.urlAfterRedirects.split('/')[1] || 'habitaciones';
        this.currentRoute.set(route);
      });
  }

  async checkApiStatus() {
    try {
      const response = await firstValueFrom(this.httpService.checkApiStatus());

      if (response.success && response.data) {
        const info = response.data as ApiInfo;
        this.appState.setApiStatus(`Connected v${info.version} (${info.booking_mode})`);
        this.appState.clearError();
      } else {
        throw new Error('API check failed');
      }
    } catch (error) {
      this.appState.setApiStatus('Disconnected');
      const errorMessage = error instanceof Error ? error.message : 'Cannot connect to API';
      this.appState.setError(`${errorMessage}. Make sure the backend is running.`);
      console.error('API Status Check Error:', error);
    }
  }

  // Navegación programática
  navigateTo(path: string) {
    this.router.navigate([path]);
    this.appState.clearError();
  }

  // Verificar si una ruta está activa
  isRouteActive(routePath: string): boolean {
    const route = routePath.replace('/', '');
    return this.currentRoute() === route;
  }

  // Método para refrescar el estado de la API
  async refreshApiStatus() {
    await this.checkApiStatus();
  }
}
