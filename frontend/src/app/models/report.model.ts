export interface ReportSummary {
  total_bookings: number;
  total_rooms: number;
  avg_booking_value: number;
  bookings_last_month: number;
}

export interface OccupancyReport {
  total_rooms: number;
  occupied_rooms: number;
  occupancy_rate: number; // Porcentaje como número (ej: 75.50)
}

export interface RevenueReport {
  month: string; // Formato ISO date string del primer día del mes
  total_bookings: number;
  total_revenue: number;
}

export interface ReportsData {
  summary?: ReportSummary;
  occupancy?: OccupancyReport;
  revenue?: RevenueReport[];
}

// Respuesta de la API para /reports
export interface ReportsApiResponse {
  success: boolean;
  data: ReportsData;
  generated_at: string; // ISO date string
  report_type: string; // "all" | "summary" | "occupancy" | "revenue"
}
