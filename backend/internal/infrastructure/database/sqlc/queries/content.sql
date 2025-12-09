-- Note: These queries use placeholder {SCHEMA} which will be replaced at runtime

-- name: CreateContent :one
INSERT INTO content (
    title,
    slug,
    body,
    status,
    author_id,
    published_at
) VALUES (
    $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: GetContentByID :one
SELECT * FROM content
WHERE id = $1 LIMIT 1;

-- name: GetContentBySlug :one
SELECT * FROM content
WHERE slug = $1 LIMIT 1;

-- name: ListContent :many
SELECT * FROM content
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListContentByStatus :many
SELECT * FROM content
WHERE status = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListContentByAuthor :many
SELECT * FROM content
WHERE author_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: ListPublishedContent :many
SELECT * FROM content
WHERE status = 'published' AND published_at <= NOW()
ORDER BY published_at DESC
LIMIT $1 OFFSET $2;

-- name: UpdateContent :one
UPDATE content
SET
    title = COALESCE(sqlc.narg('title'), title),
    slug = COALESCE(sqlc.narg('slug'), slug),
    body = COALESCE(sqlc.narg('body'), body),
    status = COALESCE(sqlc.narg('status'), status),
    published_at = COALESCE(sqlc.narg('published_at'), published_at)
WHERE id = sqlc.arg('id')
RETURNING *;

-- name: DeleteContent :exec
DELETE FROM content
WHERE id = $1;

-- name: CountContent :one
SELECT COUNT(*) FROM content;

-- name: CountContentByStatus :one
SELECT COUNT(*) FROM content
WHERE status = $1;

-- name: CountContentByAuthor :one
SELECT COUNT(*) FROM content
WHERE author_id = $1;

-- name: SearchContentByTitle :many
SELECT * FROM content
WHERE title ILIKE '%' || $1 || '%'
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;
