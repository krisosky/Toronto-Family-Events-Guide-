-- Family Events Guide - first database schema
-- Run ONCE against an empty PostgreSQL database with: psql -v ON_ERROR_STOP=1 -f ...
BEGIN;

CREATE TABLE countries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    iso_code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL
);

CREATE TABLE regions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id BIGINT NOT NULL REFERENCES countries(id),
    name VARCHAR(120) NOT NULL,
    code VARCHAR(20),
    UNIQUE (country_id, name)
);

CREATE TABLE cities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_id BIGINT NOT NULL REFERENCES regions(id),
    name VARCHAR(120) NOT NULL,
    timezone VARCHAR(80) NOT NULL,
    UNIQUE (region_id, name)
);

CREATE TABLE venues (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city_id BIGINT NOT NULL REFERENCES cities(id),
    name VARCHAR(200) NOT NULL,
    street_address TEXT,
    postal_code VARCHAR(20),
    accessibility_info TEXT
);

CREATE TABLE organizers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    website_url TEXT,
    contact_email VARCHAR(254),
    contact_phone VARCHAR(40),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(110) NOT NULL UNIQUE
);

CREATE TABLE events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    organizer_id BIGINT REFERENCES organizers(id) ON DELETE SET NULL,
    venue_id BIGINT REFERENCES venues(id) ON DELETE SET NULL,
    -- For online/TBA events, city still identifies the target area
    city_id BIGINT NOT NULL REFERENCES cities(id),
    title VARCHAR(255) NOT NULL,
    short_description VARCHAR(500),
    description TEXT,
    event_type VARCHAR(100),
    setting VARCHAR(10) NOT NULL DEFAULT 'unknown'
        CHECK (setting IN ('indoor','outdoor','both','unknown')),
    is_free BOOLEAN NOT NULL DEFAULT TRUE,
    price_min NUMERIC(10,2),
    price_max NUMERIC(10,2),
    currency_code CHAR(3) NOT NULL DEFAULT 'CAD',
    minimum_age SMALLINT CHECK (minimum_age BETWEEN 0 AND 120),
    maximum_age SMALLINT CHECK (maximum_age BETWEEN 0 AND 120),
    family_friendly BOOLEAN NOT NULL DEFAULT TRUE,
    official_source_url TEXT,
    ticket_url TEXT,
    image_url TEXT,
    accessibility_info TEXT,
    recurrence_notes TEXT,
    status VARCHAR(25) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft','pending_review','approved','published',
                         'needs_information','rejected','expired')),
    verification_status VARCHAR(20) NOT NULL DEFAULT 'unverified'
        CHECK (verification_status IN ('unverified','verified','failed')),
    last_verified_at TIMESTAMPTZ,
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (minimum_age IS NULL OR maximum_age IS NULL OR minimum_age <= maximum_age),
    CHECK (price_min IS NULL OR price_min >= 0),
    CHECK (price_max IS NULL OR price_max >= 0),
    CHECK (price_min IS NULL OR price_max IS NULL OR price_min <= price_max),
    CHECK (NOT is_free OR (COALESCE(price_min,0) = 0 AND COALESCE(price_max,0) = 0))
);

CREATE TABLE event_categories (
    event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, category_id)
);

CREATE TABLE event_occurrences (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    cancelled BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (ends_at > starts_at),
    UNIQUE (event_id, starts_at)
);

CREATE TABLE event_reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    reviewer_identifier VARCHAR(120) NOT NULL,
    decision VARCHAR(25) NOT NULL CHECK (decision IN (
        'approved','rejected','needs_information','verified','published','unpublished')),
    notes TEXT,
    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE newsletter_subscribers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(120) NOT NULL,
    email VARCHAR(254) NOT NULL,
    city_id BIGINT REFERENCES cities(id),
    brand_id VARCHAR(100),
    gcc_sync_status VARCHAR(15) NOT NULL DEFAULT 'pending'
        CHECK (gcc_sync_status IN ('pending','synced','failed')),
    subscribed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(email, brand_id)
);

CREATE TABLE contact_submissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(254) NOT NULL,
    message TEXT NOT NULL,
    gcc_sync_status VARCHAR(15) NOT NULL DEFAULT 'pending'
        CHECK (gcc_sync_status IN ('pending','synced','failed')),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Helpful indexes for the WordPress/API team's upcoming filter queries.
CREATE INDEX ix_occurrences_active_dates ON event_occurrences(starts_at, ends_at)
    WHERE cancelled = FALSE;
CREATE INDEX ix_occurrences_event ON event_occurrences(event_id);
CREATE INDEX ix_events_status_city ON events(status, city_id);
CREATE INDEX ix_events_organizer ON events(organizer_id);
CREATE INDEX ix_events_venue ON events(venue_id);
CREATE INDEX ix_events_title ON events(title);
CREATE INDEX ix_event_categories_category ON event_categories(category_id, event_id);
CREATE INDEX ix_event_reviews_event_time ON event_reviews(event_id, reviewed_at DESC);
-- Obvious duplicate source links are flagged by the API team's matching logic.
-- Not enforced as unique here because a source can legitimately describe multiple events.

COMMIT;
