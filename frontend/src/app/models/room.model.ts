export interface RoomType {
  id: number;
  type_name: string;
  description: string;
  image_url: string;
  price_per_night: number;
  max_guests: number;
}

export interface Room {
  id: number;
  room_number: number;
  room_type: string;
  price_per_night: number;
  max_guests: number;
  available: boolean; // Calculado dinámicamente por la API
  image_url?: string; // URL de imagen del tipo de habitación
}

export interface RoomSearchParams {
  check_in?: string;
  check_out?: string;
}

// Respuesta de la API para /rooms
export interface RoomsApiResponse {
  success: boolean;
  data: Room[];
  filters: {
    check_in?: string;
    check_out?: string;
  };
  count: number;
}

// Respuesta de la API para /rooms/types
export interface RoomTypesApiResponse {
  success: boolean;
  data: RoomType[];
  count: number;
}
