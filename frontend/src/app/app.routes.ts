import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/habitaciones',
    pathMatch: 'full',
  },
  {
    path: 'habitaciones',
    loadComponent: () => import('./components/rooms/rooms').then((m) => m.RoomsComponent),
    title: 'Habitaciones Disponibles - Hotel Casino',
  },
  {
    path: 'reservas',
    loadComponent: () =>
      import('./components/reservations/reservations').then((m) => m.ReservationsComponent),
    title: 'Gestión de Reservas - Hotel Casino',
  },
  {
    path: 'reportes',
    loadComponent: () => import('./components/reports/reports').then((m) => m.ReportsComponent),
    title: 'Reportes Administrativos - Hotel Casino',
  },
  {
    path: '**',
    redirectTo: '/habitaciones',
  },
];
