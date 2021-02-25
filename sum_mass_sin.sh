#!/bin/bash
#Script calculates the sum of the mass on all the particles within a 
# grid cell. Since gdal_grid doesn't do that natively, it is necessary to 
# compute the average then the count of pixels in each cell, then multiply

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
    gdal_grid -of GTiff -ot Float32 -txe -8895604.157 -7783653.638 \
                                  -tye 4447802.079 5559752.598 \
                                  -outsize 1200 1200 \
                                  -zfield mass \
                                  -a average:radius1=463:radius2=463:min_points=1:nodata=-1 \
                                  -l $table \
                                  -where "(ts='$target_time'::timestamp) and (ptyp=$fire) and (abs(mass-1./60/70)>0.00000001)" \
                                  PG:"dbname='ei' host='127.0.0.1' user='postgres'" \
                                  mass-parallel-sin/avg${fire}_${fix_target_time}.tif

    gdal_grid -of GTiff -ot Float32 -txe -8895604.157 -7783653.638 \
                                  -tye 4447802.079 5559752.598 \
                                  -outsize 1200 1200 \
                                  -zfield mass \
                                  -a count:radius1=463:radius2=463:min_points=1:nodata=-1 \
                                  -l $table \
                                  -where "(ts='$target_time'::timestamp) and (ptyp=$fire) and (abs(mass-1./60/70)>0.00000001)" \
                                  PG:"dbname='ei' host='127.0.0.1' user='postgres'" \
                                  mass-parallel-sin/count${fire}_${fix_target_time}.tif
                                  
    gdal_calc.py --calc=A*B --outfile mass-parallel-sin/sum${fire}_${fix_target_time}.tif \
                 -A mass-parallel-sin/avg${fire}_${fix_target_time}.tif \
                 -B mass-parallel-sin/count${fire}_${fix_target_time}.tif \
                 --NoDataValue=-1 \
                 --format=GTiff \
                 --type=Float32                                  
done
