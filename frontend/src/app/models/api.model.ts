/**
 * Modelos para respuestas de la API
 * Estos tipos definen la estructura de las respuestas del backend
 */

export interface BaseApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  source?: 'PostgreSQL' | 'Mock Service';
  count?: number;
  details?: any;
}

// Información de la API root endpoint
export interface ApiInfo {
  message: string;
  version: string;
  booking_mode: 'pg' | 'mock';
  endpoints: Record<string, string>;
}
