#!/bin/bash

# --- interpolate era5-land from 0.1 to 1 degree. 

varName=(hurs  pr prsnratio  ps  rlds  rsds  sfcWind  tas tasrange  tasskew)

#-- set up symbolic link because spaces in file path is a pain
ln -s "/mnt/c/Users/user/OneDrive - bla/ClimateDataLab/" dircdl

for v in ${varName[@]}
do    

 for y in {1991..1991}
    do

        for m in {01..01}
        do
        
        cd cdldir/era5-land/day/p1deg/ 
        pwd

        #cdo remapbil,/projects/AMR_ice_sheet_calculations/ggsrs/cordex/mygrid orog_SAM-44_ECMWF-ERAINT_evaluation_r0i0p0_SMHI-RCA4_v3_fx.nc orog_SAM-44i_ECMWF-ERAINT_evaluation_r0i0p0_SMHI-RCA4_v3_fx.nc
#ncks -O -d lon,$lonMin,$lonMax -d lat,$latMin,$latMax orog_SAM-44i_ECMWF-ERAINT_evaluation_r0i0p0_SMHI-RCA4_v3_fx.nc orog_SAM-44i_ECMWF-ERAINT_evaluation_r0i0p0_SMHI-RCA4_v3_fx_chile.nc


        
       #echo "Change to external hard drive dir"
        #cd $outPath

done	
	
    done
	
        done



