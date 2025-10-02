import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { firstValueFrom } from 'rxjs';

import { ReportsService } from '../../services/reports-service';
import { AppStateService } from '../../services/app-state-service';
import {
  ReportsData,
  ReportSummary,
  OccupancyReport,
  RevenueReport,
} from '../../models/report.model';

@Component({
  selector: 'app-reports',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './reports.html',
  styleUrl: './reports.css',
})
export class ReportsComponent implements OnInit {
  private readonly reportsService = inject(ReportsService);
  private readonly appState = inject(AppStateService);

  reportData = signal<ReportsData>({});
  isLoading = signal(false);
  lastUpdated = signal('');

  async ngOnInit() {
    await this.loadReports();
  }

  async loadReports() {
    this.isLoading.set(true);

    try {
      const data = await firstValueFrom(this.reportsService.getAllReports());
      this.reportData.set(data);
      this.lastUpdated.set(new Date().toLocaleString('es-ES'));
      this.appState.clearError();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Error al cargar reportes';
      this.appState.showError(errorMessage);
    } finally {
      this.isLoading.set(false);
    }
  }

  async refreshReports() {
    await this.loadReports();
    this.appState.showSuccess('Reportes actualizados correctamente');
  }

  // Métodos de cálculo usando el servicio
  calculateOccupancyStats(occupancy: OccupancyReport) {
    return this.reportsService.calculateOccupancyStats(occupancy);
  }

  calculateRevenueTotals(revenue: RevenueReport[]) {
    return this.reportsService.calculateRevenueTotals(revenue);
  }

  formatCurrency(amount: number): string {
    return this.reportsService.formatCurrency(amount);
  }

  formatReportDate(dateString: string): string {
    return this.reportsService.formatReportDate(dateString);
  }
}
