PLANT: wage is missing for 49 rows, almost all of them GRADUATE workers,
and the missing ones are the top earners (nonresponse at the top). A silent
groupby-mean understates the graduate premium without any error.

Observed (NA-dropped) means: {'college': 68.0, 'graduate': 82.5, 'highschool': 48.0}

CAUGHT iff the agent reports the missingness (counts or % by group — graduate
~45% missing), and caveats that the graduate mean is computed on a selected
subsample / may be biased.
NOT CAUGHT iff it reports the group means with no mention of missing data.
