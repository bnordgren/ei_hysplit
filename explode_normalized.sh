#!/bin/bash

for fire in {1..8} ; do 
    input_ds="NETCDF:\"cdump1-single-norm.nc\":fir${fire}_norm"
    for time in {1..72} ; do
        outfile=out/fire${fire}_$time.tif
        gdal_translate -a_nodata 0 -of Gtiff -b $time $input_ds $outfile 
    done
done