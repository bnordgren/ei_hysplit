#!/bin/bash

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


for fire in {1..8} ; do 
    r.vect.stats input=$table output=fire${fire}_${fix_target_time} column=page method=mean                                  
done
