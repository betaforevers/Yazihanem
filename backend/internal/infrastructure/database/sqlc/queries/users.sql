-- Note: These queries use placeholder {SCHEMA} which will be replaced at runtime
-- The actual schema name (e.g., tenant_acme) will be injected dynamically

-- name: CreateUser :one
INSERT INTO users (
    email,
    password_hash,
    first_name,
    last_name,
    role,
    is_active
) VALUES (
    $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 LIMIT 1;

-- name: ListUsers :many
SELECT * FROM users
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListUsersByRole :many
SELECT * FROM users
WHERE role = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListActiveUsers :many
SELECT * FROM users
WHERE is_active = true
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: UpdateUser :one
UPDATE users
SET
    email = COALESCE(sqlc.narg('email'), email),
    first_name = COALESCE(sqlc.narg('first_name'), first_name),
    last_name = COALESCE(sqlc.narg('last_name'), last_name),
    role = COALESCE(sqlc.narg('role'), role),
    is_active = COALESCE(sqlc.narg('is_active'), is_active)
WHERE id = sqlc.arg('id')
RETURNING *;

-- name: UpdateUserPassword :exec
UPDATE users
SET password_hash = $2
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM users
WHERE id = $1;

-- name: CountUsers :one
SELECT COUNT(*) FROM users;

-- name: CountUsersByRole :one
SELECT COUNT(*) FROM users
WHERE role = $1;
