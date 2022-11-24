#!/bin/bash

# --- download hourly era5-land
#varName=(2m_temperature)
varName=(download)


#cd ${dirName}

for v in ${varName[@]}
do
    #--- step 1. Download global hourly data for a month 
    #outPath=/media/user/ClimateDataLab/era5_land/${v} 
    workPath=/home/user/era5-land/dowork/
     
    for y in {1982..1982}
    do

        for m in {01..12}
        do

        cp template.py temp.py
        sed -i s/'yyyy'/${y}/g temp.py
        sed -i s/'mm'/${m}/g temp.py
        sed -i s/'varname'/${v}/g temp.py
    
        echo ${v}_${y}_${m}.nc 
        python3 temp.py
        
        mv ${v}_${y}${m}.grib $workPath
        
        mv ${workPath}${v}_${y}${m}.grib ${workPath}${v}_${y}${m}_temp.grib 
        
        echo "Moving grib file to dowork and rename"
        
        done
    done
done


