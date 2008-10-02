#!/usr/bin/env python
# Copyright (C) 2007-2008 Matthew West
# Licensed under the GNU General Public License version 2 or (at your
# option) any later version. See the file COPYING for details.

import os, sys
import copy as module_copy
from Scientific.IO.NetCDF import *
from pyx import *
sys.path.append("../tool")
from pmc_data_nc import *
from pmc_pyx import *

times_hour = [1, 2, 3, 4, 5, 6, 12, 18, 24]

data = pmc_var(NetCDFFile("out/testcase_nococo/urban_plume_state_0001.nc"),
	       "comp_bc",
	       [])
data.write_summary(sys.stdout)

data.reduce([select("unit", "vol_den"),
		 sum("aero_species")])
data.scale_dim("composition", 100)
data.scale_dim("radius", 1e6)
data.scale_dim("time", 1.0/3600)

for i in range(len(times_hour)):
    g = graph.graphxy(
	width = 10,
	x = graph.axis.log(min = 1.e-3,
                           max = 1.e+1,
                           title = r'radius ($\mu$m)',
			   painter = grid_painter),
	y = graph.axis.linear(min = 0,
			      max = 100,
			      title = 'soot volume fraction',
			      texter = graph.axis.texter.decimal(suffix
								 = r"\%"),
			      painter = grid_painter))
    data_slice = module_copy.deepcopy(data)
    data_slice.reduce([select("time", times_hour[i])])
    #min_val = data_slice.data.min()
    #max_val = data_slice.data.max()
    min_val = 0.0
    max_val = 1e-10
    plot_data = data_slice.data_2d_list(strip_zero = True,
					min = min_val,
					max = max_val)
    g.plot(graph.data.list(plot_data,
			   xmin = 1, xmax = 2, ymin = 3, ymax = 4, color = 5),
	   styles = [graph.style.rect(rainbow_palette)])
    add_color_bar(g,
		  min = min_val,
		  max = max_val,
		  title = r"volume density",
		  palette = rainbow_palette)
    g.writePDFfile("out/testcase_nococo/aero_comp_bc_vol_%d.pdf" % times_hour[i])