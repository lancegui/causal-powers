# Large data — building in a lazy engine (Arrow, polars, Julia)

`SKILL.md` gives the four rules in one line each. This card is the detail: why
each one exists, and the idiom in R, Python, and Julia. It applies the moment a
source is too big to read whole comfortably — a multi-file parquet dataset, a
transaction table in the hundreds of millions of rows — and the build has to run
in an out-of-core / lazy engine (R `arrow` + `dplyr`, `pyarrow.dataset`, polars
lazy frames, or chunked reads in Julia).

The failure this card prevents is the usual one, made worse by scale: the build
runs, the panel comes out, and nothing says a column was mis-typed in a third of
the files, that a join dropped the unmapped rows, or that the node ran out of
memory on the 280th file only after an hour. At this size you cannot eyeball
the input, so the contracts have to be written into the build.

**Use the engine the project has standardized on.** Arrow/dplyr, polars, or a
database engine can all do this work; the right one is the one that already runs
reliably on this machine for this data. Don't switch engines mid-pipeline, and
don't introduce a second engine for one stage — the contracts, types, and
memory behaviour you validated belong to the first.

---

## 1. Multi-file parquet: pass an explicit schema (Arrow)

`open_dataset(files)` infers the dataset schema from **one file** (the first) and
applies it to all of them. In a dataset written over years, by different
exports, column types drift across files: an ID column that is a string in some
files and an integer in others; a unit column that changes type; a text column
that is entirely null in some files and so was written as `bool`. With an
inferred schema this either fails partway through a scan, or — worse — silently
casts: an ID with leading zeros read as an integer is no longer the same ID, so
**dedup and joins on that key break without an error**.

- **Survey the schemas once** — read every file's footer schema (cheap, no data)
  and tabulate the type of each column you need across files.
- **Write the schema by hand, listing only the columns you use**, each in the
  widest type that holds every file's values losslessly (IDs and codes as
  strings; quantities as `float64` unless every file is integer).
- **Pass it on every open.** Columns not in the schema are not read at all, which
  also cuts I/O.

```r
library(arrow); library(dplyr)
files <- Sys.glob("data/raw/transactions/*.parquet")
stopifnot(length(files) == N_FILES)                       # why: a missing file is a silent sample cut
# survey once: which columns change type across files?
types <- lapply(files, \(f) sapply(open_dataset(f)$schema$fields, \(x) x$type$ToString()))
SCH <- schema(BUYER_ID = utf8(), TXN_DATE = date32(), PRODUCT = utf8(),
              QUANTITY = float64(), UNIT = utf8(), AMOUNT = float64())   # only the columns used
ds <- open_dataset(files, schema = SCH)
```

```python
import pyarrow as pa, pyarrow.dataset as ds, pyarrow.parquet as pq
types = {f: pq.read_schema(f) for f in files}             # footer only, no data
SCH = pa.schema([("BUYER_ID", pa.string()), ("TXN_DATE", pa.date32()),
                 ("QUANTITY", pa.float64()), ("AMOUNT", pa.float64())])
d = ds.dataset(files, schema=SCH, format="parquet")
# polars: pl.scan_pyarrow_dataset(d), or pl.scan_parquet(files, schema=...) on a recent polars
```

## 2. Set thread counts explicitly (Arrow)

Arrow's CPU and I/O pools default to the detected core count. On a shared node
that oversubscribes the machine, and every thread also holds its own buffers, so
peak memory scales with it. Set both pools once, at the top of the script, to a
number chosen for this machine (e.g. 16 on a shared many-core node) — and the
same for any other threaded library in the script.

```r
set_cpu_count(16L); set_io_thread_count(16L)              # why: shared node; defaults = every core
data.table::setDTthreads(16L)
```

```python
pa.set_cpu_count(16); pa.set_io_thread_count(16)
# polars: os.environ["POLARS_MAX_THREADS"] = "16" BEFORE `import polars`
```

## 3. Push row-level work into the engine; materialize only after aggregating

The engine is lazy: verbs build a query plan, and nothing is read until you
materialize. Every row-level operation belongs **before** that point:

- **Filters** (sample window, unit types) — as early as possible, so the scan
  reads less.
- **Joins to small lookup / mapping tables** — push the lookup into the engine
  (`arrow_table(lookup)` / a lazy frame) and join there. **Assert the lookup's
  key is unique before the join** — in the engine a fan-out is just a bigger
  query result, and nothing errors.
- **Derived columns** (flags, period indices, conditional amounts).
- **Group-by / aggregate** down to the grain you actually need.

Then materialize (`collect()` / `.collect()` / `to_table()`), once per stage,
on the aggregated result.

**Plan where materialization happens by table size.** Before writing the stage,
write down each table's grain and rough row count (transactions → unit × month →
unit × quarter × product …) and collect only the tables that fit comfortably in
memory with headroom. A large intermediate that later steps reuse stays in the
engine — `compute()` in arrow/dplyr (an Arrow table, not R vectors), or write it
to parquet and re-open it lazily when even that is too big — and only its
aggregate is collected.

**Never read a whole large file into memory when a lazy filter would do.**
`read_parquet(big) %>% filter(...)` / `pd.read_parquet(big)` loads every row and
column first; `open_dataset(big) %>% filter(...) %>% select(...) %>% collect()`
/ `pl.scan_parquet(big).filter(...).select(...).collect()` reads only what
survives.

**Exact order statistics may have to wait.** Check whether the engine's
quantiles are exact: Arrow's `median()` / `quantile()` are approximate (t-digest).
When the exact value matters, aggregate to the smallest table that still holds
the values (e.g. one row per form or per order), collect it, and take the
median in memory.

```r
lookup <- read_parquet("data/intermediate/id_map.parquet")       # small: id -> unit
stopifnot(!anyDuplicated(lookup$BUYER_ID))                        # why: m:1 join; a dup key fans out silently
base <- ds %>%
  filter(TXN_DATE >= as.Date("2010-01-01"), UNIT %in% UNITS_KEPT) %>%
  inner_join(arrow_table(lookup), by = "BUYER_ID") %>%
  mutate(q = (year(TXN_DATE) - 2010L) * 4L + (month(TXN_DATE) - 1L) %/% 3L)
uq <- base %>% group_by(unit, q) %>%
  summarise(amount = sum(AMOUNT, na.rm = TRUE), n_txn = n(), .groups = "drop") %>%
  collect()                                                       # collect AFTER the group-by
big <- base %>% group_by(unit, q, PRODUCT) %>%
  summarise(qty = sum(QUANTITY), .groups = "drop") %>% compute()  # too big to collect: stays in Arrow
```

```python
import polars as pl
from datetime import date
lookup = pl.read_parquet("data/intermediate/id_map.parquet")
assert lookup["BUYER_ID"].is_unique().all(), "lookup key not unique"
uq = (pl.scan_pyarrow_dataset(d)
        .filter(pl.col("TXN_DATE") >= date(2010, 1, 1))
        .join(lookup.lazy(), on="BUYER_ID", how="inner")
        .with_columns(q=(pl.col("TXN_DATE").dt.year() - 2010) * 4 + (pl.col("TXN_DATE").dt.month() - 1) // 3)
        .group_by("unit", "q").agg(pl.col("AMOUNT").sum(), pl.len().alias("n_txn"))
        .collect())                                               # collect AFTER the group-by
```

**Julia.** Where the project has no lazy query engine, stream: read one file (or
one row group) at a time with only the needed columns, aggregate it to partial
sums and counts, and combine the partials. Only **decomposable** statistics
combine across chunks — sums, counts, min/max. A mean is `Σsum / Σcount`, never a
mean of chunk means; a median or distinct count does not decompose and needs the
collect-then-compute route above.

```julia
parts = map(files) do f
    d = DataFrame(Parquet2.Dataset(f))[!, COLS]                   # one file in memory at a time
    combine(groupby(d, [:unit, :q]), :AMOUNT => sum => :amount, nrow => :n_txn)
end
uq = combine(groupby(reduce(vcat, parts), [:unit, :q]), :amount => sum => :amount, :n_txn => sum => :n_txn)
```

## 4. Reconciliation contracts at every build stage

A lazy build has fewer natural places to look at the data, so every stage ends
with a contract that **stops** on violation (`stop()` / `raise` / `error()`,
never a warning). These are the `data-contracts` invariants, placed at stage
boundaries; counts are taken *in the engine* so they cost one scan, not a
collect.

- **Rows in == Σ counts out.** Count the rows entering the stage, carry `n()`
  through every aggregation, and check the aggregated table's counts sum back.
  If a filter or a split is part of the stage, the pieces add up: kept +
  excluded == in.
- **Totals reconcile to a known raw-source constant.** Fix the grand total of
  the main measure once from the raw source (a published figure, or a one-time
  full-data aggregate recorded as a named constant) and check each stage's sum
  against it with a relative tolerance.
- **Every aggregated table is unique on its key.** Assert it right after the
  collect.
- **Left joins to unique lookups leave the row count unchanged.** Inner joins
  that are *meant* to drop rows (unmapped IDs) report how many they dropped —
  that number is a sample decision, logged in `decisions.yaml`.
- **Watch it bite once** — run the uniqueness assert on a two-row duplicate and
  confirm it stops.

```r
n_in   <- ds %>% filter(...) %>% count() %>% collect() %>% pull(n)
n_base <- base %>% count() %>% collect() %>% pull(n)
message("unmapped rows dropped by the lookup join: ", n_in - n_base)
if (anyDuplicated(uq[c("unit", "q")])) stop("CONTRACT FAIL: uq not unique on unit, q")
if (sum(uq$n_txn) != n_base) stop("CONTRACT FAIL: transactions in uq ", sum(uq$n_txn), " vs ", n_base)
if (abs(sum(uq$amount) / RAW_TOTAL - 1) > 1e-6) stop(   # RAW_TOTAL: same window, from the raw source
  "CONTRACT FAIL: total ", sum(uq$amount), " vs ", RAW_TOTAL)
```

These are the build's equivalent of the merge protocol. They are few — one
count, one total, one uniqueness assert per stage — and they are the only thing
standing between a 300-file scan and a confidently wrong panel.
