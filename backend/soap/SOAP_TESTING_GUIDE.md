# Guía de Pruebas para el Servicio SOAP

## 📋 Descripción

El servicio SOAP implementado proporciona dos operaciones principales para la gestión de reservas del hotel:

1. **GetAvailability**: Consulta habitaciones disponibles
2. **CreateBooking**: Crea una nueva reserva

## 🔗 Endpoints

- **SOAP Endpoint**: `http://localhost:3000/soap/booking`
- **WSDL**: `http://localhost:3000/soap/booking?wsdl`

---

## 🧪 Pruebas con cURL

### 1. Consultar WSDL

```bash
curl http://localhost:3000/soap/booking?wsdl
```

### 2. GetAvailability - Consultar Disponibilidad

**Solicitud XML**:

```bash
curl -X POST http://localhost:3000/soap/booking \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: http://saltohotelcasino.uy/booking/GetAvailability" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://saltohotelcasino.uy/booking">
  <soap:Body>
    <tns:GetAvailabilityRequest>
      <tns:checkIn>2025-12-01</tns:checkIn>
      <tns:checkOut>2025-12-05</tns:checkOut>
    </tns:GetAvailabilityRequest>
  </soap:Body>
</soap:Envelope>'
```

**Con filtro por tipo de habitación**:

```bash
curl -X POST http://localhost:3000/soap/booking \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: http://saltohotelcasino.uy/booking/GetAvailability" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://saltohotelcasino.uy/booking">
  <soap:Body>
    <tns:GetAvailabilityRequest>
      <tns:checkIn>2025-12-01</tns:checkIn>
      <tns:checkOut>2025-12-05</tns:checkOut>
      <tns:roomType>Suite</tns:roomType>
    </tns:GetAvailabilityRequest>
  </soap:Body>
</soap:Envelope>'
```

### 3. CreateBooking - Crear Reserva

```bash
curl -X POST http://localhost:3000/soap/booking \
  -H "Content-Type: text/xml" \
  -H "SOAPAction: http://saltohotelcasino.uy/booking/CreateBooking" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://saltohotelcasino.uy/booking">
  <soap:Body>
    <tns:CreateBookingRequest>
      <tns:clientName>Juan Pérez</tns:clientName>
      <tns:roomNumber>101</tns:roomNumber>
      <tns:checkIn>2025-12-10</tns:checkIn>
      <tns:checkOut>2025-12-15</tns:checkOut>
    </tns:CreateBookingRequest>
  </soap:Body>
</soap:Envelope>'
```

---

## 📮 Pruebas con Postman

### Configuración General

1. **Método**: POST
2. **URL**: `http://localhost:3000/soap/booking`
3. **Headers**:
   - `Content-Type`: `text/xml`
   - `SOAPAction`: (depende de la operación)

### Request 1: GetAvailability

**Headers**:

- `Content-Type`: `text/xml`
- `SOAPAction`: `http://saltohotelcasino.uy/booking/GetAvailability`

**Body (raw XML)**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://saltohotelcasino.uy/booking">
  <soap:Body>
    <tns:GetAvailabilityRequest>
      <tns:checkIn>2025-12-01</tns:checkIn>
      <tns:checkOut>2025-12-05</tns:checkOut>
    </tns:GetAvailabilityRequest>
  </soap:Body>
</soap:Envelope>
```

**Respuesta esperada**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <tns:GetAvailabilityResponse xmlns:tns="http://saltohotelcasino.uy/booking">
      <tns:availableRooms>
        <tns:room>
          <tns:id>1</tns:id>
          <tns:roomNumber>101</tns:roomNumber>
          <tns:roomType>Standard</tns:roomType>
          <tns:pricePerNight>150.00</tns:pricePerNight>
          <tns:maxGuests>2</tns:maxGuests>
          <tns:available>true</tns:available>
        </tns:room>
        <!-- Más habitaciones... -->
      </tns:availableRooms>
    </tns:GetAvailabilityResponse>
  </soap:Body>
</soap:Envelope>
```

### Request 2: CreateBooking

**Headers**:

- `Content-Type`: `text/xml`
- `SOAPAction`: `http://saltohotelcasino.uy/booking/CreateBooking`

**Body (raw XML)**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://saltohotelcasino.uy/booking">
  <soap:Body>
    <tns:CreateBookingRequest>
      <tns:clientName>María García</tns:clientName>
      <tns:roomNumber>102</tns:roomNumber>
      <tns:checkIn>2025-12-20</tns:checkIn>
      <tns:checkOut>2025-12-25</tns:checkOut>
    </tns:CreateBookingRequest>
  </soap:Body>
</soap:Envelope>
```

**Respuesta esperada (éxito)**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <tns:CreateBookingResponse xmlns:tns="http://saltohotelcasino.uy/booking">
      <tns:success>true</tns:success>
      <tns:bookingId>123</tns:bookingId>
      <tns:message>Reserva creada exitosamente</tns:message>
      <tns:totalPrice>750.00</tns:totalPrice>
    </tns:CreateBookingResponse>
  </soap:Body>
</soap:Envelope>
```

---

## 🔍 Casos de Prueba

### Escenario 1: Consultar todas las habitaciones disponibles

- Fechas: 2025-12-01 a 2025-12-05
- Sin filtro de tipo
- Resultado esperado: Lista de todas las habitaciones disponibles

### Escenario 2: Consultar habitaciones tipo Suite

- Fechas: 2025-12-01 a 2025-12-05
- Tipo: Suite
- Resultado esperado: Solo habitaciones tipo Suite disponibles

### Escenario 3: Crear reserva exitosa

- Cliente: Juan Pérez
- Habitación: 101
- Fechas: 2025-12-10 a 2025-12-15
- Resultado esperado: success=true, bookingId asignado

### Escenario 4: Error - Habitación no disponible

- Cliente: Ana López
- Habitación: 101 (ya reservada en escenario 3)
- Fechas: 2025-12-12 a 2025-12-14 (se solapa)
- Resultado esperado: success=false, mensaje de error

### Escenario 5: Error - Habitación inexistente

- Cliente: Pedro Sánchez
- Habitación: 999
- Resultado esperado: success=false, "habitación no existe"

---

## 📊 Validaciones del Servicio

El servicio SOAP implementa las siguientes validaciones:

✅ Fechas válidas (formato YYYY-MM-DD)
✅ Verificación de disponibilidad de habitaciones
✅ Validación de existencia de habitación
✅ Cálculo automático de precio total
✅ Prevención de reservas solapadas
✅ Manejo de errores con SOAP Fault

---

## 🐛 Troubleshooting

### Error: "Cannot find module 'soap'"

```bash
cd backend
npm install soap xml2js
```

### Error: "WSDL not found"

Verificar que el archivo `backend/soap/bookingService.wsdl` existe.

### Error de conexión

Verificar que el backend esté ejecutándose en el puerto 3000:

```bash
docker-compose ps
```

---

## 📝 Notas

- El servicio SOAP convive con la API REST existente
- Ambos servicios (REST y SOAP) acceden a la misma base de datos
- Las reservas creadas por SOAP son visibles en la API REST y viceversa
- El WSDL describe completamente el contrato del servicio
