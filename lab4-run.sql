\connect dwh

SET search_path TO dwh, public;

CALL etl.load_from_branches();
