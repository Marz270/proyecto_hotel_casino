import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { map, catchError, of } from 'rxjs';

/**
 * Guard que protege rutas requiriendo autenticación
 */
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  // Verificar si hay token
  const token = authService.getToken();
  if (!token) {
    router.navigate(['/login']);
    return false;
  }

  return true;
};

/**
 * Guard que protege rutas requiriendo rol de administrador
 */
export const adminGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  // Verificar si hay token
  const token = authService.getToken();
  if (!token) {
    router.navigate(['/login']);
    return false;
  }

  // Si ya tenemos el usuario cargado, verificar directamente
  const currentUser = authService.getCurrentUser();
  if (currentUser) {
    if (currentUser.role === 'admin') {
      return true;
    } else {
      router.navigate(['/']);
      return false;
    }
  }

  // Si no tenemos el usuario, obtenerlo de la API
  return authService.getUserInfo().pipe(
    map((response) => {
      if (response.success && response.user) {
        if (response.user.role === 'admin') {
          return true;
        } else {
          router.navigate(['/']);
          return false;
        }
      }
      router.navigate(['/login']);
      return false;
    }),
    catchError(() => {
      router.navigate(['/login']);
      return of(false);
    })
  );
};
