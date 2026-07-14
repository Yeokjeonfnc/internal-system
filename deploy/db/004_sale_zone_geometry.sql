BEGIN;

ALTER TABLE sale_zone_mst
    ADD COLUMN IF NOT EXISTS geometry_type varchar(20),
    ADD COLUMN IF NOT EXISTS geometry_data jsonb;

CREATE INDEX IF NOT EXISTS idx_sale_zone_mst_geometry_data
    ON sale_zone_mst USING gin (geometry_data);

COMMENT ON COLUMN sale_zone_mst.geometry_type IS 'POLYGON | CIRCLE';
COMMENT ON COLUMN sale_zone_mst.geometry_data IS '영역 좌표 JSON (paths / center+radius)';

COMMIT;

