-- 005_create_bookings.sql
-- Booking & Services module tables: facilities, slot configs, blocked slots,
-- and bookings. Includes booking reference generation function.

CREATE TABLE facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    approval_mode VARCHAR(10) NOT NULL DEFAULT 'auto'
        CHECK (approval_mode IN ('auto', 'manual')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    capacity INT NOT NULL DEFAULT 1 CHECK (capacity > 0),
    grace_before_minutes INT NOT NULL DEFAULT 15
        CHECK (grace_before_minutes BETWEEN 0 AND 60),
    grace_after_minutes INT NOT NULL DEFAULT 30
        CHECK (grace_after_minutes BETWEEN 0 AND 120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE facility_slot_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID NOT NULL REFERENCES facilities(id),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_time_order CHECK (start_time < end_time)
);

CREATE INDEX idx_slot_configs_facility ON facility_slot_configs(facility_id);

CREATE TABLE blocked_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID NOT NULL REFERENCES facilities(id),
    slot_config_id UUID NOT NULL REFERENCES facility_slot_configs(id),
    blocked_date DATE NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_blocked_slot UNIQUE (facility_id, slot_config_id, blocked_date)
);

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_reference VARCHAR(15) NOT NULL UNIQUE,
    student_id UUID NOT NULL REFERENCES users(id),
    facility_id UUID NOT NULL REFERENCES facilities(id),
    slot_config_id UUID NOT NULL REFERENCES facility_slot_configs(id),
    booking_date DATE NOT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'no_show', 'rejected')),
    rejection_reason VARCHAR(255),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookings_student ON bookings(student_id);
CREATE INDEX idx_bookings_facility_date ON bookings(facility_id, booking_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_reference ON bookings(booking_reference);

-- Sequence for booking reference numbers (per-year, reset via function)
CREATE SEQUENCE booking_ref_seq START 1;

-- Function to generate booking reference: KIZ-YYYY-NNNNN
CREATE OR REPLACE FUNCTION next_booking_reference()
RETURNS VARCHAR AS $$
DECLARE
    current_year INT := EXTRACT(YEAR FROM NOW());
    seq_name TEXT := 'booking_ref_seq_' || current_year;
    seq_val INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = seq_name) THEN
        EXECUTE format('CREATE SEQUENCE %I START 1', seq_name);
    END IF;
    EXECUTE format('SELECT nextval(%L)', seq_name) INTO seq_val;
    RETURN 'KIZ-' || current_year || '-' || lpad(seq_val::text, 5, '0');
END;
$$ LANGUAGE plpgsql;
