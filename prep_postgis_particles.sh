#!/bin/bash

table="par_gis_filtered"
host=192.168.59.39

#psql -h $host -U postgres -c "DELETE from $table WHERE wkb_geometry = ST_GeomFromText('POINT(0 0)', 4326)" ei
#psql -h $host -U postgres -c "ALTER TABLE $table ADD COLUMN ts TIMESTAMP" ei
#psql -h $host -U postgres -c "UPDATE $table SET ts=(substring(time,2,11)||'00')::timestamp" ei
psql -h $host -U postgres -c "CREATE INDEX on ${table} USING GIST (wkb_geometry)" ei
psql -h $host -U postgres -c "CREATE INDEX on ${table}(time)" ei
psql -h $host -U postgres -c "CREATE INDEX on ${table}(ptyp)" ei
