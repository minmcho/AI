-- ============================================================
-- CargoTrack Platform — Core Schema
-- pgvector enabled for AI-powered similarity search
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- ── Organisational hierarchy ─────────────────────────────────

CREATE TABLE departments (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    code        TEXT NOT NULL UNIQUE,
    parent_id   UUID REFERENCES departments(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE regions (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    code        TEXT NOT NULL UNIQUE,
    country     TEXT NOT NULL,
    timezone    TEXT NOT NULL DEFAULT 'UTC',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE locations (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          TEXT NOT NULL,
    code          TEXT NOT NULL UNIQUE,
    region_id     UUID NOT NULL REFERENCES regions(id),
    department_id UUID REFERENCES departments(id),
    address       TEXT,
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    location_type TEXT NOT NULL CHECK (location_type IN ('warehouse','port','depot','hub','terminal','custom')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE units (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          TEXT NOT NULL,
    code          TEXT NOT NULL UNIQUE,
    unit_type     TEXT NOT NULL CHECK (unit_type IN ('container','pallet','box','crate','drum','bag','vehicle','other')),
    tare_kg       NUMERIC(10,2),
    max_load_kg   NUMERIC(10,2),
    volume_m3     NUMERIC(10,3),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Cargo & Shipment ─────────────────────────────────────────

CREATE TABLE shipments (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_number  TEXT NOT NULL UNIQUE,
    status           TEXT NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('pending','in_transit','at_customs','arrived','delivered','exception','cancelled')),
    priority         TEXT NOT NULL DEFAULT 'standard'
                         CHECK (priority IN ('low','standard','high','critical')),
    origin_id        UUID NOT NULL REFERENCES locations(id),
    destination_id   UUID NOT NULL REFERENCES locations(id),
    department_id    UUID REFERENCES departments(id),
    carrier          TEXT,
    service_type     TEXT,
    estimated_arrival TIMESTAMPTZ,
    actual_arrival   TIMESTAMPTZ,
    total_weight_kg  NUMERIC(12,3),
    total_volume_m3  NUMERIC(12,3),
    notes            TEXT,
    metadata         JSONB DEFAULT '{}',
    -- pgvector: semantic embedding of shipment description+history
    embedding        VECTOR(1536),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cargo_items (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id    UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    unit_id        UUID REFERENCES units(id),
    sku            TEXT,
    description    TEXT NOT NULL,
    quantity       INTEGER NOT NULL DEFAULT 1,
    weight_kg      NUMERIC(10,3),
    volume_m3      NUMERIC(10,3),
    value_usd      NUMERIC(14,2),
    hs_code        TEXT,                 -- Harmonised System tariff code
    hazmat_class   TEXT,
    temperature_min_c NUMERIC(5,1),
    temperature_max_c NUMERIC(5,1),
    -- ML classification outputs
    category       TEXT,
    sub_category   TEXT,
    cluster_id     INTEGER,
    defect_score   NUMERIC(4,3),        -- 0.000–1.000 defect probability
    -- pgvector: item embedding for clustering/similarity
    embedding      VECTOR(1536),
    metadata       JSONB DEFAULT '{}',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Tracking events (append-only ledger) ────────────────────

CREATE TABLE tracking_events (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id   UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    event_type    TEXT NOT NULL
                      CHECK (event_type IN (
                          'created','pickup','departed','in_transit','arrived',
                          'customs_hold','customs_cleared','out_for_delivery',
                          'delivered','exception','returned','status_update'
                      )),
    location_id   UUID REFERENCES locations(id),
    location_name TEXT,                 -- free-text for external scan points
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    description   TEXT,
    occurred_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    operator_id   UUID,
    metadata      JSONB DEFAULT '{}'
);

-- ── Inventory ────────────────────────────────────────────────

CREATE TABLE inventory (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id    UUID NOT NULL REFERENCES locations(id),
    department_id  UUID REFERENCES departments(id),
    sku            TEXT NOT NULL,
    description    TEXT,
    quantity       INTEGER NOT NULL DEFAULT 0,
    unit_id        UUID REFERENCES units(id),
    reorder_point  INTEGER,
    max_stock      INTEGER,
    bin_location   TEXT,               -- shelf/aisle/rack
    -- AI classification
    category       TEXT,
    sub_category   TEXT,
    cluster_id     INTEGER,
    embedding      VECTOR(1536),
    last_counted_at TIMESTAMPTZ,
    metadata       JSONB DEFAULT '{}',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (location_id, sku)
);

CREATE TABLE inventory_movements (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id    UUID NOT NULL REFERENCES inventory(id),
    movement_type   TEXT NOT NULL
                        CHECK (movement_type IN ('inbound','outbound','transfer','adjustment','count')),
    quantity_delta  INTEGER NOT NULL,
    quantity_after  INTEGER NOT NULL,
    reference_id    UUID,               -- shipment_id or transfer_id
    notes           TEXT,
    operator_id     UUID,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Defect detection ─────────────────────────────────────────

CREATE TABLE defect_detections (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- link to either a cargo item or inventory item
    cargo_item_id   UUID REFERENCES cargo_items(id),
    inventory_id    UUID REFERENCES inventory(id),
    location_id     UUID REFERENCES locations(id),
    image_url       TEXT,
    defect_type     TEXT,               -- 'damage','contamination','mislabel','missing','other'
    severity        TEXT CHECK (severity IN ('low','medium','high','critical')),
    confidence      NUMERIC(4,3),       -- model confidence 0.000–1.000
    bounding_boxes  JSONB DEFAULT '[]', -- [{x,y,w,h,label,score}]
    model_version   TEXT,
    raw_output      JSONB DEFAULT '{}',
    -- Claude reasoning (cached)
    reasoning       TEXT,
    action_taken    TEXT,
    resolved_at     TIMESTAMPTZ,
    operator_id     UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── ML clustering snapshots ──────────────────────────────────

CREATE TABLE clustering_runs (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_type        TEXT NOT NULL CHECK (run_type IN ('cargo','inventory','defect')),
    algorithm       TEXT NOT NULL,      -- 'hdbscan','kmeans','dbscan'
    num_clusters    INTEGER,
    parameters      JSONB DEFAULT '{}',
    cluster_labels  JSONB DEFAULT '[]', -- [{cluster_id, name, size, centroid_sample}]
    silhouette_score NUMERIC(5,4),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Reasoning cache (Claude prompt caching) ──────────────────

CREATE TABLE reasoning_cache (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key     TEXT NOT NULL UNIQUE,  -- hash of (model+system_prompt+query_type)
    query_type    TEXT NOT NULL,
    system_prompt TEXT NOT NULL,
    model         TEXT NOT NULL DEFAULT 'claude-opus-4-6',
    usage_count   INTEGER NOT NULL DEFAULT 0,
    last_used_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Alerts & notifications ───────────────────────────────────

CREATE TABLE alerts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type    TEXT NOT NULL
                      CHECK (alert_type IN (
                          'delay','exception','defect','low_stock',
                          'temperature_breach','customs_hold','system'
                      )),
    severity      TEXT NOT NULL CHECK (severity IN ('info','warning','error','critical')),
    title         TEXT NOT NULL,
    message       TEXT NOT NULL,
    entity_type   TEXT,                 -- 'shipment','cargo_item','inventory'
    entity_id     UUID,
    location_id   UUID REFERENCES locations(id),
    department_id UUID REFERENCES departments(id),
    acknowledged  BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by UUID,
    acknowledged_at TIMESTAMPTZ,
    metadata      JSONB DEFAULT '{}',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Indexes ──────────────────────────────────────────────────

-- Shipments
CREATE INDEX idx_shipments_tracking    ON shipments(tracking_number);
CREATE INDEX idx_shipments_status      ON shipments(status);
CREATE INDEX idx_shipments_created     ON shipments(created_at DESC);
CREATE INDEX idx_shipments_origin      ON shipments(origin_id);
CREATE INDEX idx_shipments_destination ON shipments(destination_id);
CREATE INDEX idx_shipments_department  ON shipments(department_id);

-- pgvector HNSW indexes for fast ANN search
CREATE INDEX idx_shipments_embedding   ON shipments USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_cargo_embedding       ON cargo_items USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_inventory_embedding   ON inventory USING hnsw (embedding vector_cosine_ops);

-- Tracking events
CREATE INDEX idx_tracking_shipment     ON tracking_events(shipment_id, occurred_at DESC);
CREATE INDEX idx_tracking_location     ON tracking_events(location_id);

-- Inventory
CREATE INDEX idx_inventory_location    ON inventory(location_id);
CREATE INDEX idx_inventory_sku         ON inventory(sku);
CREATE INDEX idx_inventory_cluster     ON inventory(cluster_id);

-- Cargo items
CREATE INDEX idx_cargo_shipment        ON cargo_items(shipment_id);
CREATE INDEX idx_cargo_cluster         ON cargo_items(cluster_id);
CREATE INDEX idx_cargo_defect          ON cargo_items(defect_score);

-- Alerts
CREATE INDEX idx_alerts_entity         ON alerts(entity_type, entity_id);
CREATE INDEX idx_alerts_unacked        ON alerts(acknowledged, created_at DESC);
CREATE INDEX idx_alerts_department     ON alerts(department_id);

-- Reasoning cache
CREATE INDEX idx_reasoning_cache_key   ON reasoning_cache(cache_key);

-- ── Seed data ────────────────────────────────────────────────

INSERT INTO departments (name, code) VALUES
    ('Operations',       'OPS'),
    ('Customs',          'CUS'),
    ('Quality Control',  'QC'),
    ('Logistics',        'LOG'),
    ('Procurement',      'PROC');

INSERT INTO regions (name, code, country, timezone) VALUES
    ('North America East',  'NAE', 'US', 'America/New_York'),
    ('North America West',  'NAW', 'US', 'America/Los_Angeles'),
    ('Europe West',         'EUW', 'DE', 'Europe/Berlin'),
    ('Asia Pacific',        'APAC','SG', 'Asia/Singapore'),
    ('Middle East',         'ME',  'AE', 'Asia/Dubai');

INSERT INTO locations (name, code, region_id, location_type) VALUES
    ('New York Hub',      'NYC-HUB',  (SELECT id FROM regions WHERE code='NAE'), 'hub'),
    ('Los Angeles Port',  'LAX-PORT', (SELECT id FROM regions WHERE code='NAW'), 'port'),
    ('Hamburg Terminal',  'HAM-TERM', (SELECT id FROM regions WHERE code='EUW'), 'terminal'),
    ('Singapore Depot',   'SIN-DEP',  (SELECT id FROM regions WHERE code='APAC'),'depot'),
    ('Dubai Warehouse',   'DXB-WH',   (SELECT id FROM regions WHERE code='ME'),  'warehouse');

INSERT INTO units (name, code, unit_type, tare_kg, max_load_kg, volume_m3) VALUES
    ('20ft Container',  'CONT-20', 'container', 2200, 28000, 33.2),
    ('40ft Container',  'CONT-40', 'container', 3900, 26000, 67.6),
    ('Euro Pallet',     'PALL-EU', 'pallet',      25,  1500,  1.5),
    ('Standard Box',    'BOX-STD', 'box',          2,    50, 0.12),
    ('Drum 200L',       'DRUM-200','drum',         20,   250, 0.20);

-- ── Helper function: semantic item search ────────────────────

CREATE OR REPLACE FUNCTION search_cargo_items(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count     INT   DEFAULT 20
)
RETURNS TABLE (
    id          UUID,
    description TEXT,
    sku         TEXT,
    shipment_id UUID,
    category    TEXT,
    cluster_id  INTEGER,
    similarity  FLOAT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        ci.id,
        ci.description,
        ci.sku,
        ci.shipment_id,
        ci.category,
        ci.cluster_id,
        1 - (ci.embedding <=> query_embedding) AS similarity
    FROM cargo_items ci
    WHERE ci.embedding IS NOT NULL
      AND 1 - (ci.embedding <=> query_embedding) >= match_threshold
    ORDER BY ci.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

CREATE OR REPLACE FUNCTION search_inventory(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count     INT   DEFAULT 20
)
RETURNS TABLE (
    id          UUID,
    description TEXT,
    sku         TEXT,
    location_id UUID,
    category    TEXT,
    cluster_id  INTEGER,
    similarity  FLOAT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        inv.id,
        inv.description,
        inv.sku,
        inv.location_id,
        inv.category,
        inv.cluster_id,
        1 - (inv.embedding <=> query_embedding) AS similarity
    FROM inventory inv
    WHERE inv.embedding IS NOT NULL
      AND 1 - (inv.embedding <=> query_embedding) >= match_threshold
    ORDER BY inv.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
