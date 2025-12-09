# Yazıhanem - Multi-Tenant Content Management System

A high-performance, schema-based multi-tenant CMS built with Go, Fiber, PostgreSQL, and Redis.

## Architecture

- **Clean Architecture** pattern with strict layer separation
- **Schema-based multi-tenancy** for data isolation
- **Type-safe database queries** using sqlc
- **High-performance** Go + Fiber framework
- **Scalable** PostgreSQL with connection pooling
- **Fast caching** with Redis

## Tech Stack

### Backend
- **Language**: Go 1.21+
- **Web Framework**: Fiber v2
- **Database**: PostgreSQL 15+
- **Query Builder**: sqlc
- **Cache**: Redis 7+
- **Migrations**: golang-migrate
- **Authentication**: JWT

### Frontend
- **Web Admin Panel**: Next.js 14 + React + TypeScript
- **UI Framework**: Tailwind CSS + shadcn/ui
- **Mobile App**: Flutter 3.x
- **State Management**: Zustand (Web) / Riverpod (Mobile)

## Project Structure

```
yazihanem/
├── backend/             # Go API Backend
│   ├── cmd/
│   │   └── api/              # Application entry point
│   ├── internal/
│   │   ├── domain/          # Business entities and rules
│   │   │   ├── entity/      # Domain models
│   │   │   └── repository/  # Repository interfaces
│   │   ├── usecase/         # Business logic
│   │   ├── delivery/        # HTTP handlers and middleware
│   │   │   └── http/
│   │   └── infrastructure/  # External dependencies
│   │       ├── database/    # PostgreSQL implementation
│   │       ├── cache/       # Redis implementation
│   │       └── storage/     # File storage
│   ├── config/              # Configuration management
│   ├── migrations/          # Database migrations
│   │   └── schema/
│   └── pkg/                 # Shared utilities
├── web-admin/           # Next.js Web Admin Panel
│   ├── src/
│   │   ├── app/             # Next.js app directory
│   │   ├── components/      # React components
│   │   ├── lib/             # Utilities and API client
│   │   └── types/           # TypeScript types
│   └── public/              # Static assets
├── mobile/              # Flutter Mobile App
│   ├── lib/
│   │   ├── features/        # Feature modules
│   │   ├── core/            # Core functionality
│   │   └── shared/          # Shared widgets
│   └── assets/              # App assets
└── scripts/             # Deployment and utility scripts
```

## Getting Started

### Prerequisites

- Go 1.21 or higher
- PostgreSQL 15+
- Redis 7+
- Docker (optional, for local development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/mehmetkilic/yazihanem.git
cd yazihanem
```

2. Copy environment variables:
```bash
cp .env.example .env
```

3. Install dependencies:
```bash
go mod download
```

4. Run database migrations:
```bash
make migrate-up
```

5. Start the server:
```bash
go run cmd/api/main.go
```

## Development

### Running with Docker Compose

```bash
docker-compose up -d
```

### Running Tests

```bash
cd backend/
make test
```

### Generate sqlc Code

After modifying SQL queries in `backend/internal/infrastructure/database/sqlc/queries/`:

```bash
cd backend/
make sqlc-generate
```

### Database Migrations

Run public schema migrations:
```bash
cd backend/
make migrate-up
```

Create a new tenant schema:
```bash
cd backend/
make migrate-tenant-create schema=tenant_example
```

Drop a tenant schema:
```bash
cd backend/
make migrate-tenant-drop schema=tenant_example
```

## API Documentation

API documentation will be available at `/api/docs` when the server is running.

## Deployment

See [ARCHITECTURE-DECISIONS.md](./ARCHITECTURE-DECISIONS.md) for infrastructure requirements and deployment guidelines.

### Recommended Hosting

- **Provider**: Hetzner Cloud
- **Estimated Cost**: ~€110/month (~$120)
- **Scalability**: 100 tenants, 100 concurrent users

## Security

- JWT-based authentication
- Tenant context validation (prevents cross-tenant data leaks)
- Rate limiting per tenant
- SQL injection prevention (sqlc parameterized queries)
- HTTPS/TLS encryption

## Performance Targets

- p50: < 50ms
- p95: < 200ms
- p99: < 500ms

## License

Proprietary - All rights reserved

## Contact

For questions or support, please open an issue on GitHub.
