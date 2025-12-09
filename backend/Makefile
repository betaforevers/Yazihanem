.PHONY: help run build test clean migrate-up migrate-tenant-create migrate-tenant-drop sqlc-generate docker-up docker-down

# Default target
help:
	@echo "Available commands:"
	@echo "  make run                          - Run the application"
	@echo "  make build                        - Build the application binary"
	@echo "  make test                         - Run tests"
	@echo "  make clean                        - Clean build artifacts"
	@echo "  make sqlc-generate                - Generate sqlc code from SQL queries"
	@echo "  make migrate-up                   - Run public schema migrations"
	@echo "  make migrate-tenant-create schema=<name> - Create tenant schema"
	@echo "  make migrate-tenant-drop schema=<name>   - Drop tenant schema"
	@echo "  make docker-up                    - Start Docker Compose services"
	@echo "  make docker-down                  - Stop Docker Compose services"

# Run the application
run:
	go run cmd/api/main.go

# Build the application
build:
	@mkdir -p bin
	go build -o bin/yazihanem cmd/api/main.go

# Build for Windows
build-windows:
	@mkdir -p bin
	GOOS=windows GOARCH=amd64 go build -o bin/yazihanem.exe cmd/api/main.go

# Build for Linux (production)
build-linux:
	@mkdir -p bin
	GOOS=linux GOARCH=amd64 go build -o bin/yazihanem cmd/api/main.go

# Run tests
test:
	go test -v -race -coverprofile=coverage.out ./...

# Generate sqlc code
sqlc-generate:
	@echo "Generating sqlc code..."
	@sqlc generate

# Clean build artifacts
clean:
	rm -rf bin/
	rm -f coverage.out

# Database migrations
migrate-up:
	@echo "Running public schema migrations..."
	@go run cmd/migrate/main.go up

migrate-tenant-create:
	@if [ -z "$(schema)" ]; then \
		echo "Error: schema name required"; \
		echo "Usage: make migrate-tenant-create schema=tenant_example"; \
		exit 1; \
	fi
	@echo "Creating tenant schema: $(schema)"
	@go run cmd/migrate/main.go create-tenant $(schema)

migrate-tenant-drop:
	@if [ -z "$(schema)" ]; then \
		echo "Error: schema name required"; \
		echo "Usage: make migrate-tenant-drop schema=tenant_example"; \
		exit 1; \
	fi
	@echo "Dropping tenant schema: $(schema)"
	@go run cmd/migrate/main.go drop-tenant $(schema)

# Docker Compose (runs from project root)
docker-up:
	cd .. && docker-compose up -d

docker-down:
	cd .. && docker-compose down
