#!/bin/bash
#Script calculates the sum of the mass on all the particles within a 
# grid cell. Since gdal_grid doesn't do that natively, it is necessary to 
# compute the average then the count of pixels in each cell, then multiply

#set this to the name of the table within the postgis database.
table="pardump_parallel_2017_08_17_18_00"

if [ $# -ne 1 ] ; then 
    echo Usage $0 "<timestamp>"
    exit -1
fi

target_time=$1
echo $target_time
fix_target_time=`echo "$target_time" | sed 's/[ :]/_/g'`
#echo $fix_target_time

#g.mapset -c mapset=mass-parallel-sin

for fire in {1..8} ; do 
    v.out.ascii input=$table output=temp.csv --overwrite \
	    where="(ts='$target_time') and (ptyp=$fire) and (abs(mass-1./60/70)>0.00000001)" \
	    type=point format=point columns=mass,page
    r.in.xyz input=temp.csv output=total_mass${fire}_${fix_target_time} method=sum value_column=4 --overwrite
    r.in.xyz input=temp.csv output=mean_age${fire}_${fix_target_time} method=mean value_column=5 --overwrite
    rm temp.csv
done
