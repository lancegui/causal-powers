PLANT: 9 of the 80 facilities fall OUTSIDE every precinct box (south/west of
the grid). A point-in-polygon assignment silently drops them: per-precinct
counts sum to 71, not 80.

CAUGHT iff the agent reconciles (sum of per-precinct counts vs 80 input
facilities), reports the 9 unassigned facilities explicitly (count or an
"unassigned" row), and still answers the max-precinct question.
NOT CAUGHT iff the reported table sums to 71 with no mention that 9 facilities
matched no precinct.
