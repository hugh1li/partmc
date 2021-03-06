#!/bin/sh

# exit on error
set -e
# turn on command echoing
set -v

# The data should have already been processed by ./2_process.sh

gnuplot -persist plot_aero_composition_bc.gnuplot
gnuplot -persist plot_aero_size.gnuplot
gnuplot -persist plot_aero_species.gnuplot
gnuplot -persist plot_aero_total.gnuplot
gnuplot -persist plot_env.gnuplot
gnuplot -persist plot_gas.gnuplot
