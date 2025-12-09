-- name: CreateTenant :one
INSERT INTO public.tenants (
    name,
    schema_name,
    domain,
    is_active,
    max_users,
    max_storage
) VALUES (
    $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetTenantByID :one
SELECT * FROM public.tenants
WHERE id = $1 LIMIT 1;

-- name: GetTenantByDomain :one
SELECT * FROM public.tenants
WHERE domain = $1 AND is_active = true LIMIT 1;

-- name: GetTenantBySchemaName :one
SELECT * FROM public.tenants
WHERE schema_name = $1 LIMIT 1;

-- name: ListTenants :many
SELECT * FROM public.tenants
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListActiveTenants :many
SELECT * FROM public.tenants
WHERE is_active = true
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: UpdateTenant :one
UPDATE public.tenants
SET
    name = COALESCE(sqlc.narg('name'), name),
    domain = COALESCE(sqlc.narg('domain'), domain),
    is_active = COALESCE(sqlc.narg('is_active'), is_active),
    max_users = COALESCE(sqlc.narg('max_users'), max_users),
    max_storage = COALESCE(sqlc.narg('max_storage'), max_storage)
WHERE id = sqlc.arg('id')
RETURNING *;

-- name: DeleteTenant :exec
DELETE FROM public.tenants
WHERE id = $1;

-- name: CountTenants :one
SELECT COUNT(*) FROM public.tenants;

-- name: CountActiveTenants :one
SELECT COUNT(*) FROM public.tenants
WHERE is_active = true;
