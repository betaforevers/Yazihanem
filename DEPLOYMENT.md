# Yazıhanem - Kurulum ve Çalıştırma Dokümantasyonu

## İçindekiler

1. [Gereksinimler](#gereksinimler)
2. [Development Ortamı Kurulumu](#development-ortam%C4%B1-kurulumu)
3. [Production Ortamı Kurulumu](#production-ortam%C4%B1-kurulumu)
4. [Veritabanı Yönetimi](#veritaban%C4%B1-y%C3%B6netimi)
5. [Sorun Giderme](#sorun-giderme)

---

## Gereksinimler

### Yazılım Gereksinimleri

- **Docker & Docker Compose**: Veritabanı (PostgreSQL) ve Redis için
- **Go**: v1.21 veya üzeri (Backend için)
- **Node.js**: v18 veya üzeri (Frontend için)
- **npm** veya **yarn**: Frontend paket yöneticisi

### Donanım Gereksinimleri

- **Minimum**: 4GB RAM, 2 CPU core, 10GB disk alanı
- **Önerilen**: 8GB RAM, 4 CPU core, 20GB disk alanı

---

## Development Ortamı Kurulumu

### 1. Projeyi Klonlama

```bash
git clone https://github.com/kullanici/yazihanem.git
cd yazihanem
```

### 2. Docker Servislerini Başlatma

PostgreSQL ve Redis container'larını başlatın:

```bash
cd backend
docker-compose up -d
```

Container'ların çalıştığını kontrol edin:

```bash
docker ps
```

Şu container'ları görmelisiniz:
- `yazihanem-postgres` (Port: 5432)
- `yazihanem-redis` (Port: 6379)

### 3. Backend Konfigürasyonu

Backend dizinine gidin ve `.env` dosyasını oluşturun:

```bash
cd backend
cp .env.example .env
```

`.env` dosyasını düzenleyin (development için varsayılan ayarlar):

```env
# Server Configuration
PORT=8080

# PostgreSQL Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=yazihanem
DB_SSLMODE=disable

# Redis Cache
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT Authentication
JWT_SECRET=change-this-to-a-secure-random-string-in-production
JWT_EXPIRY=24h

# Object Storage
STORAGE_TYPE=local
UPLOAD_PATH=./uploads
```

### 4. Veritabanı Migrationları

Veritabanı şemalarını oluşturun:

```bash
# PostgreSQL container'a bağlanın
docker exec -it yazihanem-postgres psql -U postgres -d yazihanem

# Migration dosyalarını çalıştırın
\i /migrations/schema/000001_create_tenants_schema.up.sql
\i /migrations/schema/000002_create_users_table.up.sql
\i /migrations/schema/000003_create_content_table.up.sql
\i /migrations/schema/000004_create_media_table.up.sql
\i /migrations/schema/000005_create_stock_table.up.sql
\i /migrations/schema/000006_create_cold_chain_table.up.sql
\i /migrations/schema/000007_create_shipments_table.up.sql
\i /migrations/schema/000008_create_documents_table.up.sql
\i /migrations/schema/000009_create_certificates_table.up.sql
\i /migrations/schema/000010_create_reports_table.up.sql

# Çıkış yapın
\q
```

**VEYA** Script ile tek seferde:

```bash
cd backend/migrations/schema
for file in *.up.sql; do
    docker exec -i yazihanem-postgres psql -U postgres -d yazihanem < "$file"
done
```

### 5. Backend'i Başlatma

```bash
cd backend

# Go bağımlılıklarını yükleyin
go mod download

# Backend'i çalıştırın
PORT=8080 go run cmd/api/main.go
```

Backend başarıyla başladığında şu mesajları göreceksiniz:

```
✓ Database connected
✓ Redis connected
✓ Storage initialized
Starting server on port 8080
```

Backend şu adreste çalışacak: `http://localhost:8080`

### 6. Frontend Konfigürasyonu

Yeni bir terminal açın ve frontend dizinine gidin:

```bash
cd web/web-admin
```

`.env.local` dosyası oluşturun:

```env
NEXT_PUBLIC_BACKEND_URL=http://localhost:8080
```

### 7. Frontend'i Başlatma

```bash
# Bağımlılıkları yükleyin
npm install

# Development sunucusunu başlatın
npm run dev
```

Frontend şu adreste çalışacak: `http://localhost:3000`

### 8. Giriş Bilgileri

Varsayılan admin hesabı:

- **Email**: `admin@demo.com`
- **Şifre**: `admin123`

---

## Production Ortamı Kurulumu

### 1. Environment Değişkenleri

Production için `.env` dosyasını güncelleyin:

```env
# Server Configuration
PORT=8080
SERVER_READ_TIMEOUT=30s
SERVER_WRITE_TIMEOUT=30s

# PostgreSQL Database
DB_HOST=your-production-db-host
DB_PORT=5432
DB_USER=your-db-user
DB_PASSWORD=your-strong-password
DB_NAME=yazihanem
DB_SSLMODE=require
DB_MAX_OPEN_CONNS=100
DB_MAX_IDLE_CONNS=25

# Redis Cache
REDIS_HOST=your-production-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# JWT Authentication
JWT_SECRET=your-very-secure-random-string-here-minimum-32-characters
JWT_EXPIRY=24h

# Object Storage (S3/MinIO)
STORAGE_TYPE=s3
STORAGE_ENDPOINT=https://s3.amazonaws.com
STORAGE_ACCESS_KEY=your-access-key
STORAGE_SECRET_KEY=your-secret-key
STORAGE_BUCKET=yazihanem-production
STORAGE_REGION=us-east-1
```

### 2. Backend Production Build

```bash
cd backend

# Production build
go build -o bin/yazihanem-api -ldflags="-s -w" cmd/api/main.go

# Çalıştırma
./bin/yazihanem-api
```

### 3. Frontend Production Build

```bash
cd web/web-admin

# Production build
npm run build

# Production sunucusu
npm run start
```

### 4. Nginx Reverse Proxy (Önerilen)

Nginx yapılandırması (`/etc/nginx/sites-available/yazihanem`):

```nginx
server {
    listen 80;
    server_name yazihanem.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /uploads/ {
        alias /path/to/yazihanem/backend/uploads/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

SSL sertifikası için Let's Encrypt kullanın:

```bash
sudo certbot --nginx -d yazihanem.com
```

### 5. Systemd Servisleri

**Backend servisi** (`/etc/systemd/system/yazihanem-backend.service`):

```ini
[Unit]
Description=Yazıhanem Backend API
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=yazihanem
WorkingDirectory=/home/yazihanem/backend
Environment="PORT=8080"
ExecStart=/home/yazihanem/backend/bin/yazihanem-api
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Frontend servisi** (`/etc/systemd/system/yazihanem-frontend.service`):

```ini
[Unit]
Description=Yazıhanem Frontend
After=network.target

[Service]
Type=simple
User=yazihanem
WorkingDirectory=/home/yazihanem/web/web-admin
Environment="PORT=3000"
Environment="NODE_ENV=production"
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Servisleri başlatma:

```bash
sudo systemctl daemon-reload
sudo systemctl enable yazihanem-backend
sudo systemctl enable yazihanem-frontend
sudo systemctl start yazihanem-backend
sudo systemctl start yazihanem-frontend
```

---

## Veritabanı Yönetimi

### Yedekleme (Backup)

```bash
# PostgreSQL yedekleme
docker exec yazihanem-postgres pg_dump -U postgres yazihanem > backup_$(date +%Y%m%d_%H%M%S).sql

# Sıkıştırılmış yedekleme
docker exec yazihanem-postgres pg_dump -U postgres yazihanem | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Geri Yükleme (Restore)

```bash
# SQL dosyasından geri yükleme
docker exec -i yazihanem-postgres psql -U postgres -d yazihanem < backup.sql

# Sıkıştırılmış dosyadan geri yükleme
gunzip < backup.sql.gz | docker exec -i yazihanem-postgres psql -U postgres -d yazihanem
```

### Migration Geri Alma

```bash
# Tek bir migration'ı geri alma
docker exec -i yazihanem-postgres psql -U postgres -d yazihanem < migrations/schema/000010_create_reports_table.down.sql

# Tüm migrationları sıfırlama
cd backend/migrations/schema
for file in $(ls -r *.down.sql); do
    docker exec -i yazihanem-postgres psql -U postgres -d yazihanem < "$file"
done
```

---

## Sorun Giderme

### Backend Veritabanına Bağlanamıyor

**Hata**: `Failed to connect to database: connection refused`

**Çözüm**:

```bash
# PostgreSQL container'ın çalıştığını kontrol edin
docker ps | grep postgres

# Eğer çalışmıyorsa başlatın
docker start yazihanem-postgres

# Logları kontrol edin
docker logs yazihanem-postgres

# Container'a bağlanıp test edin
docker exec yazihanem-postgres psql -U postgres -d yazihanem -c "SELECT 1"
```

### Port Zaten Kullanımda

**Hata**: `bind: address already in use`

**Çözüm**:

```bash
# Port 8080'i kullanan işlemi bulun
sudo lsof -i :8080

# İşlemi sonlandırın
kill -9 <PID>

# VEYA farklı bir port kullanın
PORT=8081 go run cmd/api/main.go
```

### Frontend Backend'e Bağlanamıyor

**Hata**: `Network Error` veya `CORS Error`

**Çözüm**:

1. Backend'in çalıştığını kontrol edin: `curl http://localhost:8080/api/v1/health`

2. `.env.local` dosyasında `NEXT_PUBLIC_BACKEND_URL` doğru olmalı

3. CORS ayarlarını kontrol edin (`cmd/api/main.go`):

```go
app.Use(cors.New(cors.Config{
    AllowOrigins: "http://localhost:3000",
    AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
    AllowHeaders: "Origin,Content-Type,Accept,Authorization",
}))
```

### Redis Bağlantı Hatası

**Çözüm**:

```bash
# Redis container'ı başlatın
docker start yazihanem-redis

# Redis'e bağlanıp test edin
docker exec -it yazihanem-redis redis-cli ping
# Çıktı: PONG
```

### Migration Hataları

**Hata**: `relation already exists`

**Çözüm**: Migration zaten çalıştırılmış. Önce down migration çalıştırın, sonra tekrar up migration yapın.

### Too Many Connections (PostgreSQL)

**Çözüm**:

```bash
# Çalışan Go işlemlerini sonlandırın
killall -9 main go

# PostgreSQL'i yeniden başlatın
docker restart yazihanem-postgres

# Max connections ayarını artırın (.env)
DB_MAX_OPEN_CONNS=50
DB_MAX_IDLE_CONNS=10
```

---

## Yardımcı Komutlar

### Docker Container'ları Yönetme

```bash
# Tüm container'ları başlat
docker-compose up -d

# Tüm container'ları durdur
docker-compose down

# Logları görüntüle
docker-compose logs -f

# Container'ları yeniden başlat
docker-compose restart
```

### PostgreSQL Yönetimi

```bash
# PostgreSQL shell'e giriş
docker exec -it yazihanem-postgres psql -U postgres -d yazihanem

# Veritabanı listesi
docker exec yazihanem-postgres psql -U postgres -c "\l"

# Tablo listesi
docker exec yazihanem-postgres psql -U postgres -d yazihanem -c "\dt tenant_default.*"

# Kullanıcı sayısını kontrol et
docker exec yazihanem-postgres psql -U postgres -d yazihanem -c "SELECT COUNT(*) FROM tenant_default.users;"
```

### Backend İzleme

```bash
# Backend loglarını izle
tail -f backend.log

# Canlı istekleri izle
curl -s http://localhost:8080/api/v1/health

# Performans izleme
go tool pprof http://localhost:8080/debug/pprof/profile
```

---

## Güvenlik Kontrol Listesi

- [ ] `.env` dosyalarını `.gitignore`'a ekleyin
- [ ] Production'da güçlü JWT_SECRET kullanın (minimum 32 karakter)
- [ ] Veritabanı şifresini değiştirin
- [ ] PostgreSQL SSL bağlantısını aktifleştirin (`DB_SSLMODE=require`)
- [ ] Nginx rate limiting yapılandırın
- [ ] HTTPS sertifikası yükleyin (Let's Encrypt)
- [ ] Firewall kurallarını yapılandırın (sadece 80, 443 portları açık)
- [ ] Düzenli veritabanı yedeklemesi yapın
- [ ] Log rotasyonu ayarlayın
- [ ] Redis şifresi belirleyin

---

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## Destek

Sorun yaşıyorsanız:
- GitHub Issues: https://github.com/kullanici/yazihanem/issues
- Email: destek@yazihanem.com
- WhatsApp: +1 (458) 343-1760
