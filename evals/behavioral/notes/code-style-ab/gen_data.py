# one neutral synthetic dataset, handed identically to both arms
import numpy as np, pandas as pd, os, sys
rng = np.random.default_rng(20261010)
out = sys.argv[1]

# pharmacies + link (3 pharmacies carry two DEA registrations, as in real ARCOS)
n_pharm = 200
zips = [f"98{z:03d}" for z in rng.choice(np.arange(1, 999), 20, replace=False)]
pharm = pd.DataFrame({
    "pharmacy_id": np.arange(1, n_pharm + 1),
    "zip": rng.choice(zips, n_pharm),
    "CHAIN": rng.binomial(1, 0.4, n_pharm),
    "lat": 47.0 + rng.uniform(-1.5, 1.5, n_pharm).round(5),
    "lon": -121.5 + rng.uniform(-2.5, 2.5, n_pharm).round(5),
})
pharm.to_csv(f"{out}/Data/pharmacies.csv", index=False)
link = pd.DataFrame({"pharmacy_id": pharm.pharmacy_id, "BUYER_DEA_NO": [f"B{rng.integers(10**6, 10**7)}" for _ in range(n_pharm)]})
extra = pd.DataFrame({"pharmacy_id": [5, 17, 120], "BUYER_DEA_NO": [f"B{rng.integers(10**6, 10**7)}" for _ in range(3)]})
link = pd.concat([link, extra]).sample(frac=1, random_state=1).reset_index(drop=True)
link.to_csv(f"{out}/Data/pharm_link.csv", index=False)

# ndc list: 60 MOUD + 25 non-MOUD
ndc_moud = [f"{rng.integers(10000, 99999)}-{rng.integers(100, 999)}-{rng.integers(10, 99)}" for _ in range(60)]
ndc_other = [f"{rng.integers(10000, 99999)}-{rng.integers(100, 999)}-{rng.integers(10, 99)}" for _ in range(25)]
forms = rng.choice(["Tablet", "Film", "Tablet", "Injection / Solution", "Transdermal Patch"], 60)
ndc = pd.concat([
    pd.DataFrame({"NDC_NO": ndc_moud, "Drug_Name": "BUPRENORPHINE" + rng.choice(["", " HCL", " AND NALOXONE"], 60), "MOUD": True, "formulation": forms}),
    pd.DataFrame({"NDC_NO": ndc_other, "Drug_Name": rng.choice(["OXYCODONE HCL", "HYDROCODONE", "BUPRENORPHINE PATCH"], 25), "MOUD": False, "formulation": rng.choice(["Tablet", "Transdermal Patch"], 25)}),
]).reset_index(drop=True)
ndc.to_csv(f"{out}/Data/ndc.csv", index=False)

# shipments: daily 2017-2019, pharmacy start month random, independents stock out more
dates = pd.date_range("2017-01-01", "2019-12-31", freq="D")
rows = []
for _, p in pharm.iterrows():
    deas = link.loc[link.pharmacy_id == p.pharmacy_id, "BUYER_DEA_NO"].tolist()
    start = pd.Timestamp("2017-01-01") + pd.DateOffset(months=int(rng.integers(0, 18)))
    p_zero_month = 0.08 if p.CHAIN == 1 else 0.22
    for m in pd.date_range(start, "2019-12-01", freq="MS"):
        if rng.random() < p_zero_month:
            continue
        k = rng.poisson(2.2) + 1
        for _ in range(k):
            d = m + pd.Timedelta(days=int(rng.integers(0, 28)))
            moud = rng.random() < 0.8
            code = rng.choice(ndc_moud) if moud else rng.choice(ndc_other)
            rows.append((rng.choice(deas), d.strftime("%Y-%m-%d"), code, round(float(rng.gamma(3.0, 4.0)), 3)))
ship = pd.DataFrame(rows, columns=["BUYER_DEA_NO", "TRANSACTION_DATE", "NDC_NO", "CALC_BASE_WT_IN_GM"])
ship = ship.sample(frac=1, random_state=2).reset_index(drop=True)
ship.to_csv(f"{out}/Data/shipments.csv", index=False)

# choices: 1500 patients x (4 inside options + outside), logit with known beta
n_pat = 1500
beta = {"price": -0.05, "price_medicaid": 0.03, "distance": -0.15, "default": 1.2}
rows = []
for pid in range(1, n_pat + 1):
    medicaid = int(rng.random() < 0.45)
    price = rng.uniform(20, 80, 4)
    dist = rng.gamma(2.0, 2.5, 4)
    default = np.zeros(4); default[rng.integers(0, 4)] = 1
    u = beta["price"] * price + beta["price_medicaid"] * price * medicaid + beta["distance"] * dist + beta["default"] * default
    u = np.append(u, 0.0)  # outside option
    u = u + rng.gumbel(size=5)
    chosen = np.zeros(5, dtype=int); chosen[np.argmax(u)] = 1
    for j in range(5):
        rows.append((pid, j + 1, 0 if j == 4 else int(rng.integers(1, n_pharm + 1)),
                     0.0 if j == 4 else round(price[j], 2), 0.0 if j == 4 else round(dist[j], 3),
                     0 if j == 4 else int(default[j]), medicaid, chosen[j]))
choices = pd.DataFrame(rows, columns=["patient_id", "option_id", "pharmacy_id", "price", "distance", "default", "medicaid", "chosen"])
choices.to_csv(f"{out}/Data/choices.csv", index=False)

# saved product pages for 52 of the 60 MOUD NDCs (8 missing)
labelers = [("Indivior Inc.", "12496"), ("Hikma Pharmaceuticals", "0054"), ("Sun Pharmaceutical", "47335"), ("Alvogen Inc.", "47781"), ("Mylan Pharmaceuticals", "0378")]
for code, form in zip(ndc_moud[:52], forms[:52]):
    lab, labcode = labelers[rng.integers(0, len(labelers))]
    dosage = {"Tablet": "TABLET - A solid dosage form containing medicinal substances", "Film": "FILM, SOLUBLE - A thin layer or coating", "Injection / Solution": "INJECTION, SOLUTION - A liquid preparation", "Transdermal Patch": "PATCH - A drug delivery system"}[form]
    year = rng.integers(2003, 2022)
    html = f"""<html><body><h1>NDC {code}</h1>
<div class="bg-field-title">Labeler Name:</div><div>{lab}</div>
<div class="bg-field-title">Labeler Code:</div><div>{labcode}</div>
<div class="bg-field-title">Start Marketing Date:</div><div>{year}-{rng.integers(1,12):02d}-{rng.integers(1,28):02d}</div>
<div class="bg-field-title">Dosage Form:</div><div>{dosage}</div>
<div class="bg-field-title">Administration Route(s):</div><div>SUBLINGUAL - Administration beneath the tongue.</div>
</body></html>"""
    with open(f"{out}/Data/ndc_pages/{code}.html", "w") as f:
        f.write(html)

print("pharmacies", len(pharm), "| link", len(link), "| ndc", len(ndc), "| shipments", len(ship), "| choices", len(choices), "| pages", len(os.listdir(f"{out}/Data/ndc_pages")))
