# Yazihanem Test Suite

Comprehensive testing infrastructure for multi-tenant SaaS backend.

## Test Structure

```
tests/
├── integration/
│   ├── tenant_isolation_test.go    # CRITICAL: Tenant security tests
│   ├── auth_flow_test.go           # Authentication workflow tests
│   └── content_api_test.go         # Content API endpoint tests
└── load/
    └── load_test.js                # k6 performance tests
```

## Prerequisites

### Unit & Integration Tests
```bash
# Docker (for testcontainers)
docker --version  # Should be 20.10+

# Go test dependencies
cd backend
make -f Makefile.test deps
```

### Load Tests
```bash
# Install k6
# Ubuntu/Debian
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# macOS
brew install k6

# Verify installation
k6 version
```

## Running Tests

### Quick Start
```bash
cd backend

# Run all tests
make -f Makefile.test test

# Run unit tests only (fast)
make -f Makefile.test test-unit

# Run integration tests (requires Docker)
make -f Makefile.test test-integration

# Run load tests (requires backend running)
make -f Makefile.test test-load
```

### Test Coverage
```bash
# Generate coverage report
make -f Makefile.test test-coverage

# Check coverage threshold (minimum 60%)
make -f Makefile.test test-coverage-check
```

### Advanced Usage
```bash
# Run specific test
make -f Makefile.test test-run TEST=TestTenantIsolation_CannotAccessOtherTenantData

# Run tests with verbose output
make -f Makefile.test test-verbose

# Run quick smoke tests
make -f Makefile.test test-quick

# Run benchmark tests
make -f Makefile.test test-bench

# Watch mode (auto-run on file changes)
make -f Makefile.test test-watch
```

## Test Categories

### 1. Unit Tests
**Purpose**: Test individual functions and domain logic
**Speed**: Fast (<1s)
**Dependencies**: None (no Docker required)

**Examples**:
- `pkg/dbutil/tenant_conn_test.go` - Schema name validation
- `internal/domain/entity/user_test.go` - Password validation

```bash
go test -short ./internal/domain/... ./pkg/...
```

### 2. Integration Tests
**Purpose**: Test complete API workflows with real PostgreSQL/Redis
**Speed**: Moderate (10-60s depending on Docker)
**Dependencies**: Docker required

**Examples**:
- `tests/integration/tenant_isolation_test.go` - **CRITICAL** tenant security
- `tests/integration/auth_flow_test.go` - JWT authentication
- `tests/integration/content_api_test.go` - Content CRUD operations

```bash
go test -v ./tests/integration/... -timeout 5m
```

### 3. Load Tests
**Purpose**: Validate performance under concurrent load
**Speed**: Slow (5-10 minutes)
**Dependencies**: Backend running + k6 installed

**Metrics Validated**:
- ✅ p95 latency < 200ms
- ✅ p99 latency < 500ms
- ✅ Error rate < 1%
- ✅ Handles 200 concurrent users

```bash
# Start backend
cd backend
go run ./cmd/api/main.go

# Run load test (in another terminal)
k6 run tests/load/load_test.js
```

## Critical Tests

### Tenant Isolation Tests (MANDATORY)
These tests verify the core security boundary of the multi-tenant system:

1. **TestTenantIsolation_CannotAccessOtherTenantData**
   - Verifies Tenant A cannot read Tenant B data
   - **Status**: If this fails, system has critical security vulnerability

2. **TestTenantIsolation_ContentSeparation**
   - Verifies content is isolated between tenants
   - **Status**: MUST pass before production deployment

3. **TestTenantIsolation_MaliciousSchemaInjection**
   - Tests SQL injection prevention
   - **Status**: MUST pass to prevent schema-level attacks

4. **TestTenantIsolation_ConcurrentAccess**
   - Verifies isolation under concurrent load
   - **Status**: MUST pass to prevent race conditions

**Run critical tests**:
```bash
go test -v ./tests/integration/tenant_isolation_test.go -run TestTenantIsolation
```

## CI/CD Integration

### GitHub Actions (Recommended)
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - name: Run tests
        run: |
          cd backend
          make -f Makefile.test test-ci
```

## Troubleshooting

### Docker Connection Errors
```bash
# Verify Docker is running
docker ps

# Check Docker permissions
sudo usermod -aG docker $USER
newgrp docker
```

### testcontainers Cleanup
```bash
# Remove orphaned containers
docker container prune

# Remove orphaned volumes
docker volume prune
```

### k6 Installation Issues
```bash
# Verify k6 installation
k6 version

# Test k6 with simple script
k6 run --vus 10 --duration 30s tests/load/load_test.js
```

## Coverage Targets

| Component | Target | Current | Status |
|-----------|--------|---------|--------|
| **Domain Layer** | 80% | TBD | ⏳ |
| **Infrastructure** | 60% | TBD | ⏳ |
| **Handlers** | 70% | TBD | ⏳ |
| **Overall** | 60% | TBD | ⏳ |

## Performance Benchmarks

```bash
# Run benchmarks
go test -bench=. -benchmem ./...

# Example output:
# BenchmarkTenantConnection-8    1000    1234 ns/op    512 B/op    4 allocs/op
```

## Writing New Tests

### Unit Test Template
```go
package mypackage

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestMyFunction(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    string
        wantErr bool
    }{
        {name: "valid input", input: "test", want: "expected", wantErr: false},
        {name: "invalid input", input: "", want: "", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := MyFunction(tt.input)
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
                assert.Equal(t, tt.want, got)
            }
        })
    }
}
```

### Integration Test Template
```go
package integration

import (
    "testing"
    "yazihanem/backend/internal/testutil"
)

func TestMyIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test in short mode")
    }

    infra := testutil.SetupTestInfrastructure(t)
    defer infra.Teardown(t)

    // Your test logic here
}
```

## Best Practices

1. **Always run tests before commit**
   ```bash
   make -f Makefile.test test
   ```

2. **Tag integration tests**
   ```go
   if testing.Short() {
       t.Skip("Skipping integration test")
   }
   ```

3. **Use table-driven tests** for comprehensive coverage

4. **Clean up resources** with `defer`

5. **Verify tenant isolation** in every multi-tenant feature

## Contact

For test infrastructure questions, see `ARCHITECTURE-DECISIONS.md` Phase 4 section.
