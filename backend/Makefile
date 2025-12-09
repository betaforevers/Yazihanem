.PHONY: help run build test clean migrate-up migrate-down migrate-create docker-up docker-down

# Default target
help:
	@echo "Available commands:"
	@echo "  make run           - Run the application"
	@echo "  make build         - Build the application binary"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make migrate-up    - Run database migrations"
	@echo "  make migrate-down  - Rollback database migrations"
	@echo "  make migrate-create name=<migration_name> - Create new migration"
	@echo "  make docker-up     - Start Docker Compose services"
	@echo "  make docker-down   - Stop Docker Compose services"

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

# Clean build artifacts
clean:
	rm -rf bin/
	rm -f coverage.out

# Database migrations (requires golang-migrate)
migrate-up:
	@echo "Run migrations manually with: migrate -path migrations/schema -database postgres://user:pass@localhost:5432/yazihanem?sslmode=disable up"

migrate-down:
	@echo "Rollback migrations manually with: migrate -path migrations/schema -database postgres://user:pass@localhost:5432/yazihanem?sslmode=disable down"

migrate-create:
	@echo "Create migration manually with: migrate create -ext sql -dir migrations/schema -seq $(name)"

# Docker Compose (runs from project root)
docker-up:
	cd .. && docker-compose up -d

docker-down:
	cd .. && docker-compose down
