#!/bin/bash

# Predefine the file locations.
basedir=/data/ei_eval_21
hysplit_basedir=$basedir/hysplit
mcd19a2_basedir=$basedir/sat/aot/mosaics

# For simplicity, we take in the MODIS filename 
mcd19a2_file=$1

# Calculate the hysplit file name corresponding to the same timestamp 
# as the provided mcd19a2 filename. Caller also provides whether the 
# desired hysplit file is "mass" or "age".
# $1 = mcd19a2 file
# $2 = "mass" or "age"
# Function prints the hysplit filename to stdout. Use command substitution to
# assign to a variable..
function hysplit_name {
   local mcd19a2_stem=`basename $1 .tif`
   local month=`echo $mcd19a2_stem | cut -c 14-15`
   local day=`echo $mcd19a2_stem | cut -c 17-18`
   local hour=`echo $mcd19a2_stem | cut -c 20-23`

   echo -n "hysplit_"$2"_2017-"${month}-${day}_${hour}00.tif
}
 
# Calculate the clipped mcd19a2 filename given the original.
# $1= mcd19a2 file
# Function echoes the filename to stdout. Use command substitution to 
# assign to a variable. 
function clipped_aot_file {
   local mcd19a2_stem=`basename $1 .tif`
   echo -n ${mcd19a2_stem}_clip.tif
}

# Calculate the mcd19a2 mass filename given the original.
# $1= mcd19a2 file
# Function echoes the filename to stdout. Use command substitution to 
# assign to a variable. 
function aot_mass_file {
   local mcd19a2_stem=`basename $1 .tif`
   echo -n ${mcd19a2_stem}_mass.tif
}

# Calculate the masked hysplit filename given the original.
# $1= hysplit file
# Function echoes the filename to stdout. Use command substitution to 
# assign to a variable. 
function hysplit_mask_file {
   local hysplit_stem=`basename $1 .tif`
   echo -n ${hysplit_stem}_mask.tif
}

# Warp the MCD19A2 scene to the projection of the HYSPLIT data
# while at the same time clipping to the extent of the HYSPLIT
# scene and ensuring that the pixel size is exactly the same. 
# $1 = full path to mcd19a2 file
# $2 = full path to hysplit file
function co_register {
   #capture the spatial reference system in a temporary file
   gdalsrsinfo $2 > hysplit_srs.wkt

   #fetch the pixel size from gdalinfo
   local size=`gdalinfo -json $2 | \
           python -c "import json; import sys; \
                      info = json.load(sys.stdin) ; \
                      print(' '.join([str(x) for x in info['size']]))"`


   # fetch the extent from gdalinfo
   local extent=`gdalinfo -json $2 | \
           python -c "import json; import sys; \
                      info = json.load(sys.stdin) ; \
                      print(' '.join([str(x) for x in info['cornerCoordinates']['lowerLeft']])+' '+ \
                            ' '.join([str(x) for x in info['cornerCoordinates']['upperRight']]))"`

   local clipped_file=`clipped_aot_file $1`
   gdalwarp -t_srs hysplit_srs.wkt -ts $size -te $extent -r cubic \
            $1 $mcd19a2_basedir/$clipped_file

}

# function masks the hysplit file against the nodata values in the clipped modis 
# data product. This will only work if both the files have pixels exactly the same size and
# cover exactly the same region on the ground in exactly the same projection.
# $1 = full path to the clipped mcd19a2 file
# $2 = full path to the hysplit file
function mask_hysplit {
   local hysplit_file=$2
   local mcd19a2_file=$1
   local hysplit_mask=$hysplit_basedir/$(hysplit_mask_file $hysplit_file)

   gdal_calc.py -A $hysplit_file -B $mcd19a2_file --calc="where(B==0,0,A)" --outfile=$hysplit_mask --overwrite
}

# function calculates aod-derived mass from modis data product. 
# note that it's expecting to be used far away from the source, so there's no background 
# subtraction...
# $1 = full path to the clipped mcd19a2 file
function calc_mass {
   local mcd19a2_file=$1
   local mass_file=$mcd19a2_basedir/$(aot_mass_file $mcd19a2_file)

   local pix_sz=`gdalinfo -json $mcd19a2_file | \
                 python -c "import json ; import sys ; \
                            x = json.load(sys.stdin) ; \
                            print(' '.join((str(x['geoTransform'][1]),str(x['geoTransform'][5]))))"`
   local x_sz=`echo $pix_sz | cut  -d' ' -f1` 
   local y_sz=`echo $pix_sz | cut  -d' ' -f2`
   local scale=`gdalinfo -json $mcd19a2_file | \
                python -c "import json ; import sys ; \
                           x = json.load(sys.stdin) ; \
                           print(x['bands'][0]['scale'])"`

   gdal_calc.py -A $mcd19a2_file --calc="($x_sz * $y_sz) * $scale * A / 4.6" \
                --outfile=$mass_file --type=Float32
   gdal_edit.py -units "g" $mass_file 
}

# function aggregates pixels by a specified factor in both the 
# x and y directions, to create regions for comparison.  The 
# pixel values in the resultant raster are the sum of all the 
# contributing pixels in the source raster.
# $1=full path to the file to aggregate
# $2=factor by which the resolution is reduced
function aggregate {
   local infile=$1
   local factor=$2
   local directory=`dirname $infile`
   local outfile=$directory/`basename $infile .tif`_$factor.tif

   #fetch the pixel size from gdalinfo
   local size=`gdalinfo -json $infile | \
           python -c "import json; import sys; \
                      info = json.load(sys.stdin) ; \
                      print(' '.join([str(x) for x in info['size']]))"`
   local xs=`echo $size | cut -d" " -f1`
   local ys=`echo $size | cut -d" " -f2`
   xs=$((xs/factor))
   ys=$((ys/factor))

   gdalwarp -ts $xs $ys -r sum $infile $outfile
}

# get the corresponding hysplit scene name
hysplit_file=$hysplit_basedir/$(hysplit_name $mcd19a2_file mass)

#clip the satellite scene to the hysplit window
co_register $mcd19a2_file $hysplit_file
mcd19a2_clip=$mcd19a2_basedir/$(clipped_aot_file $mcd19a2_file)

#mask hysplit data based on modis "missing data"
mask_hysplit $mcd19a2_clip $hysplit_file
hysplit_mask=$hysplit_basedir/$(hysplit_mask_file $hysplit_file)

#calculate mass value from AOD
calc_mass $mcd19a2_clip
mcd19a2_mass=$mcd19a2_basedir/$(aot_mass_file $mcd19a2_clip)

#aggregate the final hysplit and aot files
aggregate $mcd19a2_mass 10
aggregate $hysplit_mask 10
