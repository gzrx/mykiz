-- 002_create_announcements.sql
-- Creates the announcements table for admin-published content.
-- Supports soft-delete via is_deleted flag.

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL CHECK (char_length(body) <= 5000),
    author_id UUID NOT NULL REFERENCES users(id),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_announcements_is_deleted ON announcements(is_deleted);
