#!/bin/bash

#set this to the name of the table within the postgis database.
table="pardump_parallel_2017_08_17_18_00(sin_geom)"

if [ $# -ne 1 ] ; then 
    echo Usage $0 "<timestamp>"
    exit -1
fi

target_time=$1
echo $target_time
fix_target_time=`echo "$target_time" | sed 's/[ :]/_/g'`
#echo $fix_target_time


for fire in {1..8} ; do 
    gdal_grid -of GTiff -ot Int16 -txe -8895604.157 -7783653.638 \
                                  -tye 4447802.079 5559752.598 \
                                  -outsize 1200 1200 \
                                  -zfield page \
                                  -a average:radius1=463:radius2=463:min_points=1:nodata=-1 \
                                  -l $table \
                                  -where "(ts='$target_time'::timestamp) and (ptyp=$fire) and (abs(mass-1./60/70)>0.00000001)" \
                                  PG:"dbname='ei' host='127.0.0.1' user='postgres'" \
                                  tof-parallel-sin/fire${fire}_${fix_target_time}.tif
                                  
done
