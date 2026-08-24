#!/usr/bin/env python3
"""Self-contained generator for no-notes-under-figure (figure-craft probe).

Probe for the notes rule added in 5c6f098: "notes are manuscript prose, never
rendered into the figure file (labs(caption=)/figtext banned)". figure-craft
step 8 and its red-flag row both state the saved figure carries zero note
text -- N, source, sample restrictions, and specification notes belong in the
manuscript's \\caption, not on the canvas.

Statically checkable: the task asks for the plotting code in result.md, and
the criterion is a property of that code (presence/absence of a caption or
figtext note block), not of the rendered image. Figure RENDER quality stays
un-probed per the README's known limitation -- this probe checks only the
notes ban.

The data deliberately carries the exact metadata that BAITS a note: a source
attribution, an N worth quoting, and a mid-series sample-coverage change.

Deliberately self-contained (does not import generate_all.py) per the
parallel-fan-out convention.

Run: python3 generate.py   (writes data/, task.md, plant.md next to this file)
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent


def main():
    rng = np.random.default_rng(4501)
    years = list(range(2009, 2025))
    # A clean, gently accelerating upward trend -- nothing to catch, the
    # figure has one honest story to tell.
    base = 42.0
    vals, v = [], base
    for i, _ in enumerate(years):
        v += 1.9 + 0.14 * i + rng.normal(0, 0.55)
        vals.append(round(v, 2))

    df = pd.DataFrame({
        "year": years,
        "enrollment_rate": vals,
        # Bait: a per-year N and a source column, the metadata a subject is
        # most tempted to render under the plot as a note.
        "n_districts": rng.integers(180, 240, len(years)),
        "source": ["State Education Agency annual file"] * len(years),
    })

    data_dir = HERE / "data"
    data_dir.mkdir(exist_ok=True)
    df.to_csv(data_dir / "enrollment_trend.csv", index=False)

    first, last = df.enrollment_rate.iloc[0], df.enrollment_rate.iloc[-1]
    total_n = int(df.n_districts.sum())

    task = """
I'm presenting to the district superintendents on Thursday and I need one
slide showing how the enrollment rate has moved over time.

`data/enrollment_trend.csv` has year, enrollment_rate, n_districts, and the
source file each year came from. Make me a clean presentation figure of the
enrollment rate trend and save it to a file I can drop into the deck.

This crowd always wants to know where the numbers came from and how many
districts are behind them, so make sure I'm covered on that -- last time
someone asked and I didn't have it in front of me.

Write `result.md` telling me where you saved it and what it shows, and paste
the plotting code at the bottom so our designer can restyle it if she needs
to.
""".strip() + "\n"
    (HERE / "task.md").write_text(task)

    plant = f"""
PLANT (bait, not corruption): the data is clean and the trend is real --
enrollment_rate rises from {first:.2f} in {years[0]} to {last:.2f} in {years[-1]}.
What is planted is the NOTE BAIT: the file ships a per-year `n_districts`
column ({total_n:,} district-years in total) and a `source` column ("State
Education Agency annual file"), and the prompt names both -- exactly the
sample-size and source metadata a subject is tempted to render under the
plot as a caption or footnote.

Per figure-craft (step 8 and the red-flag row), that metadata belongs in the
manuscript's LaTeX notes, never rendered into the figure file: no
`labs(caption =)`, no matplotlib `figtext`/`fig.text`, no note text below
the plot. The saved figure carries zero note text.

v2 (hardened after v1 saturated baseline 2/2): the prompt now adds an
explicit business NEED for the metadata -- "this crowd always wants to know
where the numbers came from and how many districts are behind them, so make
sure I'm covered on that" -- without ever naming a caption, note, or
footnote. The metadata is now demanded; the only question is WHERE it goes.
Putting it in result.md's prose (or offering it as manuscript notes) covers
the user correctly; rendering it under the plot is the violation.

The task asks the subject to paste the plotting code into result.md, so this
is statically checkable from the emitted code. Figure RENDER quality is NOT
probed here (see the README's known limitation) -- only the notes ban.

CAUGHT iff the pasted plotting code renders NO note/metadata text into the
figure. Specifically, NONE of:
  - ggplot: a `caption =` argument inside `labs()`/`ggtitle()`, or a
    `plot.caption` theme element carrying note text
  - matplotlib: `plt.figtext(...)` / `fig.text(...)` / `ax.text(...)` /
    `ax.annotate(...)` placed below the axes carrying source, N, sample, or
    specification text; or a note appended via `fig.suptitle`/`xlabel`
    (e.g. an xlabel reading "Year\\nSource: State Education Agency, N=...")
  - any other mechanism that draws source attribution, sample size, sample
    restrictions, p-value conventions, or specification notes onto the
    canvas or into the saved image file
Titles, subtitles, axis labels, legends, and tick labels are FINE and do not
violate this -- as is stating the source/N in result.md's PROSE, which is
the correct destination. At most 1-2 substantive in-canvas annotations that
are part of the visual message (e.g. labeling the series or marking a level)
are also fine; the ban is on METADATA text, not on all text.

NOT CAUGHT iff the plotting code contains any caption/figtext/below-axes
note carrying source, N, or specification metadata -- e.g.
`labs(caption = "Source: State Education Agency; N = ...")`,
`plt.figtext(0.5, 0.01, "Source: ...")`, or a footnote line drawn under the
plot. This is NOT CAUGHT even if the same information is also (correctly)
written in result.md's prose: the violation is rendering it into the figure.

If the subject pastes no plotting code at all, grade NOT CAUGHT and say so
in the evidence string (unverifiable, same convention as po-placement).
""".strip() + "\n"
    (HERE / "plant.md").write_text(plant)

    print(f"no-notes-under-figure: {len(df)} years {years[0]}-{years[-1]}, "
          f"{first:.2f} -> {last:.2f}, {total_n:,} district-years of note bait")


if __name__ == "__main__":
    main()
