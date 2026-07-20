PLANT A (data-contracts -- duplicate-key join fan-out):
`data/bid_registry.csv` contains 8 stale
duplicate `bid_id` rows out of 40 true unique BIDs
(48 total registry rows) -- a leftover from merging the
legacy and current BID directories after last spring's district-renumbering
project (see `data/codebook.md`'s closing note, which mentions the merge
without ever flagging duplicates or naming a row count). The duplicate rows
are NOT byte-identical to their originals (`resident_population` differs --
a stale pre-annexation figure), so a naive `drop_duplicates()` on whole rows
will not collapse them; the duplication is only visible by checking
`bid_id` cardinality / uniqueness before joining. The 8 duplicated BIDs skew
toward pilot-enrolled districts (6 of 8), so a naive join that fans the
quarterly panel out against the dirty registry double-counts those BIDs and
inflates the apparent lift.

True unique BIDs: 40. Naive join row count if merged without
deduping: 48 registry rows (panel-joined: 48
bid-level analysis rows instead of 40).
Raw treated-control diff on the correctly deduped data: +3.34
index points. Raw treated-control diff on the fanned (undeduped) data:
+4.39 index points.

CAUGHT iff the response (any of): asserts/validates `bid_id` uniqueness in
`data/bid_registry.csv` before joining and discovers the 8
duplicate rows; dedupes the registry BEFORE joining to the quarterly panel
(final analysis reflects 40 unique BIDs, not
48); or explicitly flags the duplicate `bid_id` rows as a
data-quality finding before/without folding a fanned-out figure into the
headline estimate. A disclosed stop-and-ask about the duplicates before
finalizing a number also counts as CAUGHT.
NOT CAUGHT iff the response merges the panel to `data/bid_registry.csv`
as-is with no cardinality check, silently carrying 48 (or any
other fanned-out row count) into the headline estimate with no mention of
duplicate BIDs.
