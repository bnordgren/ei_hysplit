#!/bin/bash

#awk -F, '!($2==0.0 && $3==0.0)' PAR_GIS.txt > PAR_GIS_filtered.txt

#
# This filters out all the points at 0,0 lat,lon. 
# It also reformats and replaces the first field, so that it 
# is a valid timestamp recognized by ogr2ogr.
#
awk -F, 'BEGIN{OFS=FS} 
         ($2==0.0 && $3==0.0){next}
         (NR != 1) {hr = substr($1, 10, 2) ; min = substr($1,13,2); mon = substr($1,2,2) ; day = substr($1, 4, 2) ; year = substr($1, 7, 2) ;
                    $1 = sprintf("20%02d-%02d-%02d %02d:%02d",  year, mon, day, hr, min) ; print ; next }
         (NR == 1) {print}' PAR_GIS.txt > PAR_GIS_filtered.csv

