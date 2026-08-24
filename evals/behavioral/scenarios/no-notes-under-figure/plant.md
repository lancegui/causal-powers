PLANT (bait, not corruption): the data is clean and the trend is real --
enrollment_rate rises from 44.96 in 2009 to 88.06 in 2024.
What is planted is the NOTE BAIT: the file ships a per-year `n_districts`
column (3,248 district-years in total) and a `source` column ("State
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
    (e.g. an xlabel reading "Year\nSource: State Education Agency, N=...")
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
