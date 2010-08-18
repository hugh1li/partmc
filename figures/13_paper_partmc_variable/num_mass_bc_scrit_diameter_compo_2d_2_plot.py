#!/usr/bin/env python2.5

import os, sys
import config
import scipy.io
import numpy as np

sys.path.append("../../tool")
import partmc
import mpl_helper
import matplotlib

x_array_bc = np.loadtxt("data/2d_bc_compo_12_x_values.txt") * 1e6
y_array_bc = np.loadtxt("data/2d_bc_compo_12_y_values.txt") * 100

x_array_scrit = np.loadtxt("data/2d_scrit_compo_12_x_values.txt") * 1e6
y_array_scrit = np.loadtxt("data/2d_scrit_compo_12_y_values.txt") 

num_bc = np.loadtxt("data/2d_bc_compo_12_average_num.txt") / 1e6
num_scrit = np.loadtxt("data/2d_scrit_compo_12_average_num.txt") / 1e6

mass_bc = np.loadtxt("data/2d_bc_compo_12_average_mass.txt") * 1e9
mass_scrit = np.loadtxt("data/2d_scrit_compo_12_average_mass.txt") * 1e9

(figure, axes_array) = mpl_helper.make_fig_array(2,2, figure_width=config.figure_width_double, 
                                                 left_margin=0.7, right_margin=0.6, vert_sep=0.3)

axes = axes_array[1][0]
axes.pcolor(x_array_bc, y_array_bc, num_bc.transpose(),linewidths = 0.1)
axes.set_xscale("log")
axes.set_yscale("linear")
axes.set_ylabel(r"$w_{\rm BC} / \%$")
axes.set_ylim(0, 0.8)
axes.set_xlim(5e-3, 5)
axes.grid(True)

axes = axes_array[0][0]
axes.pcolor(x_array_bc, y_array_bc, mass_bc.transpose(),linewidths = 0.1)
axes.set_xscale("log")
axes.set_yscale("linear")
axes.set_ylabel(r"$w_{\rm BC} / \%$")
axes.set_ylim(0, 0.8)
axes.set_xlim(5e-3, 5)
axes.grid(True)

axes = axes_array[1][1]
axes.pcolor(x_array_scrit, y_array_scrit, num_scrit.transpose(),linewidths = 0.1)
axes.set_xscale("log")
axes.set_yscale("log")
axes.set_ylabel(r"$S_{\rm crit} / \%$")
axes.set_ylim(1e-3, 1e2)
axes.set_xlim(5e-3, 5)
axes.grid(True)

axes = axes_array[0][1]
axes.pcolor(x_array_scrit, y_array_scrit, mass_scrit.transpose(),linewidths = 0.1)
axes.set_xscale("log")
axes.set_yscale("log")
axes.set_ylabel(r"$S_{\rm crit} / \%$")
axes.set_ylim(1e-3, 1e2)
axes.set_xlim(5e-3, 5)
axes.grid(True)

mpl_helper.remove_fig_array_axes(axes_array)

figure.savefig("figs/num_mass_bc_scrit_diameter_compo_2d.pdf")
