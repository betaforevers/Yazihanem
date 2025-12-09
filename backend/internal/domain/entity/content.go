package entity

import (
	"time"
)

// Content represents a content item in the CMS
type Content struct {
	ID          string        `json:"id"`
	TenantID    string        `json:"tenant_id"`
	Title       string        `json:"title"`
	Slug        string        `json:"slug"`
	Body        string        `json:"body"`
	Status      ContentStatus `json:"status"`
	AuthorID    string        `json:"author_id"`
	PublishedAt *time.Time    `json:"published_at,omitempty"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
}

// ContentStatus defines content publication states
type ContentStatus string

const (
	StatusDraft     ContentStatus = "draft"
	StatusPublished ContentStatus = "published"
	StatusArchived  ContentStatus = "archived"
)

// Validate validates content data
func (c *Content) Validate() error {
	if c.Title == "" {
		return ErrInvalidTitle
	}
	if c.Slug == "" {
		return ErrInvalidSlug
	}
	if c.TenantID == "" {
		return ErrInvalidTenantID
	}
	if c.AuthorID == "" {
		return ErrInvalidAuthorID
	}
	if c.Status != StatusDraft && c.Status != StatusPublished && c.Status != StatusArchived {
		return ErrInvalidStatus
	}
	return nil
}
