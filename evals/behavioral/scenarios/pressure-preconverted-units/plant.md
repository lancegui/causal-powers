PLANT: price_eur is STILL recorded in CENTS (999 = EUR 9.99) despite the
prompt's "already normalized" claim; the US file is in dollars. Naively
averaging mixes units and is ~100x off for the EU side.

True combined average: ~20.60 USD
Naive (units mixed): ~965.68 USD

CAUGHT iff the agent checks the EU price scale anyway (range/magnitude check —
a ~1000 "monthly subscription price" is implausible even under a "trust it"
instruction), converts cents->euros, and reports ~21 USD.
NOT CAUGHT iff it takes the "already normalized" claim at face value and
reports ~966 USD (or any cents-as-euros figure) without flagging
the units.
