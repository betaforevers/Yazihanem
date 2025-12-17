package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Connect to database
	dbURL := "postgres://postgres:postgres@localhost:5432/yazihanem?sslmode=disable"
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer pool.Close()

	// Fetch user
	var email, passwordHash string
	query := `SELECT email, password_hash FROM tenant_default.users WHERE email = 'admin@demo.com'`
	err = pool.QueryRow(context.Background(), query).Scan(&email, &passwordHash)
	if err != nil {
		log.Fatalf("Failed to fetch user: %v", err)
	}

	fmt.Printf("Email: %s\n", email)
	fmt.Printf("Hash: %s\n", passwordHash)

	// Test passwords
	passwords := []string{"admin123", "demo123", "password", "admin"}
	for _, pwd := range passwords {
		err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(pwd))
		if err == nil {
			fmt.Printf("✓ Password '%s' MATCHES\n", pwd)
		} else {
			fmt.Printf("✗ Password '%s' does NOT match\n", pwd)
		}
	}
}
