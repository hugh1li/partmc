#!/bin/bash

# exit on error
set -e
# turn on command echoing
set -v
# make sure that the current directory is the one where this script is
cd ${0%/*}

((counter = 1))
while [ true ]
do
  echo Attempt $counter

../../extract_aero_size --mass --dmin 1e-9 --dmax 1e-3 --nbin 160 out/loss_part_volume_0001
../../extract_sectional_aero_size --mass out/loss_exact_volume

if ! ../../numeric_diff --by col --rel-tol 0.3 out/loss_exact_volume_aero_size_mass.txt out/loss_part_volume_0001_aero_size_mass.txt &> /dev/null; then
	  echo Failure "$counter"
	  if [ "$counter" -gt 10 ]
	  then
		  echo FAIL
		  exit 1
	  fi
	  echo retrying...
	  ../../partmc run_constant_part.spec
	  ../../partmc run_constant_exact.spec
  else
	  echo PASS
	  exit 0
  fi
  ((counter++))
done
