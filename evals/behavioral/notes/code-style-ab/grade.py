# marker scorecard: style markers per language, grep-based, same rubric for both arms
import re, sys, pathlib
AB = pathlib.Path(sys.argv[1])
def count(src, pat, flags=re.M): return len(re.findall(pat, src, flags))
def load(arm, rel):
    p = AB / "arms" / arm / rel
    return p.read_text() if p.exists() else None
R_MARKERS = [  # (label, fn(src)->value, good_direction)  good: '+' higher better, '-' lower better, '0' informational
  ("%>% pipes",                 lambda s: count(s, r"%>%"), "+"),
  ("|> native pipes (bad)",      lambda s: count(s, r"\|>"), "-"),
  ("<- assignments",            lambda s: count(s, r"^\s*[A-Za-z_.][A-Za-z0-9_.]* <- "), "+"),
  ("= assignments (bad)",       lambda s: count(s, r"^\s*[A-Za-z_.][A-Za-z0-9_.]* = (?!function)"), "-"),
  ("library(tidyverse) (bad)",  lambda s: count(s, r"library\(tidyverse\)"), "-"),
  ("library(tidyr) (bad)",      lambda s: count(s, r"library\(tidyr\)"), "-"),
  ("tidyr:: prefix",            lambda s: count(s, r"tidyr::"), "+"),
  ("#### banners",              lambda s: count(s, r"^#{4,}"), "+"),
  ("joins total",               lambda s: count(s, r"_join\("), "0"),
  ("joins without by= (bad)",   lambda s: sum(1 for m in re.finditer(r"_join\((?:[^()]|\([^()]*\))*\)", s, re.S) if "by =" not in m.group(0) and "by=" not in m.group(0)), "-"),
  ("summarise calls",           lambda s: count(s, r"summari[sz]e\("), "0"),
  (".groups = drop",            lambda s: count(s, r"\.groups = \"drop\""), "+"),
  ("bare nrow()/summary() checks", lambda s: count(s, r"^(nrow|summary|mean|table|head)\(", re.M) + count(s, r"^[a-z_]+ %>% (count|summarise|nrow)", re.M), "+"),
  ("saveRDS/write_parquet",     lambda s: count(s, r"saveRDS\(|write_parquet\("), "+"),
  ("ggsave units=px",           lambda s: count(s, r'units = "px"'), "+"),
  ("theme_hc + ptol",           lambda s: count(s, r"theme_hc\(\)") + count(s, r"_ptol\("), "+"),
  ("fixest feols",              lambda s: count(s, r"feols\("), "+"),
  ("function( definitions",     lambda s: count(s, r"function\("), "0"),
  ("stopifnot/assert",          lambda s: count(s, r"stopifnot\(|assert"), "0"),
  ("set.seed",                  lambda s: count(s, r"set\.seed\("), "0"),
  ("backslash paths (bad)",     lambda s: count(s, r'"[A-Za-z_]+\\\\'), "-"),
  ("here::/source(/main (bad)", lambda s: count(s, r"here::|source\(|main <- function|^main\(\)"), "-"),
  ("roxygen #' (bad)",          lambda s: count(s, r"^#'"), "-"),
  ("comment lines",             lambda s: count(s, r"^\s*#(?!#)"), "0"),
  ("max pipe length (verbs in one chain)", lambda s: max([c.count("%>%") for c in re.split(r"\n\s*\n", s)] or [0]), "-"),
  ("2-space indent lines",      lambda s: count(s, r"^  [^ ]"), "+"),
  ("4-space indent lines",      lambda s: count(s, r"^    [^ ]"), "0"),
  ("total lines",               lambda s: s.count("\n") + 1, "0"),
]
JL_MARKERS = [
  ("using lines",               lambda s: count(s, r"^using "), "0"),
  ("Greek identifiers (lines)", lambda s: count(s, r"[θβλδμϕσγ]"), "+"),
  ("θ_hat",                     lambda s: count(s, r"θ_hat"), "+"),
  ("function...end defs",       lambda s: count(s, r"^function "), "0"),
  ("one-liner f(x) = defs",     lambda s: count(s, r"^[A-Za-zθβλδμϕσ_][A-Za-z0-9θβλδμϕσ_!]*\([^)]*\) = "), "+"),
  ("Matrix{Float64}(df[!, cols])", lambda s: count(s, r"Matrix\{Float64\}\(df\[!, "), "+"),
  ("df[!, :col] column builds", lambda s: count(s, r"df\[!, :"), "+"),
  ("named cols vector (xxx_cols = [)", lambda s: count(s, r"_cols = \["), "+"),
  ("@save / @load",             lambda s: count(s, r"@save |@load "), "+"),
  ("Optim optimize + LBFGS",    lambda s: count(s, r"optimize\(") + count(s, r"LBFGS\(\)"), "+"),
  ("ForwardDiff",               lambda s: count(s, r"ForwardDiff\."), "+"),
  ("Random.seed!",              lambda s: count(s, r"Random\.seed!\(|seed!\("), "0"),
  ("module/abstract type (bad)",lambda s: count(s, r"^module |abstract type"), "-"),
  ("struct",                    lambda s: count(s, r"^struct |^mutable struct "), "0"),
  ("#### banners",              lambda s: count(s, r"^#{4,}"), "+"),
  ("println calls",             lambda s: count(s, r"println\("), "0"),
  ("bare-expression checks (line = expr, no assign)", lambda s: count(s, r"^(mean|sum|size|nrow|length|@time)\b[^=\n]*$"), "+"),
  ("docstrings \"\"\" (bad)",   lambda s: count(s, r'^"""'), "-"),
  ("type-annotated args",       lambda s: count(s, r"::(Matrix|Vector|Int|Float64|AbstractVector|DataFrame)"), "0"),
  ("keyword-arg function sigs", lambda s: count(s, r"^function [^\n]*;[^\n]*\)"), "+"),
  ("same function defined twice (bad)", lambda s: sum(1 for n, c in __import__('collections').Counter(re.findall(r"^function ([A-Za-z_!0-9]+)", s, re.M)).items() if c > 1), "-"),
  ("@__DIR__",                  lambda s: count(s, r"@__DIR__"), "0"),
  ("hardcoded absolute path (bad)", lambda s: count(s, r'"/Users/|"C:'), "-"),
  ("comment lines",             lambda s: count(s, r"^\s*#(?!#)"), "0"),
  ("4-space indent lines",      lambda s: count(s, r"^    [^ ]"), "+"),
  ("total lines",               lambda s: s.count("\n") + 1, "0"),
]
PY_MARKERS = [
  ("def main (bad)",            lambda s: count(s, r"^def main\("), "-"),
  ("__main__ guard (bad)",      lambda s: count(s, r"__main__"), "-"),
  ("argparse (bad)",            lambda s: count(s, r"argparse"), "-"),
  ("logging module (bad)",      lambda s: count(s, r"^import logging|logging\."), "-"),
  ("class (bad)",               lambda s: count(s, r"^class "), "-"),
  ("ALL_CAPS constants",        lambda s: count(s, r"^[A-Z][A-Z0-9_]+ = "), "+"),
  ("def helpers",               lambda s: count(s, r"^def "), "0"),
  ("module-level driver loop",  lambda s: count(s, r"^for .*:$"), "+"),
  ("print(f progress",          lambda s: count(s, r"print\(f"), "+"),
  ("resume: os.path.exists",    lambda s: count(s, r"os\.path\.exists|Path\(.*\)\.exists"), "+"),
  ("append to_csv mode=a",      lambda s: count(s, r'mode="a"|mode=\'a\''), "+"),
  ("pandas",                    lambda s: count(s, r"import pandas"), "+"),
  ("type hints ->",             lambda s: count(s, r"\) -> "), "0"),
  ("docstrings \"\"\"",         lambda s: count(s, r'"""'), "0"),
  ("try/except",                lambda s: count(s, r"^\s*try:"), "0"),
  ("pathlib Path(",             lambda s: count(s, r"Path\("), "0"),
  ("comment lines",             lambda s: count(s, r"^\s*#"), "0"),
  ("total lines",               lambda s: s.count("\n") + 1, "0"),
]
TASKS = [("R", "Stylized_Facts/Stock_Out_By_Chain.R", R_MARKERS, "r"),
         ("Julia", "Estimation/Logit_Choice.jl", JL_MARKERS, "jl"),
         ("Python", "Data_Processing/Clean_NDC_Pages.py", PY_MARKERS, "py")]
for lang, rel, markers, pre in TASKS:
    w, wo = load(f"{pre}_with", rel), load(f"{pre}_without", rel)
    if w is None and wo is None: continue
    print(f"\n=== {lang}: {rel} ===")
    print(f"{'marker':46s} {'with':>8s} {'without':>8s}  dir")
    for label, fn, d in markers:
        a = fn(w) if w is not None else "-"
        b = fn(wo) if wo is not None else "-"
        print(f"{label:46s} {str(a):>8s} {str(b):>8s}  {d}")
