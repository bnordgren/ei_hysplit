#!/bin/bash

database=PG:"dbname='ei' host='127.0.0.1' user='postgres'"

ogr2ogr -oo X_POSSIBLE_NAMES=lon* \
        -oo Y_POSSIBLE_NAMES=lat* \
        -oo KEEP_GEOM_COLUMNS=NO \
        -a_srs epsg:4326 \
        -lco SPATIAL_INDEX=GIST \
        "$database" \
        CSV:PARDUMP-parallel-2017-08-17-18-00.csv PARDUMP-parallel-2017-08-17-18-00
