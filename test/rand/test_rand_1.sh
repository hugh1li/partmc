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

../../test_poisson_sample 1 50 10000000 > out/poisson_1_approx.dat
../../test_poisson_sample 1 50 0        > out/poisson_1_exact.dat
if ! ../../numeric_diff --by col --rel-tol 1e-3 out/poisson_1_exact.dat out/poisson_1_approx.dat &> /dev/null; then
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
