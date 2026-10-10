# A/B prompts — identical across arms except the one "style guide" paragraph

Preamble (both arms):

> You are writing one script for an economist's research project. The project lives at `<ARM_DIR>` — a fresh copy of the repo layout with the data in Data/. Rules: work only inside that directory; do not read, list, or search any other directory on this machine, and do not look at other repositories. Write the script at the path given, run it from the project root exactly as instructed, fix until it runs clean, then reply with ONLY: (1) the script path, (2) the last 25 lines of the run output.

With-skill arm adds:

> The author has a coding style guide at `<ARM_DIR>/CODE_STYLE.md` (a copy of `skills/code-style/SKILL.md`). Read it in full before writing anything and follow it exactly, including its default-on improvements.

Tasks (one per language; data from `gen_data.py`, seed 20261010):

- **R** `Stylized_Facts/Stock_Out_By_Chain.R` — MOUD shipments only → map DEA to pharmacy_id → pharmacy × month grams → fill zero months from first shipment through 2019-12 → stock-out share per pharmacy → join CHAIN + zip → `feols(share ~ CHAIN | zip)` → save RDS + density plot. Run: `Rscript Stylized_Facts/Stock_Out_By_Chain.R`.
- **Julia** `Estimation/Logit_Choice.jl` — conditional logit (price, price × medicaid, distance, default; outside option = 0) by MLE with Optim LBFGS + autodiff → Hessian SEs → `@save` θ̂ → baseline + 3 counterfactual purchase shares (no default, distance halved, price +20%). Run: `julia --project=<scratch env> Estimation/Logit_Choice.jl`.
- **Python** `Data_Processing/Clean_NDC_Pages.py` — for each MOUD NDC parse the saved HTML page (stdlib only) → 4 fields + is_tablet → 11-digit NDC → write CSV, save every 10, skip done on rerun. Run twice.

Subject model: the session's default (Fable 5.1), `general-purpose` subagents, 2026-10-10.
