import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { HttpService } from './http-service';
import { ReportsData, ReportSummary, OccupancyReport, RevenueReport } from '../models/report.model';

@Injectable({
  providedIn: 'root',
})
export class ReportsService {
  private readonly httpService = inject(HttpService);

  /**
   * Obtiene todos los reportes
   */
  getAllReports(): Observable<ReportsData> {
    return this.httpService.get<ReportsData>('/reports').pipe(
      map((response) => {
        if (response.success && response.data) {
          return response.data;
        }
        throw new Error(response.error || 'Error al obtener reportes');
      })
    );
  }

  /**
   * Obtiene solo el reporte de resumen
   */
  getSummaryReport(): Observable<ReportSummary> {
    return this.httpService.get<ReportsData>('/reports', { type: 'summary' }).pipe(
      map((response) => {
        if (response.success && response.data?.summary) {
          return response.data.summary;
        }
        throw new Error('Error al obtener reporte de resumen');
      })
    );
  }

  /**
   * Obtiene solo el reporte de ocupación
   */
  getOccupancyReport(): Observable<OccupancyReport> {
    return this.httpService.get<ReportsData>('/reports', { type: 'occupancy' }).pipe(
      map((response) => {
        if (response.success && response.data?.occupancy) {
          return response.data.occupancy;
        }
        throw new Error('Error al obtener reporte de ocupación');
      })
    );
  }

  /**
   * Obtiene solo el reporte de ingresos
   */
  getRevenueReport(): Observable<RevenueReport[]> {
    return this.httpService.get<ReportsData>('/reports', { type: 'revenue' }).pipe(
      map((response) => {
        if (response.success && response.data?.revenue) {
          return response.data.revenue;
        }
        throw new Error('Error al obtener reporte de ingresos');
      })
    );
  }

  /**
   * Calcula estadísticas adicionales del reporte de ocupación
   */
  calculateOccupancyStats(occupancy: OccupancyReport) {
    const occupancyRate = Math.round(occupancy.occupancy_rate * 100) / 100;

    return {
      availableRooms: occupancy.total_rooms - occupancy.occupied_rooms,
      occupancyPercentage: occupancyRate,
      isHighOccupancy: occupancyRate > 80,
      isMediumOccupancy: occupancyRate > 50 && occupancyRate <= 80,
      isLowOccupancy: occupancyRate <= 50,
      statusText: occupancyRate > 80 ? 'Alta' : occupancyRate > 50 ? 'Media' : 'Baja',
      statusColor: occupancyRate > 80 ? 'success' : occupancyRate > 50 ? 'warning' : 'danger',
    };
  }

  /**
   * Calcula totales del reporte de ingresos
   */
  calculateRevenueTotals(revenue: RevenueReport[]) {
    if (!revenue || revenue.length === 0) {
      return {
        totalRevenue: 0,
        totalBookings: 0,
        averageRevenuePerMonth: 0,
        averageRevenuePerBooking: 0,
        months: 0,
      };
    }

    const totalRevenue = revenue.reduce((sum, item) => sum + (item.total_revenue || 0), 0);
    const totalBookings = revenue.reduce((sum, item) => sum + (item.total_bookings || 0), 0);
    const averageRevenuePerMonth = totalRevenue / revenue.length;
    const averageRevenuePerBooking = totalBookings > 0 ? totalRevenue / totalBookings : 0;

    return {
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      totalBookings,
      averageRevenuePerMonth: Math.round(averageRevenuePerMonth * 100) / 100,
      averageRevenuePerBooking: Math.round(averageRevenuePerBooking * 100) / 100,
      months: revenue.length,
    };
  }

  /**
   * Formatea fecha para visualización en reportes
   */
  formatReportDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', {
      year: 'numeric',
      month: 'long',
    });
  }

  /**
   * Formatea números como moneda
   */
  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('es-ES', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(amount);
  }
}
