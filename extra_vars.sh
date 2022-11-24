#!/bin/bash

# --- Prepare extra vars for bias correction
#---  Conversion table https://confluence.ecmwf.int/pages/viewpage.action?pageId=197702790

#---- units and conversions and set variable names to match worked example
#--------------------------
#---- varname    unit
#---  tas        oK  [example data float]   
#---  tasrange   oK
#---  tasskew    oK
#---  sfcWind    ms-1  
#---  hurs       %
#---  ps         Pa
#---  pr         m --> kgm-2s-1
#---  prsnratio  dim less   [example data float]
#---  rsds       Wm-2 
#---  rlds       Wm-2

#--- KEEP SNOW AND PRECIP IN METERS FOR NOW, TO AVOID MAKING DUPLICATE FILES 
#--- pr should be multiplied by 1000 to convert to kgm-2day-1 (or mmday-1) when extracting lat, lon subregions
#--- 

#hurs,pr,prsnratio,ps,rlds,rsds,sfcWind,tas,tasrange,tasskew \


#for v in ${varName[@]}

#--- https://www.isimip.org/documents/413/ISIMIP3b_bias_adjustment_fact_sheet_Gnsz7CO.pdf


 for y in {1991..1991}
    do

        for m in {01..01}
        do
        
        
        cd "/filepath/ClimateDataLab/era5-land/day/p1deg/" 
        pwd
        
        #--- outputting these extra vars as compressed short precision float (I16) 
        
        #1. Create tasrange = tasmax − tasmin 
        cdo -b F32 -sub tasmax/tasmax_${y}${m}c.nc tasmin/tasmin_${y}${m}c.nc tmp_${y}${m}.nc
        cdo -b I16 -setattribute,tasrange@long_name=Range_Daily_Near-Surface_Air_Temperature -setattribute,tasrange@standard_name=air_temperature_range -setattribute,tasrange@units=K -chname,'tasmax','tasrange' tmp_${y}${m}.nc tasrange/tasrange_${y}${m}.nc
        nccopy -k4 -d5 tasrange/tasrange_${y}${m}.nc tasrange/tasrange_${y}${m}c.nc
        rm tmp_${y}${m}.nc 
        rm tasrange/tasrange_${y}${m}.nc
        echo 'tasrange calculated'
         
        #2. Create tasskew = (tas − tasmin)/(tasmax − tasmin). 
        cdo -b F32 -sub tas/tas_${y}${m}c.nc tasmin/tasmin_${y}${m}c.nc tmp_${y}${m}.nc
        cdo -b F32 -div tmp_${y}${m}.nc tasrange/tasrange_${y}${m}c.nc tasskew/tmp_${y}${m}.nc
        cdo -b I16 setattribute,tasskew@long_name="Range Daily Near-Surface Air Temperature" -setattribute,tasskew@standard_name=air_temperature_range -setattribute,tasskew@units=K -chname,'tas','tasskew' tasskew/tmp_${y}${m}.nc tasskew/tasskew_${y}${m}.nc
        nccopy -k4 -d5 tasskew/tasskew_${y}${m}.nc tasskew/tasskew_${y}${m}c.nc
        rm tmp_${y}${m}.nc
        rm tasskew/tmp_${y}${m}.nc
        rm tasskew/tasskew_${y}${m}.nc
        echo 'tasskew calculated'
        
        #3. Create prsnratio = prsn/pr
        cdo -b F32 -div prsn/prsn_${y}${m}c.nc pr/pr_${y}${m}c.nc tmp_${y}${m}.nc
        cdo -b I16 -setattribute,prsnratio@long_name="Ratio of Snowfall Flux to Total Precipitation" -setattribute,prsnratio@standard_name=snowfall_precipitation_ratio -setattribute,prsnratio@units=1 -chname,'prsn','prsnratio' tmp_${y}${m}.nc prsnratio/prsnratio_${y}${m}.nc
        nccopy -k4 -d5 prsnratio/prsnratio_${y}${m}.nc prsnratio/prsnratio_${y}${m}c.nc
        rm tmp_${y}${m}.nc
        rm prsnratio/prsnratio_${y}${m}.nc
        echo 'prsnratio calculated'
        
done
	
	
done



#--- left over uncompressed. 
        #nccopy -k4 -d5 tasmax/tasmax_${y}${m}.nc tasmax/tasmax_${y}${m}c.nc
        #nccopy -k4 -d5 tasmin/tasmin_${y}${m}.nc tasmin/tasmin_${y}${m}c.nc
        #nccopy -k4 -d5 tas/tas_${y}${m}.nc tas/tas_${y}${m}c.nc
        #nccopy -k4 -d5 prsn/prsn_${y}${m}.nc prsn/prsn_${y}${m}c.nc
        #nccopy -k4 -d5 pr/pr_${y}${m}.nc pr/pr_${y}${m}c.nc
        #echo 'Finished compressing'