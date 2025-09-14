# Copilot Instructions for proyecto_hotel_casino

## 🎯 Academic Project Context (TFU2 - Análisis y Diseño de Aplicaciones II)

This is the **Trabajo Final Unidad 2** demonstrating architectural tactics for non-functional requirements (NFRs) in a hotel-casino reservation system. The goal is to show **rollback capabilities** and **deferred binding** patterns through a containerized REST API.

**Key NFRs to demonstrate:**

- **Deployment facilitation** (rollback tactics)
- **Modifiability** (deferred binding via dependency injection & external configuration)
- **Performance** (efficient database pooling)
- **Security** (input validation, error handling)

## Project Overview

Node.js backend for **Salto Hotel & Casino** reservation system. Uses Express for REST API, PostgreSQL for persistence, and Docker Compose for orchestration and rollback demonstrations.

## Architecture & Key Files

- **backend/server.js**: Main Express server setup. Loads routes from `routes/index.routes.js`.
- **backend/database/db.js**: PostgreSQL connection pool using environment variables.
- **backend/routes/index.routes.js**: Main API route definitions.
- **backend/Dockerfile**: Containerizes the backend service.
- **docker-compose.yaml**: Orchestrates the API and database containers, sets up environment variables, and mounts database initialization scripts.

## Developer Workflows

- **Start locally**: `npm start` from `backend/` directory
- **Full stack with Docker**: `docker-compose up` from project root
- **Rollback demo**: Use `docker-compose -f docker-compose.rollback.yaml up` to demonstrate version switching
- **Environment config**: Load sensitive data from `.env` files, demonstrate external configuration binding
- **API testing**: Use provided curl examples or Postman collection for CRUD operations
- **Database init**: Scripts in `backend/database/scripts/` auto-run on PostgreSQL container startup

## Required Demo Features

**REST API endpoints** (minimal CRUD):

- `GET/POST /reservations` - Reservation management
- `GET/POST /clients` - Client management
- `GET /rooms` - Room availability

**Architectural tactics to showcase:**

- **Rollback**: Multiple app versions via Docker tags/compose files
- **Deferred binding**: Dependency injection patterns, environment-based configuration
- **Input validation**: Use `express-validator` for security
- **Error handling**: Centralized JSON error responses

## Patterns & Conventions

- **Error Handling**: Centralized error middleware in `server.js` returns JSON error responses
- **Routing**: All routes defined in `routes/index.routes.js` and mounted at `/`
- **Database Access**: Use the exported `pool` from `database/db.js` for all queries. Do not create new connections manually
- **CommonJS Modules**: All backend code uses `require`/`module.exports`
- **API Responses**: Prefer JSON responses for all endpoints
- **Dependency Injection**: Services injected via constructor/function parameters (demonstrate deferred binding)
- **Configuration**: External config via environment variables, avoid hardcoded values

## Integration Points

- **PostgreSQL**: All data access goes through the `pg` library and the connection pool in `db.js`
- **Docker**: Use Docker Compose for local development and orchestration. Database initialization scripts can be placed in `backend/database/scripts/`
- **Environment Variables**: Database credentials, JWT secrets, and feature flags managed externally

## Examples

- To add a new route, edit `routes/index.routes.js` and mount it in `server.js` if needed
- To run the backend in development, use `docker-compose up` and access the API at `localhost:3000`
- To connect to the database, use the `pool` object from `db.js`
- For rollback demo: Create v1/v2 tags and switch between compose files

---

If any conventions or workflows are unclear, please ask for clarification or provide feedback to improve these instructions.
