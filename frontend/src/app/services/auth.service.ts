import { Injectable, inject, signal } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap, catchError, throwError, BehaviorSubject } from 'rxjs';
import {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  User,
  UserInfoResponse,
  VerifyTokenResponse,
} from '../models/auth.model';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly API_BASE_URL = 'http://localhost:3000';
  private readonly TOKEN_KEY = 'auth_token';

  // Estado reactivo del usuario
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  // Signal para estado de autenticación
  public isAuthenticated = signal<boolean>(false);

  constructor() {
    // Verificar si hay token al inicializar
    this.checkAuthentication();
  }

  /**
   * Verificar autenticación al cargar la aplicación
   */
  private async checkAuthentication(): Promise<void> {
    const token = this.getToken();
    if (token) {
      try {
        await this.verifyToken().toPromise();
      } catch (error) {
        this.logout();
      }
    }
  }

  /**
   * Login de usuario
   */
  login(username: string, password: string): Observable<LoginResponse> {
    return this.http
      .post<LoginResponse>(`${this.API_BASE_URL}/auth/login`, {
        username,
        password,
      })
      .pipe(
        tap((response) => {
          if (response.success && response.token) {
            this.setToken(response.token);
            this.isAuthenticated.set(true);
            this.loadUserInfo();
          }
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Registro de nuevo usuario
   */
  register(data: RegisterRequest): Observable<RegisterResponse> {
    return this.http.post<RegisterResponse>(`${this.API_BASE_URL}/auth/register`, data).pipe(
      tap((response) => {
        if (response.success && response.token) {
          this.setToken(response.token);
          this.isAuthenticated.set(true);
          this.loadUserInfo();
        }
      }),
      catchError(this.handleError)
    );
  }

  /**
   * Obtener información del usuario actual
   */
  getUserInfo(): Observable<UserInfoResponse> {
    return this.http
      .get<UserInfoResponse>(`${this.API_BASE_URL}/auth/me`, {
        headers: this.getAuthHeaders(),
      })
      .pipe(
        tap((response) => {
          if (response.success && response.user) {
            this.currentUserSubject.next(response.user);
          }
        }),
        catchError(this.handleError)
      );
  }

  /**
   * Verificar validez del token
   */
  verifyToken(): Observable<VerifyTokenResponse> {
    return this.http
      .post<VerifyTokenResponse>(
        `${this.API_BASE_URL}/auth/verify`,
        {},
        {
          headers: this.getAuthHeaders(),
        }
      )
      .pipe(
        tap((response) => {
          if (response.success && response.user) {
            this.currentUserSubject.next(response.user);
            this.isAuthenticated.set(true);
          }
        }),
        catchError((error) => {
          this.logout();
          return throwError(() => error);
        })
      );
  }

  /**
   * Cerrar sesión
   */
  logout(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    this.currentUserSubject.next(null);
    this.isAuthenticated.set(false);
    this.router.navigate(['/login']);
  }

  /**
   * Guardar token en localStorage
   */
  private setToken(token: string): void {
    localStorage.setItem(this.TOKEN_KEY, token);
  }

  /**
   * Obtener token desde localStorage
   */
  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  /**
   * Obtener headers con autenticación
   */
  private getAuthHeaders(): HttpHeaders {
    const token = this.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  /**
   * Cargar información del usuario
   */
  private loadUserInfo(): void {
    this.getUserInfo().subscribe({
      error: (error) => {
        console.error('Error loading user info:', error);
        this.logout();
      },
    });
  }

  /**
   * Obtener usuario actual (snapshot)
   */
  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  /**
   * Verificar si el usuario tiene un rol específico
   */
  hasRole(role: 'admin' | 'user'): boolean {
    const user = this.getCurrentUser();
    return user?.role === role;
  }

  /**
   * Manejo de errores
   */
  private handleError(error: any): Observable<never> {
    let errorMessage = 'Error desconocido';

    if (error.error instanceof ErrorEvent) {
      errorMessage = error.error.message;
    } else if (error.error?.error) {
      errorMessage = error.error.error;
    } else if (error.error?.message) {
      errorMessage = error.error.message;
    } else {
      errorMessage = `Error HTTP ${error.status}: ${error.statusText}`;
    }

    console.error('Auth Error:', error);
    return throwError(() => new Error(errorMessage));
  }
}
