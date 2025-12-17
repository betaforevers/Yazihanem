package main

import (
	"context"
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

	// Hash the password "demo123"
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte("demo123"), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	// Update admin user password
	query := `UPDATE tenant_default.users SET password_hash = $1 WHERE email = 'admin@demo.com'`
	result, err := pool.Exec(context.Background(), query, string(hashedPassword))
	if err != nil {
		log.Fatalf("Failed to update password: %v", err)
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		log.Println("No user found with email admin@demo.com")
	} else {
		log.Printf("✓ Password updated successfully for admin@demo.com (rows affected: %d)", rowsAffected)
		log.Println("✓ New password: demo123")
	}
}
