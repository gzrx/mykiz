-- 004_create_accommodation.sql
-- Creates accommodation management tables: settings, blocks, rooms, beds,
-- and applications. Supports the full accommodation lifecycle.

-- Key-value settings table (application window toggle)
CREATE TABLE accommodation_settings (
    key VARCHAR(100) PRIMARY KEY,
    value VARCHAR(500) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default setting: applications closed
INSERT INTO accommodation_settings (key, value) VALUES ('applications_open', 'false');

-- Physical structure hierarchy: block -> room -> bed
CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID NOT NULL REFERENCES blocks(id),
    room_number VARCHAR(50) NOT NULL,
    room_type VARCHAR(20) NOT NULL CHECK (room_type IN ('single', 'twin_sharing')),
    UNIQUE(block_id, room_number)
);

CREATE TABLE beds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id),
    bed_label VARCHAR(10) NOT NULL DEFAULT 'A',
    is_occupied BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(room_id, bed_label)
);

-- Application records
CREATE TABLE accommodation_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES users(id),
    application_type VARCHAR(20) NOT NULL
        CHECK (application_type IN ('semester', 'out_of_semester')),
    status VARCHAR(20) NOT NULL DEFAULT 'submitted'
        CHECK (status IN ('submitted', 'approved', 'checked_in', 'checked_out', 'rejected')),
    room_type_preference VARCHAR(20)
        CHECK (room_type_preference IN ('single', 'twin_sharing') OR room_type_preference IS NULL),
    preferred_block_id UUID REFERENCES blocks(id),
    lifestyle_tags TEXT[] DEFAULT '{}',
    check_in_date DATE,
    check_out_date DATE,
    nightly_rate NUMERIC(10,2),
    total_cost NUMERIC(10,2),
    assigned_block_id UUID REFERENCES blocks(id),
    assigned_room_id UUID REFERENCES rooms(id),
    assigned_bed_id UUID REFERENCES beds(id),
    rejection_reason VARCHAR(500),
    window_id VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accom_app_student ON accommodation_applications(student_id);
CREATE INDEX idx_accom_app_status ON accommodation_applications(status);
CREATE INDEX idx_accom_app_type ON accommodation_applications(application_type);
CREATE INDEX idx_accom_app_window ON accommodation_applications(window_id);
CREATE INDEX idx_beds_room ON beds(room_id);
CREATE INDEX idx_rooms_block ON rooms(block_id);
