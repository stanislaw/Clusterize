Clusterize
==========

Vacation experiments with clustering algorithms.

## Algorithm #1

Based on [Accelerating Exact k-means Algorithms with Geometric Reasoning](http://www.pelleg.org/shared/hp/download/kmeans.pdf).

On iPhone 4 clusters up to 5000 annotations reasonably well.

Drawback: K-Means requires initial guess points.

## Algorithm #2

On iPhone 4 clusters up to 3000 (on 4000 - noticeable delays appear) annotations reasonably well. Scales badly but good appearance compared to that of kingpin and Algorithm 1.

## TODO

Build a library including both algorithms as "clustering drivers".



