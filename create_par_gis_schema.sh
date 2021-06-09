#!/bin/bash

#database=PG:"dbname='ei' host='192.168.59.10' user='postgres'"
database=PG:"dbname='ei' host='192.168.59.39' user='postgres'"

ogr2ogr -oo X_POSSIBLE_NAMES=lon* \
        -oo Y_POSSIBLE_NAMES=lat* \
        -oo KEEP_GEOM_COLUMNS=NO \
        -s_srs epsg:4326 \
        -t_srs 'PROJCS["MODIS Sinusoidal",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],PROJECTION["Sinusoidal"],PARAMETER["false_easting",0.0],PARAMETER["false_northing",0.0],PARAMETER["central_meridian",0.0],PARAMETER["semi_major",6371007.181],PARAMETER["semi_minor",6371007.181],UNIT["m",1.0],AUTHORITY["SR-ORG","6974"]]' \
        -lco SPATIAL_INDEX=NONE \
        -sql "SELECT * FROM par_gis_filtered LIMIT 0" \
        "$database" \
        CSV:PAR_GIS_filtered.csv PAR_GIS_filtered
