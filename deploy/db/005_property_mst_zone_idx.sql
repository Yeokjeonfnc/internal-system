BEGIN;

ALTER TABLE property_mst
    ADD COLUMN IF NOT EXISTS zone_idx integer;

COMMENT ON COLUMN property_mst.zone_idx IS '영업지역(sale_zone_mst.zone_idx)';

CREATE INDEX IF NOT EXISTS idx_property_mst_zone_idx
    ON property_mst (zone_idx)
    WHERE zone_idx IS NOT NULL;

COMMIT;
