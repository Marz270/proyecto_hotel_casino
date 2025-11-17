import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home';
import { LoginComponent } from './pages/login/login';
import { BookingsListComponent } from './pages/bookings-list/bookings-list';
import { CreateBookingComponent } from './pages/create-booking/create-booking.component';
import { RoomsShowcaseComponent } from './pages/rooms-showcase/rooms-showcase.component';
import { BookingConfirmationComponent } from './pages/booking-confirmation/booking-confirmation.component';
import { adminGuard } from './guards/auth.guard';

export const routes: Routes = [
  {
    path: '',
    component: HomeComponent,
  },
  {
    path: 'login',
    component: LoginComponent,
  },
  {
    path: 'rooms',
    component: RoomsShowcaseComponent,
  },
  {
    path: 'bookings/create',
    component: CreateBookingComponent,
  },
  {
    path: 'bookings/confirmation',
    component: BookingConfirmationComponent,
  },
  {
    path: 'bookings',
    component: BookingsListComponent,
    canActivate: [adminGuard],
  },
  {
    path: '**',
    redirectTo: '',
  },
];
