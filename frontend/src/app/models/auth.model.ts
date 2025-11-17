export interface User {
  id: number;
  username: string;
  email: string;
  role: 'admin' | 'user';
  created_at?: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  token: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  role?: 'admin' | 'user';
}

export interface RegisterResponse {
  success: boolean;
  token: string;
}

export interface UserInfoResponse {
  success: boolean;
  user: User;
}

export interface VerifyTokenResponse {
  success: boolean;
  user: User;
}
