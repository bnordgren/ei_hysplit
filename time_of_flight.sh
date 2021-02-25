#!/bin/bash

#set this to the name of the table within the postgis database.
table=pardump_parallel_2017_08_17_18_00

if [ $# -ne 1 ] ; then 
    echo Usage $0 "<timestamp>"
    exit -1
fi

target_time=$1
echo $target_time
fix_target_time=`echo "$target_time" | sed 's/[ :]/_/g'`
#echo $fix_target_time


for fire in {1..8} ; do 
    gdal_grid -of GTiff -ot Int16 -txe -119.0150000 -101.9749979 \
                                  -tye 43.3850015 49.4150015 \
                                  -outsize 568 201 \
                                  -zfield page \
                                  -a average:radius1=0.0149:radius2=0.0149:min_points=1:nodata=-1 \
                                  -l $table \
                                  -where "(ts='$target_time'::timestamp) and (ptyp=$fire)" \
                                  PG:"dbname='ei' host='127.0.0.1' user='postgres'" \
                                  tof-parallel/fire${fire}_${fix_target_time}.tif
                                  
done
