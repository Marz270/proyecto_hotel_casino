export interface PaymentRequest {
  reservation_id: number;
  amount: number;
  payment_method: 'credit_card' | 'debit_card' | 'cash' | 'transfer';
}

export interface PaymentResponse {
  id: number;
  reservation_id: number;
  amount: number;
  payment_method: string;
  status: 'approved' | 'pending' | 'rejected';
  transaction_id: string;
  processed_at: string; // ISO date string
}

// Respuesta de la API para /payments
export interface PaymentApiResponse {
  success: boolean;
  data: PaymentResponse;
  message: string;
}
