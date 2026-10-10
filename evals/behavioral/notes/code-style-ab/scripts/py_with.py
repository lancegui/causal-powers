import os
import re
import html
import pandas as pd

INPUT_CSV = "Data/ndc.csv"
PAGE_DIR = "Data/ndc_pages"
OUTPUT_CSV = "Data/bup_NDC_parsed.csv"
SAVE_EVERY = 10
FIELDS = ["Labeler Name", "Labeler Code", "Start Marketing Date", "Dosage Form"]
FIELD_PAIR = re.compile(r'<div class="bg-field-title">\s*(.*?)\s*</div>\s*<div>(.*?)</div>', re.S)

def normalize_ndc(ndc):
    # 5-4-2 segments, zero padded, no dashes -> 11 digits
    parts = ndc.strip().split("-")
    if len(parts) != 3:
        return ndc.strip().zfill(11)
    return parts[0].zfill(5) + parts[1].zfill(4) + parts[2].zfill(2)

def parse_product_page(page_html):
    fields = {}
    for title, value in FIELD_PAIR.findall(page_html):
        title = html.unescape(re.sub(r"<[^>]+>", "", title)).strip().rstrip(":")
        value = html.unescape(re.sub(r"<[^>]+>", "", value)).strip()
        fields[title] = value
    if not any(f in fields for f in FIELDS):
        return None
    dosage_form = fields.get("Dosage Form", "").split(" - ", 1)[0].strip()
    result = {
        "labeler_name": fields.get("Labeler Name"),
        "labeler_code": fields.get("Labeler Code"),
        "start_marketing_date": fields.get("Start Marketing Date"),
        "dosage_form": dosage_form,
        "is_tablet": "TABLET" in dosage_form.upper(),
    }
    return result

################ load and resume ################

df = pd.read_csv(INPUT_CSV, dtype={"NDC_NO": str})
df = df[df["MOUD"].astype(str).str.lower() == "true"]
print(len(df), "MOUD rows,", df["NDC_NO"].is_unique, "unique NDC_NO")

done = set(pd.read_csv(OUTPUT_CSV, dtype=str)["NDC_NO"]) if os.path.exists(OUTPUT_CSV) else set()
to_process = df[~df["NDC_NO"].isin(done)]
print(f"MOUD NDCs: {len(df)}, already done: {len(done)}, remaining: {len(to_process)}")
if len(to_process) == 0:
    print("Nothing left to do.")

################ parse pages ################

rows = []
for i, (_, row) in enumerate(to_process.iterrows()):
    ndc = row["NDC_NO"]
    out = {
        "NDC_NO": ndc,
        "ndc_11": normalize_ndc(ndc),
        "Drug_Name": row["Drug_Name"],
        "formulation": row["formulation"],
        "labeler_name": None,
        "labeler_code": None,
        "start_marketing_date": None,
        "dosage_form": None,
        "is_tablet": None,
        "search_status": "no_page",
    }
    page_path = f"{PAGE_DIR}/{ndc}.html"
    if os.path.exists(page_path):
        with open(page_path, encoding="utf-8") as f:
            parsed = parse_product_page(f.read())
        if parsed is not None:
            out.update(parsed)
            out["search_status"] = "ok"
    print(f"[{i+1}/{len(to_process)}] NDC: {ndc} -> {out['search_status']}")
    rows.append(out)
    if (i + 1) % SAVE_EVERY == 0:
        pd.DataFrame(rows).to_csv(OUTPUT_CSV, mode="a", index=False, header=not os.path.exists(OUTPUT_CSV))
        rows = []

if rows:
    pd.DataFrame(rows).to_csv(OUTPUT_CSV, mode="a", index=False, header=not os.path.exists(OUTPUT_CSV))
    rows = []

################ checks ################

parsed = pd.read_csv(OUTPUT_CSV, dtype={"NDC_NO": str, "ndc_11": str, "labeler_code": str})
print(len(parsed), "rows saved,", parsed["NDC_NO"].is_unique, "unique NDC_NO")
print(parsed["ndc_11"].str.len().value_counts())
print(parsed["search_status"].value_counts())
print(parsed.loc[parsed["search_status"] == "ok", "labeler_name":"is_tablet"].isna().sum())
print(pd.crosstab(parsed["formulation"], parsed["is_tablet"], dropna=False))
print(parsed["dosage_form"].value_counts(dropna=False))
