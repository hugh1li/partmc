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

../../extract_aero_time out/condense_0001

if ! ../../numeric_diff --min-col 23 --max-col 23 --rel-tol 0.05 ref_condense_0001_aero_time.txt out/condense_0001_aero_time.txt &> /dev/null; then
	  echo Failure "$counter"
	  if [ "$counter" -gt 10 ]
	  then
		  echo FAIL
		  exit 1
	  fi
	  echo retrying...
  else
	  echo PASS
	  exit 0
  fi
  ((counter++))
done
