#!/bin/bash

# exit on error
set -e
# turn on command echoing
set -v
# make sure that the current directory is the one where this script is
cd ${0%/*}
# make the output directory if it doesn't exist
mkdir -p out

((counter = 1))
while [ true ]
do
  echo Attempt $counter

../../partmc run_volume_part.spec
../../partmc run_volume_exact.spec

../../extract_aero_time out/loss_part_volume_0001
../../extract_sectional_aero_time out/loss_exact_volume

if ! ../../numeric_diff --by col --rel-tol 0.1 out/loss_exact_volume_aero_time.txt out/loss_part_volume_0001_aero_time.txt &> /dev/null; then
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
