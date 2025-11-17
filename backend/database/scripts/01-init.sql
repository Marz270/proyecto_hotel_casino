-- Inicialización de base de datos para Hotel & Casino
-- Este script se ejecuta automáticamente al iniciar el contenedor PostgreSQL

\echo 'Creando base de datos para Salto Hotel & Casino...'

-- Crear tabla de reservas
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    client_name VARCHAR(255) NOT NULL,
    room_number INTEGER NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de tipos de habitaciones (normalización)
CREATE TABLE IF NOT EXISTS room_types (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL,
    max_guests INTEGER DEFAULT 2
);

-- Crear tabla de habitaciones (para futuros endpoints)
CREATE TABLE IF NOT EXISTS rooms (
    id SERIAL PRIMARY KEY,
    room_number INTEGER UNIQUE NOT NULL,
    room_type_id INTEGER NOT NULL REFERENCES room_types(id),
    is_available BOOLEAN DEFAULT TRUE
);

-- Crear tabla de clientes (para futuros endpoints)
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar tipos de habitaciones
INSERT INTO room_types (type_name, description, image_url, price_per_night, max_guests) VALUES
('Standard', 
 'Habitación ideal para viajeros que buscan alojarse en un hotel 4 estrellas en el punto más céntrico de la ciudad, cerca de todo lo que necesitan para una estadía productiva.',
 'https://saltohotelcasino.uy/wp-content/uploads/2022/09/saltohotelcasino_standard_001-1024x682.jpg',
 150.00, 2),
('Classic',
 'Habitación cómoda e iluminada con vista a la ciudad. Ideal para descansar luego de una jornada de turismo o trabajo en Salto.',
 'https://saltohotelcasino.uy/wp-content/uploads/2022/08/saltohotelcasino_classic_simple_005-1024x682.jpg',
 180.00, 2),
('Suite',
 'La habitación más amplia y elegante del complejo, con jacuzzi y todas las comodidades necesarias para vivir una experiencia única. En ella podrás tener el privilegio de estar en uno de los puntos más altos de Salto observando toda la ciudad y disfrutando de unos atardeceres imperdibles.',
 'https://saltohotelcasino.uy/wp-content/uploads/2022/09/saltohotelcasino_suite_001-1024x682.jpg',
 250.00, 3),
('Superior',
 'Habitación de alta categoría, espaciosa y sumamente confortable. Posee balcón para apreciar el centro y la plaza principal de la ciudad.',
 'https://saltohotelcasino.uy/wp-content/uploads/2022/09/saltohotelcasino_superior_001-1024x682.jpg',
 400.00, 4)
ON CONFLICT (type_name) DO NOTHING;

-- Insertar datos de ejemplo para habitaciones
INSERT INTO rooms (room_number, room_type_id) VALUES
(101, (SELECT id FROM room_types WHERE type_name = 'Standard')),
(102, (SELECT id FROM room_types WHERE type_name = 'Standard')),
(201, (SELECT id FROM room_types WHERE type_name = 'Classic')),
(202, (SELECT id FROM room_types WHERE type_name = 'Classic')),
(301, (SELECT id FROM room_types WHERE type_name = 'Suite')),
(302, (SELECT id FROM room_types WHERE type_name = 'Suite')),
(401, (SELECT id FROM room_types WHERE type_name = 'Superior')),
(402, (SELECT id FROM room_types WHERE type_name = 'Superior'))
ON CONFLICT (room_number) DO NOTHING;

-- Insertar datos de ejemplo para clientes
INSERT INTO clients (name, email, phone) VALUES
('Juan Pérez', 'juan.perez@email.com', '+595981123456'),
('María González', 'maria.gonzalez@email.com', '+595981234567'),
('Carlos Rodríguez', 'carlos.rodriguez@email.com', '+595981345678')
ON CONFLICT (email) DO NOTHING;

-- Insertar usuario admin de ejemplo (password: admin123)
-- Hash generado con bcrypt rounds=10
INSERT INTO users (username, email, password_hash, role) VALUES
('admin', 'admin@saltohotelcasino.com', '$2b$10$x8yN33KBhE5bSXv/0RGAoe.WfU2kR7F4DuPH111cg0e.HW7uyUEXy', 'admin'),
('usuario', 'user@saltohotelcasino.com', '$2b$10$DGG4Q7E0.M9JDgDXBv2NceGI5jROkgOQNe.1kDkgw.TLOx1QpLfOC', 'user')
ON CONFLICT (username) DO NOTHING;

-- Insertar datos de ejemplo para reservas
INSERT INTO bookings (client_name, room_number, check_in, check_out, total_price) VALUES
('Juan Pérez', 101, '2025-09-15', '2025-09-17', 300.00),
('María González', 201, '2025-09-20', '2025-09-23', 540.00),
('Carlos Rodríguez', 301, '2025-10-01', '2025-10-03', 500.00)
ON CONFLICT DO NOTHING;