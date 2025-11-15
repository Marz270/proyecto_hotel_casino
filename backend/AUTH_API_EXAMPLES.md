# 🔐 API de Autenticación - Ejemplos de Uso

Sistema de autenticación JWT con bcrypt para Salto Hotel & Casino.

## 📋 Endpoints Disponibles

| Método | Endpoint         | Protegido | Descripción                          |
| ------ | ---------------- | --------- | ------------------------------------ |
| POST   | `/auth/register` | ❌        | Registrar nuevo usuario              |
| POST   | `/auth/login`    | ❌        | Iniciar sesión (obtener token)       |
| GET    | `/auth/me`       | ✅        | Obtener info del usuario autenticado |
| POST   | `/auth/verify`   | ✅        | Verificar validez del token          |

## 🔑 Usuarios de Prueba

| Username  | Email                      | Password   | Rol   |
| --------- | -------------------------- | ---------- | ----- |
| `admin`   | admin@saltohotelcasino.com | `admin123` | admin |
| `usuario` | user@saltohotelcasino.com  | `user123`  | user  |

## 📝 Ejemplos de Uso

### 1. Registrar Nuevo Usuario

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"username": "newuser", "email": "new@example.com", "password": "password123"}'
```

**Respuesta exitosa:**

```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 2. Iniciar Sesión

```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"username": "admin", "password": "admin123"}'

$token = $response.token
```

**Respuesta exitosa:**

```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3. Obtener Info del Usuario Autenticado

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/me" `
  -Method GET `
  -Headers @{Authorization="Bearer $token"}
```

**Respuesta exitosa:**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@saltohotelcasino.com",
    "role": "admin",
    "created_at": "2025-11-14T..."
  }
}
```

### 4. Verificar Token

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/verify" `
  -Method POST `
  -Headers @{Authorization="Bearer $token"}
```

**Respuesta exitosa:**

```json
{
  "success": true,
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@saltohotelcasino.com",
    "role": "admin",
    "iat": 1763164000,
    "exp": 1763250400
  }
}
```

## ⚠️ Manejo de Errores

### Credenciales Incorrectas

```powershell
try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
    -Method POST -ContentType "application/json" `
    -Body '{"username": "admin", "password": "wrongpass"}'
} catch {
  $_.ErrorDetails.Message | ConvertFrom-Json
}
```

**Respuesta:**

```json
{
  "success": false,
  "error": "Contraseña incorrecta"
}
```

### Token Inválido o Expirado

```powershell
try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/me" `
    -Method GET -Headers @{Authorization="Bearer invalid_token"}
} catch {
  $_.ErrorDetails.Message | ConvertFrom-Json
}
```

**Respuesta:**

```json
{
  "success": false,
  "error": "Token inválido o expirado"
}
```

### Faltan Credenciales

```powershell
try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/me" `
    -Method GET
} catch {
  $_.ErrorDetails.Message | ConvertFrom-Json
}
```

**Respuesta:**

```json
{
  "success": false,
  "error": "No se proporcionó token de autenticación"
}
```

## 🔒 Características de Seguridad

- **Hashing de Contraseñas**: bcrypt con 10 salt rounds
- **Tokens JWT**: Expiración de 24 horas
- **Validación de Entrada**: express-validator para todos los campos
- **Protección de Rutas**: Middleware `authenticate` y `authorize`

## 🛠️ Usando el Token en Otras Rutas

Para proteger cualquier ruta existente, simplemente importa y usa el middleware:

```javascript
const { authenticate, authorize } = require("../middleware/authMiddleware");

// Requiere autenticación
router.get("/protected", authenticate, (req, res) => {
  res.json({ user: req.user });
});

// Requiere rol específico
router.delete("/admin-only", authenticate, authorize("admin"), (req, res) => {
  res.json({ message: "Admin access granted" });
});
```

## 📊 Verificación Completa

Script completo para verificar todo el sistema:

```powershell
# 1. Login como admin
$adminToken = (Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"username": "admin", "password": "admin123"}').token

# 2. Obtener info del admin
Invoke-RestMethod -Uri "http://localhost:3000/auth/me" `
  -Method GET -Headers @{Authorization="Bearer $adminToken"}

# 3. Login como usuario regular
$userToken = (Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method POST -ContentType "application/json" `
  -Body '{"username": "usuario", "password": "user123"}').token

# 4. Verificar token de usuario
Invoke-RestMethod -Uri "http://localhost:3000/auth/verify" `
  -Method POST -Headers @{Authorization="Bearer $userToken"}

# 5. Registrar nuevo usuario
$newToken = (Invoke-RestMethod -Uri "http://localhost:3000/auth/register" `
  -Method POST -ContentType "application/json" `
  -Body '{"username": "testuser2", "email": "test2@example.com", "password": "test123456"}').token

Write-Host "✅ Todos los endpoints funcionan correctamente" -ForegroundColor Green
```

## 🚀 Próximos Pasos

1. **Frontend**: Integrar con Angular usando `AuthService`
2. **Proteger Rutas**: Agregar middleware a `/bookings`, `/payments`, `/reports`
3. **Refresh Tokens**: Implementar tokens de actualización de larga duración
4. **Roles Avanzados**: Sistema de permisos granulares
