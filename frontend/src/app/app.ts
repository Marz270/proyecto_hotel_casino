import { Component, OnInit, inject, signal } from '@angular/core';
import { Router, RouterOutlet, NavigationEnd } from '@angular/router';
import { CommonModule } from '@angular/common';
import { filter, firstValueFrom } from 'rxjs';
import { MatTabChangeEvent } from '@angular/material/tabs';

import { HttpService } from './services/http-service';
import { AppStateService } from './services/app-state-service';
import { ApiInfo } from './models/api.model';
import { MATERIAL_MODULES } from './material.config';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, CommonModule, ...MATERIAL_MODULES],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private readonly httpService = inject(HttpService);
  private readonly router = inject(Router);
  protected readonly appState = inject(AppStateService);

  protected readonly currentRoute = signal('habitaciones');

  private readonly routeMap = ['/habitaciones', '/reservas', '/reportes'];

  async ngOnInit() {
    await this.checkApiStatus();
    this.setupRouteTracking();
  }

  private setupRouteTracking() {
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
    }
  }

  getActiveTabIndex(): number {
    const currentPath = `/${this.currentRoute()}`;
    return Math.max(0, this.routeMap.indexOf(currentPath));
  }

  onTabChange(event: MatTabChangeEvent) {
    const route = this.routeMap[event.index];
    if (route) {
      this.router.navigate([route]);
      this.appState.clearError();
    }
  }

  async refreshApiStatus() {
    await this.checkApiStatus();
  }
}
