# DB Scripts

This folder keeps database scripts that are shared by deployment environments.

- `001_schema.sql`: normalized table/index definition for a clean database.
- `002_seed_test.sql`: disposable test data for `yj_db_test`.

Use environment-specific folders such as `deploy\test` or `deploy\prod` to decide which database receives these scripts.
