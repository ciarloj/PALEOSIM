#!/bin/bash
{
set -eo pipefail

fcs=1980-2010
dat=RCMs

nam=$1 #EOBS-010-v25e
obs=iNaturalist
spc=$2 #xylocopa-violacea
[[ $nam = EOBS-010-v25e ]] && dat=OBS
#dep=$2 #optional dependency

if [ $fcs = 1980-2010 ]; then
  yrs=$fcs
  vars="pr tas sfcWind orog"
fi
if [ $nam = EOBS-010-v25e ]; then
  dat=OBS
  vars="pr tas sfcWind orog"
fi
if [ $nam = ECMWF-ERA5_r1i1p1f1_ICTP-RegCM5-0-BATS_CP -o $nam = MPI-M-MPI-ESM1-2-LR_r1i1p1f1_ICTP-RegCM5-0-BATS_CP ]; then
  dat=CPMs
  vars="pr tas sfcWind orog"
  fcs=1995-2004
  yrs=$fcs
fi

nobs=$( cat data/OBS/$obs/${spc}_${obs}.csv | wc -l )
ntrg=5000 # target number of observations (to reach with boot if required)
nboot=$( echo "scale=4; $ntrg / $nobs" | bc ) 
nboot=$( printf "%.0f\n" "$nboot" ) #round
[[ $nboot -lt 1 ]] && nboot=1
nboot=1

am=auto
if [ $am = manual ]; then
  echo "Running script for:"
  echo "  climate data = $nam ($fcs)"
  echo "  species data = $obs"
  echo "  species      = $spc"
  echo "    with nboot = $nboot"
  echo ""
  echo "Select processes to run:"
  echo " - Run $nam indices preparations? [C]"
  echo " - Run $obs PCA ENM processes?    [P]"
  echo " - Run $obs classic ENM processes?[E]"
  read -p "Your selection:" sel
  if [ $sel != "C" -a $sel != "E" -a $sel != "P" ]; then
    echo "Incorrect Selection: $sel - must be C, P, or E"
    exit 1
  fi
else
  sel=E
fi


if [ $sel = C ]; then
  echo "## Running Climate indices..."
  bash main/run_all_indices.sh $nam $dat $yrs $fcs "$vars"
fi

if [ $sel = P ]; then
  echo "## Running PCA Ecological Niche Model..."
  echo "submitting read-and-log..."
  jidrl=$( bash main/submit_read-and-log.sh $nam $obs $spc $dat $fcs "$vars" "$dep" | tail -1 | cut -d' ' -f4 )

  echo "submitting bootstrap..."
  j="boot_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e -d afterok:$jidrl"
  jidb=$( sbatch $slrm main/bootstrapping.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )

  echo "submitting pca..."
  j="pca_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e -d afterok:$jidb"
  jidp=$( eval sbatch $slrm main/pca.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )

  echo "submitting mahalonobis..."
  j="mah_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e -d afterok:$jidp"
  jidl=$( eval sbatch $slrm main/mahalonobis.sh $nam $obs $spc $nboot $dat $fcs )
  
  echo "done."
fi

if [ $sel = E ]; then
  echo "## Running Classic Ecological Niche Model..."
  echo "submitting read-and-log..."
  jidrl=$( bash main/submit_read-and-log.sh $nam $obs $spc $dat $fcs "$vars" "$dep" | tail -1 | cut -d' ' -f4 )

  echo "submitting bootstrap..."
  j="boot_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e -d afterok:$jidrl"
  jidb=$( sbatch $slrm main/bootstrapping.sh $nam $obs $spc $nboot $dat $fcs | cut -d' ' -f4 )

  echo "submitting nor-distance..."
  j="ndis_${spc}_${nam}"
  o=logs/${j}.out
  e=logs/${j}.err
  slrm="-J $j -o $o -e $e -d afterok:$jidb"
  jidl=$( eval sbatch $slrm main/nor-distance.sh $nam $obs $spc $nboot $dat $fcs )

  echo "done."
fi

}
