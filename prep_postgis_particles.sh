#!/bin/bash

table="pardump_parallel_2017_08_17_18_00"

psql -h 127.0.0.1 -U postgres -c "DELETE from $table WHERE wkb_geometry = ST_GeomFromText('POINT(0 0)', 4326)" ei
psql -h 127.0.0.1 -U postgres -c "ALTER TABLE $table ADD COLUMN ts TIMESTAMP" ei
psql -h 127.0.0.1 -U postgres -c "UPDATE $table SET ts=(substring(time,2,11)||'00')::timestamp" ei
psql -h 127.0.0.1 -U postgres -c "CREATE INDEX on ${table}(ts)" ei
psql -h 127.0.0.1 -U postgres -c "CREATE INDEX on ${table}(ptyp)" ei
