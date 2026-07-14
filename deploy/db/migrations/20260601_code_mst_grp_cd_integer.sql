-- code_mst.grp_cd: varchar → integer (앱·매퍼와 타입 일치)
BEGIN;

ALTER TABLE code_mst
    ALTER COLUMN grp_cd TYPE integer USING grp_cd::integer;

COMMIT;
