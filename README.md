# Yazıhanem - Multi-Tenant Content Management System

A high-performance, schema-based multi-tenant CMS built with Go, Fiber, PostgreSQL, and Redis.

## Architecture

- **Clean Architecture** pattern with strict layer separation
- **Schema-based multi-tenancy** for data isolation
- **Type-safe database queries** using sqlc
- **High-performance** Go + Fiber framework
- **Scalable** PostgreSQL with connection pooling
- **Fast caching** with Redis
- **Storage abstraction** for local/S3/MinIO file uploads

## Tech Stack

### Backend
- **Language**: Go 1.21+
- **Web Framework**: Fiber v2
- **Database**: PostgreSQL 15+
- **Query Builder**: sqlc
- **Cache**: Redis 7+
- **Storage**: Local/S3/MinIO (abstraction layer)
- **Migrations**: golang-migrate
- **Authentication**: JWT
- **Rate Limiting**: Redis-based sliding window
- **Audit Logging**: PostgreSQL (GDPR/KVKK compliance)

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

## Demo Credentials

For testing the web admin panel, use these demo accounts:

### Admin User
- **Email**: `admin@demo.com`
- **Password**: `demo123`
- **Permissions**: Full access (admin role)

### Editor User
- **Email**: `editor@demo.com`
- **Password**: `demo123`
- **Permissions**: Content editing (editor role)

### Viewer User
- **Email**: `viewer@demo.com`
- **Password**: `demo123`
- **Permissions**: Read-only access (viewer role)

**Note**: Session timeout is 1 hour. After inactivity, you'll be automatically logged out.

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

5. Create demo tenant and users:
```bash
# Connect to PostgreSQL and run the demo user script
psql -U postgres -d yazihanem -f backend/scripts/create_demo_user.sql
```

6. Start the backend server:
```bash
cd backend
go run cmd/api/main.go
```

7. Start the web admin panel (in a new terminal):
```bash
cd web/web-admin
npm install
npm run dev
```

The web admin panel will be available at `http://localhost:3000`

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

## Features

### Core Functionality
- ✅ Multi-tenant SaaS architecture (schema-based isolation)
- ✅ JWT authentication with session management
- ✅ Content CRUD operations (draft → published workflow)
- ✅ Media upload system (images, videos, audio, documents)
- ✅ Rate limiting (tenant-based + IP-based)
- ✅ Audit logging (compliance & security)
- ✅ User management (admin/editor/viewer roles)

### API Endpoints (22 total)
- **Auth**: `/api/v1/auth/*` (login, logout, refresh, me, change-password)
- **Content**: `/api/v1/content/*` (CRUD, publish, slug-based retrieval)
- **Media**: `/api/v1/media/*` (upload, list, get, delete)
- **Admin**: `/api/v1/admin/*` (stats, audit logs, user management)
- **Public**: `/health` (health check)

### Storage
- **Local filesystem** (production-ready)
- **S3/MinIO** (interface ready, implementation pending)
- **Tenant-isolated paths**: `{tenant_id}/media/{year}/{month}/{filename}`
- **MIME type validation**: 15 allowed types (images, videos, audio, documents)
- **File size limit**: 50MB per upload

## API Documentation

API documentation will be available at `/api/docs` when the server is running.

### Quick API Examples

**Upload Media:**
```bash
curl -X POST http://localhost:3000/api/v1/media/upload \
  -H "Authorization: Bearer {JWT}" \
  -F "file=@image.jpg"
```

**Create Content:**
```bash
curl -X POST http://localhost:3000/api/v1/content \
  -H "Authorization: Bearer {JWT}" \
  -H "Content-Type: application/json" \
  -d '{"title":"My Post","slug":"my-post","body":"Content..."}'
```

**List Content:**
```bash
curl http://localhost:3000/api/v1/content?status=published&page=1
```

## Deployment

See [ARCHITECTURE-DECISIONS.md](./ARCHITECTURE-DECISIONS.md) for infrastructure requirements and deployment guidelines.

### Recommended Hosting

- **Provider**: Hetzner Cloud
- **Estimated Cost**: ~€110/month (~$120)
- **Scalability**: 100 tenants, 100 concurrent users

## Security

- ✅ JWT-based authentication (RS256 signing)
- ✅ Tenant context validation (prevents cross-tenant data leaks)
- ✅ Rate limiting (1000 req/min per tenant, 5 req/min for login)
- ✅ SQL injection prevention (sqlc parameterized queries)
- ✅ MIME type whitelist (prevents malicious file uploads)
- ✅ File size limits (50MB max)
- ✅ Audit logging (all critical operations tracked)
- ✅ HTTPS/TLS encryption (production requirement)

## Performance Targets

- p50: < 50ms
- p95: < 200ms
- p99: < 500ms

## License

Proprietary - All rights reserved

## Contact

For questions or support, please open an issue on GitHub.
