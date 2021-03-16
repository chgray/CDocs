# Hello world
1. item1
2. item2

# Mermaid
```mermaid
    flowchart TD
        A-->B
        B.->C
        C-->|Loop!!|A
```

# MatPlotLib
```{.matplotlib}
import numpy as np
import matplotlib.pyplot as plt

np.random.seed(23)

# Compute areas and colors
N = 150
r = 2 * np.random.rand(N)
theta = 2 * np.pi * np.random.rand(N)
area = 200 * r**2
colors = theta

fig = plt.figure()
ax = fig.add_subplot(111, projection='polar')
c = ax.scatter(theta, r, c=colors, s=area, cmap='hsv', alpha=0.75)
```

# GNUPlot
```{.gnuplot}
set title "Simple Plots" font ",20"
set key left box
set samples 50
set style data points

plot [-10:10] sin(x),atan(x),cos(atan(x))
```

# GNUPlot2
```{.gnuplot}
set format z "%.1f"
unset key
set view 66, 200, 1, 1
set xyplane 0
unset xtics
unset ytics
set title "fence plot constructed with zerrorfill"
set xlabel "X axis"  rotate parallel
set ylabel "Y axis" rotate parallel offset -4
set pm3d depthorder base
sinc(u,v) = sin(sqrt(u**2+v**2)) / sqrt(u**2+v**2)

set style fill solid noborder
splot for [i=-5:4][y=-50:50:5] '+' using (i):($1/100.):(-1):(-1):(sinc($1/10., 1.+i)) with zerrorfill
```