"""Parse saved NDC product pages for every MOUD NDC into Data/bup_NDC_parsed.csv.

Inputs
    Data/ndc.csv                      NDC_NO, Drug_Name, MOUD, formulation
    Data/ndc_pages/<NDC_NO>.html      one saved product page per MOUD NDC (some missing)

Output
    Data/bup_NDC_parsed.csv           one row per MOUD NDC (1:1 on NDC_NO)

Each page carries its fields as consecutive div pairs:
    <div class="bg-field-title">Labeler Name:</div><div>Hikma Pharmaceuticals</div>
Parsing uses only the standard library (html.parser); pandas handles the tables.

Resumable: progress is flushed to the output every SAVE_EVERY records, and NDCs
already present in the output are skipped on rerun.

Run from the project root:  python3 Data_Processing/Clean_NDC_Pages.py
"""

import os
import re
import sys
from html.parser import HTMLParser

import pandas as pd

NDC_CSV = os.path.join("Data", "ndc.csv")
PAGES_DIR = os.path.join("Data", "ndc_pages")
OUT_CSV = os.path.join("Data", "bup_NDC_parsed.csv")
SAVE_EVERY = 10

FIELDS = {
    "Labeler Name": "labeler_name",
    "Labeler Code": "labeler_code",
    "Start Marketing Date": "start_marketing_date",
    "Dosage Form": "dosage_form_full",
    "Administration Route(s)": "administration_route",
}

OUT_COLS = [
    "NDC_NO",
    "ndc11",
    "Drug_Name",
    "formulation",
    "labeler_name",
    "labeler_code",
    "start_marketing_date",
    "dosage_form",
    "dosage_form_full",
    "administration_route",
    "is_tablet",
    "search_status",
]


# ---------------------------------------------------------------------------
# HTML parsing (standard library only)
# ---------------------------------------------------------------------------
class FieldPairParser(HTMLParser):
    """Collect `<div class="bg-field-title">Key:</div><div>Value</div>` pairs.

    A title div sets the pending key; the next plain div closes the pair.
    """

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.fields = {}
        self._in_div = False
        self._is_title = False
        self._buf = []
        self._pending_key = None

    def handle_starttag(self, tag, attrs):
        if tag != "div":
            return
        classes = dict(attrs).get("class", "") or ""
        self._in_div = True
        self._is_title = "bg-field-title" in classes.split()
        self._buf = []

    def handle_data(self, data):
        if self._in_div:
            self._buf.append(data)

    def handle_endtag(self, tag):
        if tag != "div" or not self._in_div:
            return
        text = re.sub(r"\s+", " ", "".join(self._buf)).strip()
        if self._is_title:
            self._pending_key = text.rstrip(":").strip()
        elif self._pending_key is not None:
            self.fields[self._pending_key] = text
            self._pending_key = None
        self._in_div = False
        self._is_title = False
        self._buf = []


def parse_page(path):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        parser = FieldPairParser()
        parser.feed(fh.read())
        parser.close()
    return parser.fields


# ---------------------------------------------------------------------------
# Field helpers
# ---------------------------------------------------------------------------
def ndc_to_11(ndc):
    """'12277-867-11' -> '12277086711' (5-4-2 zero-padded, no dashes)."""
    parts = ndc.strip().split("-")
    if len(parts) != 3:
        raise ValueError(f"NDC_NO {ndc!r} is not 3 dash-separated segments")
    widths = (5, 4, 2)
    for p, w in zip(parts, widths):
        if not p.isdigit() or len(p) > w:
            raise ValueError(f"NDC_NO {ndc!r}: segment {p!r} does not fit width {w}")
    out = "".join(p.zfill(w) for p, w in zip(parts, widths))
    assert len(out) == 11 and out.isdigit(), out
    return out


def dosage_form_short(full):
    """Text before the first ' - ' (the FDA definition follows the dash)."""
    if full is None:
        return None
    return full.split(" - ", 1)[0].strip()


def is_tablet_flag(short_form):
    if short_form is None:
        return None
    return short_form.upper().startswith("TABLET")


def build_record(row):
    """One output record for one MOUD NDC row from ndc.csv."""
    ndc = row["NDC_NO"]
    rec = {
        "NDC_NO": ndc,
        "ndc11": ndc_to_11(ndc),
        "Drug_Name": row["Drug_Name"],
        "formulation": row["formulation"],
        "labeler_name": None,
        "labeler_code": None,
        "start_marketing_date": None,
        "dosage_form": None,
        "dosage_form_full": None,
        "administration_route": None,
        "is_tablet": None,
        "search_status": "no_page",
    }
    page = os.path.join(PAGES_DIR, f"{ndc}.html")
    if not os.path.isfile(page):
        return rec

    fields = parse_page(page)
    for key, col in FIELDS.items():
        rec[col] = fields.get(key)
    missing = [k for k in ("Labeler Name", "Labeler Code", "Start Marketing Date", "Dosage Form")
               if not fields.get(k)]
    if missing:
        raise ValueError(f"{page}: page exists but lacks fields {missing}; parsed keys={sorted(fields)}")
    rec["dosage_form"] = dosage_form_short(rec["dosage_form_full"])
    rec["is_tablet"] = is_tablet_flag(rec["dosage_form"])
    rec["search_status"] = "ok"
    return rec


# ---------------------------------------------------------------------------
# I/O with resume
# ---------------------------------------------------------------------------
def load_existing():
    if not os.path.isfile(OUT_CSV):
        return pd.DataFrame(columns=OUT_COLS)
    df = pd.read_csv(OUT_CSV, dtype=str, keep_default_na=False)
    df = df.replace({"": None})
    for c in OUT_COLS:
        if c not in df.columns:
            df[c] = None
    return df[OUT_COLS]


def save(df):
    """Atomic write: temp file then rename, so an interrupted save never truncates."""
    df = df[OUT_COLS].sort_values("NDC_NO").reset_index(drop=True)
    assert df["NDC_NO"].is_unique, "duplicate NDC_NO in output"
    tmp = OUT_CSV + ".tmp"
    df.to_csv(tmp, index=False)
    os.replace(tmp, OUT_CSV)


def main():
    if not os.path.isfile(NDC_CSV):
        sys.exit(f"Run from the project root: {NDC_CSV} not found (cwd={os.getcwd()})")

    ndc = pd.read_csv(NDC_CSV, dtype=str)
    assert ndc["NDC_NO"].is_unique, "ndc.csv: NDC_NO must be unique (1 row per NDC)"
    moud = ndc[ndc["MOUD"].str.strip().str.lower() == "true"].copy()
    moud = moud.sort_values("NDC_NO").reset_index(drop=True)
    n_pages = sum(f.endswith(".html") for f in os.listdir(PAGES_DIR)) if os.path.isdir(PAGES_DIR) else 0
    print(f"ndc.csv: {len(ndc)} NDCs, {len(moud)} MOUD; {n_pages} saved pages in {PAGES_DIR}")

    existing = load_existing()
    done = set(existing["NDC_NO"])
    todo = moud[~moud["NDC_NO"].isin(done)]
    print(f"Already done: {len(done)}; remaining: {len(todo)}")

    if todo.empty:
        print("Nothing left to do -- all MOUD NDCs already in", OUT_CSV)
        summarize(existing, moud)
        return

    records = []
    n_total = len(todo)
    for i, (_, row) in enumerate(todo.iterrows(), start=1):
        rec = build_record(row)
        records.append(rec)
        print(f"[{i:>3}/{n_total}] {rec['NDC_NO']} -> {rec['ndc11']}  {rec['search_status']:<7} "
              f"{rec['dosage_form'] or '-'}")
        if i % SAVE_EVERY == 0:
            save(pd.concat([existing, pd.DataFrame(records)], ignore_index=True))
            print(f"    ... saved progress ({len(done) + i} records in {OUT_CSV})")

    out = pd.concat([existing, pd.DataFrame(records)], ignore_index=True)
    save(out)
    print(f"Saved {len(out)} records to {OUT_CSV}")
    summarize(load_existing(), moud)


def summarize(out, moud):
    """Reconcile the output to its source: one row per MOUD NDC, nothing more."""
    assert set(out["NDC_NO"]) == set(moud["NDC_NO"]), "output NDC set != MOUD NDC set"
    assert len(out) == len(moud), f"output rows {len(out)} != MOUD NDCs {len(moud)}"
    assert out["ndc11"].str.fullmatch(r"\d{11}").all(), "ndc11 must be 11 digits"
    assert out["search_status"].isin(["ok", "no_page"]).all()
    ok = out["search_status"] == "ok"
    for c in ("labeler_name", "labeler_code", "start_marketing_date", "dosage_form"):
        assert out.loc[ok, c].notna().all(), f"{c} missing on an ok row"
    assert out.loc[~ok, "labeler_name"].isna().all(), "no_page row carries labeler data"

    print("\nsearch_status:")
    print(out["search_status"].value_counts().to_string())
    print("\ndosage_form x is_tablet (ok rows):")
    print(pd.crosstab(out.loc[ok, "dosage_form"], out.loc[ok, "is_tablet"]).to_string())
    print("\nformulation (ndc.csv) x dosage_form (page):")
    print(pd.crosstab(out.loc[ok, "formulation"], out.loc[ok, "dosage_form"]).to_string())
    # is_tablet arrives as text here because `out` is always the reloaded CSV.
    tab_mismatch = out.loc[ok & ((out["formulation"] == "Tablet") != (out["is_tablet"] == "True"))]
    if len(tab_mismatch):
        print(f"\nWARNING: {len(tab_mismatch)} ok rows where formulation=='Tablet' disagrees with is_tablet:")
        print(tab_mismatch[["NDC_NO", "formulation", "dosage_form", "is_tablet"]].to_string(index=False))
    print(f"\n{len(out)} rows written, {ok.sum()} ok, {(~ok).sum()} no_page.")


if __name__ == "__main__":
    main()
