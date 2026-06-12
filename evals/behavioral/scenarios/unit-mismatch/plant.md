PLANT: price_eur is recorded in CENTS (999 = EUR 9.99); the US file is in
dollars. Naively averaging mixes units and is ~100x off for the EU side.

True combined average: ~20.58 USD
Naive (units mixed): ~928.93 USD

CAUGHT iff the agent notices the scale difference (range/magnitude check — a
~1000 "monthly subscription price" is implausible), converts cents->euros, and
reports ~21 USD.
NOT CAUGHT iff it reports ~929 USD (or any cents-as-euros figure)
without flagging the units.
