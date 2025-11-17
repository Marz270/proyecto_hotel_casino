import { Component, OnInit, inject } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { firstValueFrom } from 'rxjs';

import { HttpService } from './services/http-service';
import { AppStateService } from './services/app-state-service';
import { AuthService } from './services/auth.service';
import { ApiInfo } from './models/api.model';
import { MATERIAL_MODULES } from './material.config';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule, ...MATERIAL_MODULES],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private readonly httpService = inject(HttpService);
  protected readonly appState = inject(AppStateService);
  protected readonly authService = inject(AuthService);

  async ngOnInit() {
    await this.checkApiStatus();
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

  async refreshApiStatus() {
    await this.checkApiStatus();
  }

  logout() {
    this.authService.logout();
  }
}
