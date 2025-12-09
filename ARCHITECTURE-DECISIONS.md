# Yazıhanem - Architectural Decisions Document
**Date**: 2025-12-09
**Project Type**: Multi-tenant Content Management System
**Tech Stack**: Go + Fiber + sqlc + PostgreSQL + Redis + Flutter + Next.js

---

## CRITICAL DESIGN DECISIONS

### 1. Multi-Tenancy Model
**Decision**: Schema-based isolation
**Rationale**:
- Each tenant gets dedicated PostgreSQL schema
- Balance between security and operational complexity
- Better than row-level (security risk) and cheaper than database-per-tenant

### 2. Scale Parameters
- **Target Tenants**: 100
- **Concurrent Users**: 100 (1 user per tenant)
- **Data Growth Rate**: 1,000 records per tenant per day
- **Monthly Growth**: 3,000,000 records
- **Annual Growth**: 36,000,000 records

---

## INFRASTRUCTURE REQUIREMENTS

### Application Server (Go + Fiber + Web Admin Static Hosting)
```
CPU: 4 vCPU (Intel Xeon or AMD EPYC)
RAM: 8 GB
Storage: 50 GB SSD
Network: 1 Gbps
OS: Ubuntu 22.04 LTS
Services:
  - Go Fiber API (port 3000)
  - Nginx reverse proxy + Web Admin static files (port 80/443)
```
**Note**: Web Admin Panel will be built as static Next.js export and served via Nginx

### PostgreSQL Database Server
```
CPU: 8 vCPU (schema switching overhead)
RAM: 32 GB (recommended for 100 schemas)
Storage: 1 TB NVMe SSD
IOPS: 5,000+ sustained
Network: 10 Gbps
OS: Ubuntu 22.04 LTS
```
**Critical Notes**:
- 100 schemas = high metadata overhead
- Connection pooling via pgBouncer mandatory
- Write-heavy workload requires high IOPS

### Redis Cache Server
```
CPU: 2 vCPU
RAM: 8 GB
Storage: 20 GB SSD
Network: 1 Gbps
```
**Usage**: Session management, tenant metadata cache, query cache

### Object Storage (S3-compatible)
```
Provider: MinIO (self-hosted) OR Backblaze B2 OR Wasabi
Initial Capacity: 500 GB
Growth Estimate: +100 GB/month
```
**Purpose**: Media and file storage for content management

---

## COST ANALYSIS

### Provider Comparison
| Provider | App Server | DB Server | Redis | Total/Month |
|----------|------------|-----------|-------|-------------|
| **Hetzner (Germany)** | €20 (CPX31) | €90 (CCX63) | Included | **€110 (~$120)** |
| DigitalOcean | $48 | $240 | $24 | $312 |
| Vultr | $48 | $256 | $24 | $328 |
| AWS EC2 | $70 | $450 | $30 | $550 |

**RECOMMENDED**: Hetzner (cheapest, reliable, EU data center)

---

## TECHNOLOGY STACK DETAILS

### Backend
- **Language**: Go 1.21+
- **Framework**: Fiber v2 (Express-like, high performance)
- **Database**: PostgreSQL 15+
- **Query Builder**: sqlc (type-safe SQL code generation)
- **Migrations**: golang-migrate
- **Cache**: Redis 7+
- **Authentication**: JWT with tenant context

### Frontend
- **Mobile App (Tenant Users)**: Flutter 3.x
- **Web Admin Panel (Management)**: Next.js 14+ with React 18
- **UI Framework (Web)**: Tailwind CSS + shadcn/ui
- **State Management (Web)**: React Context / Zustand
- **API Integration**: RESTful JSON API (both platforms)

### Architecture Pattern
- **Clean Architecture** (Domain → Use Cases → Controllers → Infrastructure)
- Strict layer separation
- Dependency injection
- Repository pattern for data access

---

## INITIAL IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Day 1-2)
1. Initialize Git repository
2. Create Go module and project structure
3. Setup PostgreSQL schema migration system
4. Configure sqlc for type-safe queries
5. Create Docker Compose for local development

### Phase 2: Core Features (Day 3-5)
1. Implement tenant resolution middleware
2. Build authentication system (JWT + tenant context)
3. Design and create initial database schema
4. Setup Redis connection pool
5. Implement session management

### Phase 3: API Development (Day 6-10)
1. Create content CRUD endpoints
2. Implement user management
3. Add media upload/storage integration
4. Build tenant onboarding flow
5. Add rate limiting and security middleware

### Phase 4: Testing & Deployment (Day 11-14)
1. Write unit tests (domain logic)
2. Write integration tests (API endpoints)
3. Create deployment scripts for Hetzner
4. Setup CI/CD pipeline
5. Write operational documentation

### Phase 5: Web Admin Panel Development (Day 15-21)
1. Initialize Next.js 14 project with TypeScript
2. Setup Tailwind CSS + shadcn/ui components
3. Implement authentication flow (JWT integration)
4. Build tenant management dashboard
5. Create user management interface
6. Develop content CRUD interface
7. Add media upload/management
8. Implement role-based access control
9. Build analytics dashboard
10. Configure static export and deployment

### Phase 6: Flutter Mobile App Development (Day 22-35)
1. Initialize Flutter project structure
2. Setup state management (Riverpod/Bloc)
3. Implement authentication screens
4. Build content browsing UI
5. Create content creation/editing screens
6. Add media upload functionality
7. Implement offline-first architecture
8. Add push notifications
9. Build user profile management
10. Testing and app store preparation

---

## SECURITY REQUIREMENTS

### Mandatory Controls
- JWT token validation on every request
- Tenant context validation (prevent cross-tenant data leaks)
- Rate limiting per tenant (prevent abuse)
- SQL injection prevention (sqlc parameterized queries)
- HTTPS/TLS encryption in transit
- Encrypted database backups
- Audit logging for sensitive operations

### PostgreSQL Security
- Row-level security as secondary defense layer
- Least privilege database users per service
- Connection pooling via pgBouncer (prevent connection exhaustion)
- Regular backup testing (restore drills monthly)

---

## PERFORMANCE TARGETS

### API Response Times
- p50: < 50ms
- p95: < 200ms
- p99: < 500ms

### Database Query Performance
- Indexes on all foreign keys
- Composite indexes for common WHERE clauses
- Query timeout: 5 seconds max
- Connection pool size: 20 per application instance

### Cache Hit Ratio
- Target: > 80% for tenant metadata
- TTL strategy: 5 minutes for session data, 1 hour for static metadata

---

## CONSTRAINTS & RESTRICTIONS

### Forbidden Patterns
- No shared tables without tenant_id filtering
- No direct database access from controllers (repository pattern only)
- No secrets in code (environment variables only)
- No synchronous long-running operations (use background jobs)

### Code Quality Standards
- All database queries via sqlc (no raw SQL in business logic)
- 100% error handling (no ignored errors)
- Structured logging only (JSON format)
- No panic() in production code paths

---

## OPEN QUESTIONS / FUTURE CONSIDERATIONS

1. **Backup Strategy**: Daily automated backups? Retention period?
2. **Monitoring**: Prometheus + Grafana? Alert thresholds?
3. **Geographic Distribution**: Single region or multi-region?
4. **Compliance**: GDPR/KVKK requirements for data residency?
5. **Disaster Recovery**: RTO/RPO targets?

---

**Document Status**: Approved for implementation
**Next Step**: Initialize Git repository and begin Phase 1