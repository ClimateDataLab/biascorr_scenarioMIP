#!/bin/bash

# --- convert hourly era5-land to daily and rename to CF convention var names
#---  Conversion table https://confluence.ecmwf.int/pages/viewpage.action?pageId=197702790

#---- instanteous variables
#--------------------------era5-land ---- cmip -----
#---  24                   2t  		  tas        oK     
#---  24                   10u            ua/sfcWind ms-1  
#---  24                   10v            va         ms-1
#---  24                   2d             -          oK        
#---  24                   sp   	  ps         Pa
#--- accumulated variables
#--- 23-24                tp(m)           pr         kgm-2s-1
#--- 23-24                sf(m)           prsn       kgm-2s-1 
#--- 23-24                ssrd(Js-1)      rsds       Wm-2 
#--- 23-24                strd(Js-1)      rlds       Wm-2

#--- precip and snow have units "m of water equivalent per day" and so they should be multiplied by 1000 to convert to kgm-2day-1 or mmday-1.
#--- radiation fluxes should be divided by 86400 seconds (24 hours) to convert to the commonly used units of Wm-2 and Nm-2, respectively.
#--- KEEP SNOW AND PRECIP IN METERS FOR NOW
#--- All output netcdf files are netCDF4_classic
#--- Lange et al., 2021 fact sheet file:///home/user/Downloads/ISIMIP3b_bias_adjustment_fact_sheet_Gnsz7CO.pdf
  
outPath=/media/user/ClimateDataLab/era5_land/day/
 	
underStairs=/mnt/climatedatalab/era5-land/day/      

 for y in {1993..1993}
    do

        for m in {01..01}
        do
        
        echo "Change to external hard drive dir"
        cd $outPath

	#--- convert to netcdf using compression
        #---- k is netcdf4, deflate value 5 is recommended, -s shuffle data before compression     
	grib_to_netcdf -D NC_SHORT -k 4 -d 5 -o download_${y}${m}.nc download_${y}${m}_temp.grib
	
	#---instantenous data first ---------------------------------------
        
        echo "Calculate daily temperature"
	cdo daymin -selvar,tasmin -chname,'t2m','tasmin' download_${y}${m}.nc tasmin/tasmin_${y}${m}.nc 
	cdo daymax -selvar,tasmax -chname,'t2m','tasmax' download_${y}${m}.nc tasmax/tasmax_${y}${m}.nc 
	cdo daymean -selvar,tas -chname,'t2m','tas' download_${y}${m}.nc tas/tas_${y}${m}.nc 
	
	echo "Calculate daily relative humidity from dew point temperature"
	#Wright 1997, https://zenodo.org/record/6344066
	cdo daymean -selvar,d2m download_${y}${m}.nc d2m/d2m_${y}${m}.nc 
	
        ncks -A tas/tas_${y}${m}.nc d2m/d2m_${y}${m}.nc  
        cdo -expr,'rh=100*(611.21*exp(17.502*d2m/(240.97+d2m)))/(611.21*exp(17.502*tas/(240.97+tas)))' d2m/d2m_${y}${m}.nc rh_${y}${m}.nc
        cdo -setattribute,hurs@standard_name=relative_humidity -setattribute,hurs@units=% -chname,'rh','hurs' rh_${y}${m}.nc hurs/hurs_${y}${m}.nc
        rm rh_${y}${m}nc d2m/d2m_${y}${m}.nc 
        
        echo "Calculate and keep daily dew point temperature"
	cdo daymean -selvar,d2m download_${y}${m}.nc d2m/d2m_${y}${m}.nc 
        
        echo "Calculate daily pressure"
        cdo daymean -selvar,sp download_${y}${m}.nc sp_${y}${m}.nc
        cdo chname,'sp','ps' sp_${y}${m}.nc ps/ps_${y}${m}.nc
        rm sp_${y}${m}.nc 
        
        echo "Calculate daily mean wind speed"
        cdo daymean -selvar,u10 download_${y}${m}.nc u10_${y}${m}.nc 
        cdo daymean -selvar,v10 download_${y}${m}.nc v10_${y}${m}.nc 
        
	cdo -b F32 sqrt -add -sqr u10_${y}${m}.nc -sqr v10_${y}${m}.nc uv10_${y}${m}.nc 
	cdo chname,'u10','sfcWind' uv10_${y}${m}.nc sfcWind/sfcWind_${y}${m}.nc 
	rm uv10_${y}${m}.nc u10_${y}${m}.nc v10_${y}${m}.nc 

	#--- accumulated variables --------------------------------------
	
	echo "Calculate daily accum precip"
	#--- select data at timestep 00:00
	cdo -selhour,0 -selvar,tp download_${y}${m}.nc tp_${y}${m}.nc	
	#--- data at time step 00:00 is the accum values for the previous days
	cdo -shifttime,-1day -chname,'tp','pr' tp_${y}${m}.nc pr/pr_${y}${m}.nc
	rm tp_${y}${m}.nc
	
	echo "Calculate daily shortwave radiation"
	#--- select data at timestep 00:00
	cdo -selhour,0 -selvar,ssrd download_${y}${m}.nc ssrd_${y}${m}.nc	
	#--- convert jm-2 to Wm-2 
	cdo -b F32 -shifttime,-1day -divc,86400 -chname,'ssrd','rsds' -setattribute,ssrd@units=W/m2 ssrd_${y}${m}.nc rsds/rsds_${y}${m}.nc
	rm ssrd_${y}${m}.nc
	
	echo "Calculate daily longwave radiation"
	#--- select data at timestep 00:00
	cdo -selhour,0 -selvar,strd download_${y}${m}.nc strd_${y}${m}.nc	
	#--- convert jm-2 to Wm-2 
	cdo -b F32 -shifttime,-1day -divc,86400 -chname,'strd','rlds' -setattribute,strd@units=W/m2 strd_${y}${m}.nc rlds/rlds_${y}${m}.nc
	rm strd_${y}${m}.nc
	
	echo "Calculate accum snowfall"
	#--- select data at timestep 00:00
	cdo -selhour,0 -selvar,sf download_${y}${m}.nc sf_${y}${m}.nc	
	cdo -chname,'sf','prsn' -shifttime,-1day sf_${y}${m}.nc prsn/prsn_${y}${m}.nc
	rm sf_${y}${m}.nc
	
	echo "Compress using nccopy to dir on external hard disk"
        #--- quick and hacky - come back and loop through variable list
	nccopy -k4 -d5 tasmin/tasmin_${y}${m}.nc tasmin/tasmin_${y}${m}c.nc
	nccopy -k4 -d5 tasmax/tasmax_${y}${m}.nc tasmax/tasmax_${y}${m}c.nc
	nccopy -k4 -d5 tas/tas_${y}${m}.nc tas/tas_${y}${m}c.nc	
	nccopy -k4 -d5 d2m/d2m_${y}${m}.nc d2m/d2m_${y}${m}c.nc
	nccopy -k4 -d5 ps/ps_${y}${m}.nc ps/ps_${y}${m}c.nc
	nccopy -k4 -d5 pr/pr_${y}${m}.nc pr/pr_${y}${m}c.nc
	nccopy -k4 -d5 prsn/prsn_${y}${m}.nc prsn/prsn_${y}${m}c.nc
	nccopy -k4 -d5 hurs/hurs_${y}${m}.nc hurs/hurs_${y}${m}c.nc
	nccopy -k4 -d5 sfcWind/sfcWind_${y}${m}.nc sfcWind/sfcWind_${y}${m}c.nc
	nccopy -k4 -d5 rsds/rsds_${y}${m}.nc rsds/rsds_${y}${m}c.nc
	nccopy -k4 -d5 rlds/rlds_${y}${m}.nc rlds/rlds_${y}${m}c.nc
	
		
	echo "copy to understairs"
        cp --preserve=timestamps tasmin/tasmin_${y}${m}c.nc $underStairs/tasmin/tasmin_${y}${m}c.nc
        cp --preserve=timestamps tasmax/tasmax_${y}${m}c.nc $underStairs/tasmax/tasmax_${y}${m}c.nc
        cp --preserve=timestamps tas/tas_${y}${m}c.nc $underStairs/tas/tas_${y}${m}c.nc
        cp --preserve=timestamps d2m/d2m_${y}${m}c.nc $underStairs/d2m/d2m_${y}${m}c.nc
        cp --preserve=timestamps ps/ps_${y}${m}c.nc $underStairs/ps/ps_${y}${m}c.nc
        cp --preserve=timestamps pr/pr_${y}${m}c.nc $underStairs/pr/pr_${y}${m}c.nc
        cp --preserve=timestamps prsn/prsn_${y}${m}c.nc $underStairs/prsn/prsn_${y}${m}c.nc
        cp --preserve=timestamps hurs/hurs_${y}${m}c.nc $underStairs/hurs/hurs_${y}${m}c.nc
        cp --preserve=timestamps sfcWind/sfcWind_${y}${m}c.nc $underStairs/sfcWind/sfcWind_${y}${m}c.nc
        cp --preserve=timestamps rsds/rsds_${y}${m}c.nc $underStairs/rsds/rsds_${y}${m}c.nc
        cp --preserve=timestamps rlds/rlds_${y}${m}c.nc $underStairs/rlds/rlds_${y}${m}c.nc
	
	echo "Delete uncompressed daily files"
	rm tasmin/tasmin_${y}${m}.nc 
	rm tasmax/tasmax_${y}${m}.nc 
	rm tas/tas_${y}${m}.nc 
	rm d2m/d2m_${y}${m}.nc 
	rm ps/ps_${y}${m}.nc 
	rm pr/pr_${y}${m}.nc 
	rm prsn/prsn_${y}${m}.nc
	rm hurs/hurs_${y}${m}.nc 
	rm sfcWind/sfcWind_${y}${m}.nc
	rm rsds/rsds_${y}${m}.nc 
	rm rlds/rlds_${y}${m}.nc 
	
	
        echo "Deleting hourly grib file"
 	rm download_${y}${m}_temp.grib
        rm download_${y}${m}.nc 
        
        
done
	#--- create an annual file
	#--- too big to read into matlab as annual even with nc_short
	#cdo mergetime pr_${y}$*.nc pr_$yr.nc
	#cdo mergetime tas_${y}$*.nc tas_$yr.nc
	#cdo mergetime tasmin_${y}$*.nc tasmin_$yr.nc
	#cdo mergetime tasmax_${y}$*.nc tasmax_$yr.nc
	
done



