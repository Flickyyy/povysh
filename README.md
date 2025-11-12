# Data Warehouse Labs (PostgreSQL)

## Stack Overview
- **Branch sources**: `west_branch`, `east_branch` (Lab 1).
- **Core DWH**: `dwh` database with schema `dwh` (Lab 2).
- **Weekly mart**: schema `dm` living inside the same `dwh` database (Lab 3).
- **ETL**: schema `etl` inside `dwh` содержит процедуру загрузки из филиалов (Lab 4).
- **Container**: `postgres:16-alpine`, configured via `docker/docker-compose.yml`.

## Prerequisites
- Docker Engine + Docker Compose v2.
- Ports `5432` free on the host.

## One-Time Bootstrap
```bash
cd docker
docker compose up --build
```
The init scripts under `docker/initdb` will run automatically:
1. Create databases (`west_branch`, `east_branch`, `dwh`).
2. Apply Lab 1 schema/data (`lab1-create.sql`, `lab1-insert.sql`).
3. Apply Lab 2 schema/data (`lab2-create.sql`, `lab2-insert.sql`).
4. Apply Lab 4 ETL objects and выполнить загрузку (`lab4-create.sql`, `lab4-run.sql`).
5. Apply Lab 3 schema/data (`lab3-create.sql`, `lab3-insert.sql`).

## Working With the Databases
```bash
docker exec -it dwh-postgres psql -U postgres west_branch
```
Change the database name to connect to `east_branch` or `dwh`.

### Refreshing Data
- **Branches**: rerun `\i /workspace/lab1-insert.sql` inside any branch database.
- **DWH**: `CALL etl.load_from_branches();` для дельты или `\i /workspace/lab2-insert.sql` для повторной демонстрации вручную.
- **Mart**: rerun `\i /workspace/lab3-insert.sql` from the `dwh` database (mart objects live in schema `dm`).

All load scripts are idempotent (`ON CONFLICT` / `TRUNCATE`), so repeat executions are safe.

## Documentation
Short reports for each lab live in `docs/` and list the scripts to include in the formal write-up:
- `docs/lab1.md`
- `docs/lab2.md`
- `docs/lab3.md`
- `docs/lab4.md`

## Next Steps
Lab 4 подключает процедуру `etl.load_from_branches`, поэтому последующие работы могут расширять сценарии инкрементальной загрузки или добавлять новые витрины.
