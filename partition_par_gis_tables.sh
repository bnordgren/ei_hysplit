#!/bin/bash

table="par_gis_filtered"
host=192.168.59.39

psql -h $host -U postgres -c "CREATE TABLE temp (LIKE ${table}) PARTITION BY RANGE (time)" ei
psql -h $host -U postgres -c "DROP TABLE ${table}" ei
psql -h $host -U postgres -c "ALTER TABLE temp RENAME TO ${table}" ei
psql -h $host -U postgres -c "CREATE TABLE ${table}_p1 PARTITION OF ${table} FOR VALUES FROM ('2017-08-25') TO ('2017-08-26')" ei
psql -h $host -U postgres -c "CREATE TABLE ${table}_p2 PARTITION OF ${table} FOR VALUES FROM ('2017-08-26') TO ('2017-08-27')" ei
psql -h $host -U postgres -c "CREATE TABLE ${table}_p3 PARTITION OF ${table} FOR VALUES FROM ('2017-08-27') TO ('2017-08-27 12:00')" ei
psql -h $host -U postgres -c "CREATE TABLE ${table}_p4 PARTITION OF ${table} FOR VALUES FROM ('2017-08-27 12:00') TO ('2017-08-28')" ei
psql -h $host -U postgres -c "CREATE TABLE ${table}_p5 PARTITION OF ${table} FOR VALUES FROM ('2017-08-28') TO ('2017-08-28 12:00')" ei
psql -h $host -U postgres -c "CREATE TABLE ${table}_p6 PARTITION OF ${table} FOR VALUES FROM ('2017-08-28 12:00') TO ('2017-08-29')" ei
