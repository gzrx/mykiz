-- 003_create_complaints.sql
-- Creates the complaints table for student-submitted facility issues.
-- Status follows a linear progression: submitted -> in_progress -> resolved.

CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES users(id),
    description VARCHAR(1000) NOT NULL,
    location VARCHAR(200) NOT NULL,
    image_key VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'submitted'
        CHECK (status IN ('submitted', 'in_progress', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_complaints_student_id ON complaints(student_id);
CREATE INDEX idx_complaints_status ON complaints(status);
