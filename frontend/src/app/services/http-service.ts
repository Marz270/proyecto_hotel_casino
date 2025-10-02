import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, catchError, throwError } from 'rxjs';
import { BaseApiResponse } from '../models/api.model';

@Injectable({
  providedIn: 'root',
})
export class HttpService {
  private readonly http = inject(HttpClient);
  private readonly API_BASE_URL = 'http://localhost:3000';

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Accept: 'application/json',
    });
  }

  public get<T>(endpoint: string, params?: Record<string, any>): Observable<BaseApiResponse<T>> {
    let httpParams = new HttpParams();

    if (params) {
      Object.keys(params).forEach((key) => {
        const value = params[key];
        if (value !== null && value !== undefined && value !== '') {
          httpParams = httpParams.set(key, value.toString());
        }
      });
    }

    return this.http
      .get<BaseApiResponse<T>>(`${this.API_BASE_URL}${endpoint}`, {
        headers: this.getHeaders(),
        params: httpParams,
      })
      .pipe(catchError(this.handleError.bind(this)));
  }

  public post<T>(endpoint: string, body: any): Observable<BaseApiResponse<T>> {
    return this.http
      .post<BaseApiResponse<T>>(`${this.API_BASE_URL}${endpoint}`, body, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError.bind(this)));
  }

  public put<T>(endpoint: string, body: any): Observable<BaseApiResponse<T>> {
    return this.http
      .put<BaseApiResponse<T>>(`${this.API_BASE_URL}${endpoint}`, body, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError.bind(this)));
  }

  public delete<T>(endpoint: string): Observable<BaseApiResponse<T>> {
    return this.http
      .delete<BaseApiResponse<T>>(`${this.API_BASE_URL}${endpoint}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError.bind(this)));
  }

  private handleError(error: any): Observable<never> {
    let errorMessage = 'Error desconocido';

    if (error.error instanceof ErrorEvent) {
      // Error del lado del cliente
      errorMessage = `Error: ${error.error.message}`;
    } else {
      // Error del servidor - extraer mensaje de la respuesta de la API
      if (error.error?.error) {
        errorMessage = error.error.error;
      } else if (error.error?.message) {
        errorMessage = error.error.message;
      } else {
        errorMessage = `Error HTTP ${error.status}: ${error.statusText}`;
      }
    }

    console.error('HTTP Error:', error);
    return throwError(() => new Error(errorMessage));
  }

  // Método público para verificar el estado de la API
  checkApiStatus(): Observable<BaseApiResponse> {
    return this.get('/');
  }
}
