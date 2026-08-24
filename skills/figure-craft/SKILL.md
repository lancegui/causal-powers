---
name: figure-craft
description: >-
  Use when making a FIGURE / CHART / PLOT for a paper, deck, or presentation — in ANY language (R/ggplot2, Python/matplotlib, Julia/Makie). Governs the visual style: 16.5pt text throughout (axes, legend, title), no y-label (the title carries the y-axis meaning; paper figures get no headline title), concise axis labels, clean theme with colorblind-safe Paul-Tol palette, B&W-legible (shape/linetype redundancy), and a mandatory visual self-check (no clipped text, no overlapping labels). Covers DiD/event-study plots (dots + error bars, dashed treatment line), trend lines, stacked bars, distributions, scatter — and the layout each forces. At most 1-2 inside-canvas annotations that ENHANCE understanding (absolute counts on pct bars, pretreatment-level label on DiD); metadata (N, source, p-values) goes in LaTeX notes. Output: 5×3 in, saved to results/figures/. Fires on "make a figure", "plot this", "chart", "draw", "visualize" — AFTER the data is framed and verified.
---

# Figure Craft

## Overview

The discipline skills keep you from being **wrong**; this skill keeps the figure **readable at a glance from the back of the room**. A figure is a communication artifact, not a debug plot — it will be projected on a screen, embedded in a paper, or dropped into a slide deck, and the audience will give it three seconds. It may also be printed in black and white. Every choice below serves those constraints.

**Core principle:** the minimum ink that conveys the idea, at a size the back row can read, with nothing clipped or overlapping — legible in color and in grayscale. Restraint, not decoration.

**This guide applies to EVERY figure, in every language.** The house style is defined by its *principles* (clean theme, colorblind-safe palette, large fonts, no y-axis label, concise labels, right geom, B&W-safe, visual self-check); the *implementation* differs by language. The R implementation — `theme_hc()` + `scale_color_ptol()` from `ggthemes` — is the reference because it's the most direct, but the same principles map to Python and Julia. Don't skip the style because you're not in R; translate it.

This skill fires **after** the data is right — after `question-framing` (what each mark encodes, the unit, the joins), after `descriptive-evidence` or `causal-identification` (the number is real), and after `result-verification` (it reproduces). It governs only the *rendering* — the bridge from a verified result to a presentation-ready exhibit. If the data hasn't been validated yet, route there first (`result-verification` itself runs only if the user asks for it); a beautiful figure of a wrong number is still a wrong number.

## Where this sits

This is the **last step** of the analysis chain, not the first. The figure renders a result that has already been earned:

- `question-framing` → what each mark encodes, the unit, the joins — frame before you plot.
- `descriptive-evidence` or `causal-identification` → the number is real and the composition / identification is checked.
- `result-verification` → the number reproduces from a clean seed.
- **`figure-craft`** → render the verified result as a presentation-ready exhibit.
- `project-organization` → save the figure to `results/figures/` with a conventional name (`fig_<what_it_shows>.pdf`); the figure is a deliverable, not scratch.

`analysis-craft` runs alongside — keep the plotting code minimal and legible, the same as any analysis code. `analysis-checkpoints` applies if a figure choice would change what the reader takes away (e.g., switching from levels to changes mid-stream) — that's a framing change, not a style tweak.

## The house style — non-negotiable defaults

These are the style guide's fixed choices. Apply them unless the user explicitly overrides; if you deviate, say why. The table below gives the principle, the R implementation (the reference), and the Python/Julia equivalents.

### Theme and color

| Principle | R (reference) | Python | Julia |
|---|---|---|---|
| Clean, high-contrast, minimal-chrome base theme | `theme_hc()` from `ggthemes` | `seaborn.set_style("white")` + despine; or a custom `matplotlib` style with minimal gridlines, white background, dark axis lines | `Makie.jl` with `Theme(backgroundcolor = :white)` or `Plots.jl` `gr()` with minimal frame |
| Colorblind-safe qualitative palette (Paul-Tol) | `scale_color_ptol()` / `scale_fill_ptol()` from `ggthemes` | Manually set the Paul-Tol hex codes (see below) in `plt.rcParams["axes.prop_cycle"]` or per-artist `color=` | Pass the Paul-Tol hex array to `palette`/`color` arguments |
| Black axis line grounding the plot | `axis.line = element_line(color = "black")` | `ax.spines[...].set_color("black")` + `ax.tick_params(colors="black")` | `Makie`/`Plots` axis line color |
| No legend title | `legend.title = element_blank()` | `ax.legend(title=None)` | `legendtitle = nothing` |

**The Paul-Tol qualitative palette** (use these hex codes when the library doesn't provide them natively):

```
#332288  #117733  #44AA99  #88CCEE  #DDCC77  #CC6677  #AA4499  #882255
```

(8 colors — if you have more categories than this, the palette is being stretched; reconsider the encoding.)

### Black-and-white legibility — color is never the only channel

A figure that reads in color but falls apart in grayscale is not done. Papers get printed in B&W; slides get photocopied; reviewers read on e-ink. **Every distinction the color encodes must have a redundant non-color channel** — shape, linetype, size, or label:

| Channel | R | Python | Julia |
|---|---|---|---|
| **Point shape** by group (for scatter / coefficient plots) | `aes(shape = group)` + `scale_shape_manual()` | `plt.scatter(..., marker=...)` per group | `markershape` per series |
| **Linetype** by group (for lines) | `aes(linetype = group)` + `scale_linetype_manual()` | `plt.plot(..., linestyle=...)` per group | `linestyle` per series |
| **Fill pattern** for bars (hatching) | `ggpattern::geom_col_pattern()` or manual fill density | `hatch` parameter in `plt.bar()` | `Makie` `Mesh` patterns or manual |
| **Direct labels** instead of a legend | `geom_text` / `ggrepel::geom_text_repel` | `ax.annotate(...)` per group | `text!` / `Makie.text` |

**The test:** before declaring a figure done, render it in grayscale (or mentally squint at the color version) and ask: "can I still tell the groups apart?" If two series collapse to the same gray, add shape or linetype — color alone was carrying a distinction it can't carry alone. With the Paul-Tol palette, the colors are chosen for colorblind-safety, but even they are not guaranteed to survive a B&W conversion without redundant encoding.

### Fonts — sized for the back row

Presentation figures need **large** text. The defaults below are calibrated for a figure ~5 inches wide (the standard output size, below); scale up proportionally for larger canvases. The title sits at the same 16.5 as the axis text: under the y-axis label rule below, the title *is* the y-axis label, so it carries axis-level information and gets axis-level size.

| Element | Size (pt) | R | Python | Julia |
|---|---|---|---|---|
| Axis title (x) | 16.5 | `axis.title = element_text(size = 16.5)` | `ax.set_xlabel(..., fontsize=16.5)` | `xlabel(..., fontsize=16.5)` |
| Axis tick labels | 16.5 | `axis.text = element_text(size = 16.5)` | `ax.tick_params(labelsize=16.5)` | tick label font size |
| Legend text | 16.5 | `legend.text = element_text(size = 16.5)` | `legend.get_texts()` → `set_fontsize(16.5)` | legend font size |
| Plot title / subtitle | 16.5 | `plot.title = element_text(size = 16.5)` | `ax.set_title(..., fontsize=16.5)` | title font size |
| **Y-axis title** | — | `axis.title.y = element_blank()` — **never set** | **do not call `set_ylabel`** | **no ylabel** |

### The y-axis label rule

**No y-axis label.** The y-axis meaning goes in the **title/subtitle**, not beside the axis. This frees vertical space, avoids rotated text, and lets the title carry the full description in a readable horizontal orientation.

The **title IS the y-axis label** — and for a **paper figure that is all the title ever is**: the headline belongs in the manuscript's `\caption`, never on the figure. Only a deck/presentation figure (no caption to carry it) may add a headline, as title with the y-axis meaning moving to the subtitle (R: `labs(title = "<headline>", subtitle = "<y-axis>")`; Python: `fig.suptitle` + `ax.set_title`; Julia: `title!` + `subtitle!`).

### Axis labels — concise to the point of abbreviation

X and Y labels must be **the shortest string that is still unambiguous** — incomplete sentences are fine, abbreviations are encouraged when standard. "Year", not "Calendar Year of Observation." "Coef.", not "Estimated Coefficient." If the y-axis meaning is already in the title/subtitle, the x-axis label is often a single word. Every character you save is space the audience doesn't have to parse.

## Output — size and file location

**Standard size: 5 × 3 inches**, unless the user asks otherwise. This is the default for all figures — it's compact enough for a paper figure and large enough for the 16.5pt fonts to breathe. Scale up for a full-slide deck figure only if asked.

**Save to the project's figure directory** per `project-organization` conventions — `results/figures/` for canonical deliverables, `results/diagnostics/` for scratch plots. Name by what the figure shows, traceable to its producer: `fig_eventstudy_mortality.pdf`.

| Language | Save call |
|---|---|
| R | `ggsave("results/figures/fig_<name>.pdf", width = 5, height = 3)` |
| Python | `plt.savefig("results/figures/fig_<name>.pdf", bbox_inches="tight")` with `fig = plt.figure(figsize=(5, 3))` |
| Julia (Makie) | `save("results/figures/fig_<name>.pdf", fig)` with `Figure(size=(5*96, 3*96))` or `resolution` |
| Julia (Plots.jl) | `savefig("results/figures/fig_<name>.pdf")` with `plot(..., size=(500, 300))` (px at 100 DPI) |

If `results/figures/` doesn't exist, create it. Never save a deliverable figure to the project root or `sandbox/` — it's a deliverable, not scratch.

## The visual self-check — MANDATORY

**You must render the figure to an image file and visually examine it before declaring it done.** "The code ran" is not "the figure is readable." This is the figure equivalent of `result-verification` — you are checking the output, not the code. This applies in every language.

After every save, open the file and verify:

1. **No text is clipped or extends outside the plot panel.** Check all four edges — axis labels, the title/subtitle, the legend, tick labels. Large fonts make this the #1 failure: a label that fit at default size overflows at 16.5pt. In R, watch `plot.margin`; in Python, `plt.tight_layout()` / `bbox_inches="tight"`; in Julia, check `fig` size vs content.
2. **No text overlaps.** The most common overlap is on a **busy x-axis** — many tick labels colliding. Fix it (below). Also check legend entries colliding with the plot, and the subtitle crashing into the axis.
3. **The legend fits.** If legend entries are long or numerous, they collide or wrap awkwardly — **switch to two rows** or move to the bottom (below).
4. **Point markers and error bars are visible.** At presentation scale, large markers and thick error bars are the floor; if the figure is wide, increase both.
5. **The color palette is doing its job** — and **the figure survives a grayscale render.** Categories should be distinguishable in color and in B&W (see *Black-and-white legibility* above). If you have > 8 categories, the palette is being stretched — reconsider the encoding.
6. **Annotations (if any) are placed cleanly** — not overlapping data markers, not clipped at the edge, and legible at the font size the rest of the figure uses.

### Fixing a busy x-axis

When x-axis tick labels collide, in order of preference:

- **Reduce breaks.** Show every other year, or every 5th unit. The audience doesn't need every tick; they need enough to locate themselves.
- **Rotate labels** as a last resort — but rotated labels are harder to read; prefer fewer breaks.
- **If the axis is categorical with long level names:** abbreviate the levels in the data before plotting.

### Fixing legend overflow

- **Two rows** — the default single-row legend overflows on wide category names.
- **Bottom placement** — frees horizontal space and lets the legend wrap naturally.
- **Drop it entirely** if the title already names the grouping and there's only one series — a legend with one entry is wasted ink. Or use direct labels on the series themselves (B&W-safe into the bargain).

## Annotations — at most 1–2, and only to enhance understanding

Inside-canvas annotations are **allowed but tightly constrained**: at most **1–2**, and only when they help the reader understand something the axes and title alone don't convey. The purpose of an annotation is solely to **enhance understanding**, not to decorate or to carry metadata.

An annotation earns its place when removing it would make the figure harder to interpret:

- **Absolute values on top of percentage bars.** If the y-axis shows percentages but the audience needs the absolute counts to judge whether a small percentage is a large number of people, label each bar with the count. The percentage is in the axis; the absolute is the annotation. This is information the axes can't carry simultaneously.
- **"Pretreatment treatment group" on a DiD plot.** A label showing the pretreatment level of the treatment group gives the reader the **relative scale** — is the effect large or small compared to the baseline? The coefficient plot alone shows the *change*; the annotation anchors the *level*. Place it as a text label near the relevant series.

What is NOT an annotation — these belong in **LaTeX figure notes** (`\caption` or a `note`), never on the canvas:

- Sample size (N = 1,204), data source (Source: ACS 2019), sample restrictions, p-value stars/conventions
- The regression equation, control variable lists, specification notes
- Anything that is **metadata about the analysis** rather than **part of the visual message**

"In LaTeX notes" means in the manuscript, **never rendered into the figure file**: no `labs(caption =)` / ggplot captions, no matplotlib `figtext` under the axes, no note text below the plot. The saved figure contains zero note text — write the note as manuscript prose only if the user asks for it.

**The rule:** at most 1–2 annotations. Each must pass the test: "does removing this make the figure harder to understand?" If yes, it stays; if it's merely informative, it goes in the notes.

## Chart-type decisions

### DiD / event-study coefficient plots — dots and error bars only

The canonical exhibit for causal-identification results: estimated coefficients with confidence intervals over time or event-time.

**Rules:**
- **Dots + error bars, not lines.** A connected line implies continuity between estimates; event-study coefficients are discrete period-by-period estimates. Dots convey "point estimate with uncertainty"; a line conveys "a continuous trajectory." Don't blur them. This applies in every language — `plt.errorbar` with `fmt="o"` and no line in Python, `scatter!` + `errorbars!` in Julia.
- **The dashed vertical line marks the treatment threshold.** Place it at the boundary between the last pre-period and the first post-period. In event-time notation that is conventionally **-0.5** (between period -1 and period 0). In calendar-time notation it goes at the treatment year. Always include it — without the line the reader can't see where pre ends and post begins.
- **A horizontal line at zero** — anchors the reader to the null.
- **Dodged points** when multiple groups share an x-value, so points and bars don't stack on each other.
- **B&W-safe shapes** — if two groups share an x-value, give them different point shapes (`aes(shape = group)`), not just different colors.
- **Consider a "pretreatment treatment group" annotation** to show the relative scale of the effect (see *Annotations* above).

### Trend lines — when to connect, when to stack, when to bar

**Think about what the chart is saying before you pick the geom.** The choice between a line, a stacked bar, or dots is not aesthetic — it carries meaning:

| The message | The right geom | Why |
|---|---|---|
| A single series tracks a level over time | line | Continuity is the point — each period flows into the next |
| Multiple series track levels over time, to compare their *shapes* | line (dodged, one color/linetype per series) | You want the reader to trace each series |
| A composition shifts over time (shares of a whole) | stacked bar | The stack shows both the total and the within-share change simultaneously |
| A composition at a few discrete points (not over time) | dodged bar | Stacking across non-adjacent categories misleads |
| Discrete estimates with uncertainty (coefficients, event-study) | point + errorbar | Dots = "here's an estimate ± noise"; a line would falsely imply interpolation |
| A distribution | histogram / density / bar | See *Distributions* below |

**The dot-vs-line distinction is the most important choice on this page.** A connected line says "the value moved smoothly from A to B." Dots say "here are independent estimates." If the x-values are independent estimates (event-study coefficients, cross-sectional regressions by group), **never connect them** — the connection invents a trajectory the data doesn't claim. If the x-values are a time series of observed values (not estimates), a line is natural.

**Stacked bars** are for *composition* — when the story is "the total stayed flat but the mix shifted." If the story is "series A grew faster than series B," stacked bars hide the individual trends; use dodged lines or dodged bars.

### Distributions

- **Histogram** for the shape of one variable — choose bin width deliberately (too fine = noise, too coarse = hides structure); state it.
- **Density** for comparing two or more distributions on the same axes — overlay with `alpha` so they don't occlude. Use different linetypes as well as colors for B&W.
- **ECDF** when the reader needs to read percentiles — less intuitive but more precise for "what share is below X."
- **Log x-axis** for heavy-tailed distributions (income, firm size, claim amounts) — otherwise the bottom 90% is crushed against zero and the "shape" is just "the top is big."

### Scatter plots

- **Show the points** — don't let a fitted line claim a relationship the scatter doesn't support. If N is large, use `alpha` (0.1–0.3) so density is visible.
- **A fitted line is a claim** — a loess/lowess through noisy data can invent a trend the scatter doesn't show. Only add it if you'd defend the functional form.
- **Color by a grouping variable** to reveal composition — a single-color scatter that looks like noise can resolve into clean clusters when you color by group. Use different marker shapes too (B&W-safe).

## The complete template

A copy-pasteable skeleton encoding every default above. The R version is the reference; see the language tables above for Python/Julia equivalents.

```r
library(ggplot2)
library(ggthemes)

ggplot(data, aes(x = ..., y = ..., color = ..., shape = ...)) +    # shape = B&W redundancy
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed") +              # treatment threshold (event-time)
  geom_point(position = position_dodge(width = 0.3), size = 3) +
  geom_errorbar(aes(ymin = ..., ymax = ...),
                width = 0.2, position = position_dodge(width = 0.3)) +
  scale_x_continuous(breaks = ...) +                                # space out a busy axis
  theme_hc() +
  theme(legend.title = element_blank(),
        axis.line = element_line(color = "black"),
        axis.title = element_text(size = 16.5),
        axis.text = element_text(size = 16.5),
        legend.text = element_text(size = 16.5),
        plot.title = element_text(size = 16.5),
        axis.title.y = element_blank(),
        legend.position = "bottom") +
  scale_color_ptol() +
  scale_shape_manual(values = c(16, 17, 15, 18)) +                 # B&W-safe shapes
  xlab("...") +                                                     # concise — one word if possible
  ggtitle("...")                                                     # the y-axis meaning (subtitle role)

ggsave("results/figures/fig_<name>.pdf", width = 5, height = 3)     # then OPEN and visually check
```

## Red flags — STOP

- **Shipping a figure you haven't visually examined.** "The code ran clean" is not "the figure is readable." Render it, open it, check for clipping and overlap — every time, in every language.
- **A figure that collapses in black and white.** If two series are indistinguishable in grayscale, color was the only channel — add shape, linetype, or direct labels.
- **A y-axis label on a presentation figure.** It belongs in the title/subtitle; the y-axis title is never set.
- **Connecting independent estimates with a line.** Event-study coefficients, cross-sectional regressions, group-wise estimates — dots + error bars, never a line. The line invents a trajectory.
- **Overlapping x-axis labels.** A busy axis with every tick shown is unreadable. Reduce breaks or rotate — but prefer fewer breaks.
- **More than 2 inside-canvas annotations.** Annotations enhance understanding — they are not decoration. If you're reaching for a third, one of them is metadata that belongs in the LaTeX notes.
- **Metadata (N, source, p-values, equations) inside the plot.** They go in the LaTeX figure notes, not on the canvas.
- **Note text rendered below the plot** (`labs(caption =)`, `fig.text`) — the figure file carries no notes; notes are manuscript prose.
- **Fonts too small for presentation.** If the audience is more than arm's length from the screen, default text is invisible. The floor is 16.5pt for axis/legend text.
- **A legend with one entry.** If there's one series, the title already names it; drop the legend.
- **Saving a figure to the project root or a non-standard path.** Deliverable figures go to `results/figures/fig_<name>.pdf` per `project-organization`.
- **Skipping the style because "I'm in Python, not R."** The house style is principles, not an R package. Translate the theme, palette, and font sizes to your language.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "It's just a draft figure, I'll fix the labels later." | The visual self-check catches the clipping *now*, when it's cheap. A draft with overlapping labels gets shown to a coauthor and the first thing they say is "fix the axis." |
| "A line looks cleaner than dots." | A line claims continuity the estimates don't have. "Cleaner" here means "misleading." Dots + error bars is the honest encoding for discrete estimates. |
| "I'll put the sample size in the corner of the plot." | That's metadata — it goes in the figure notes. Inside the plot it competes with the data and gets clipped at projection scale. But a *load-bearing* annotation (absolute counts on a percentage bar) stays. |
| "The default font size is fine." | The default is ~11pt — for a paper page, not a screen. For a presentation, 16.5pt is the floor. If you can't read it from across the room, neither can the audience. |
| "I'll show every year on the x-axis so nothing is hidden." | Colliding labels hide *more* than omitted ticks. Reduce breaks; the reader locates themselves from 3–5 visible labels, not 20 overlapping ones. |
| "The legend is a little long but it fits." | At 16.5pt a long legend overflows or collides. Wrap to two rows or move to bottom *before* it breaks, not after. |
| "I connected the event-study dots to show the trend." | There is no trend — those are independent estimates. The line fabricates interpolation between points you never estimated. |
| "I'm in Python, so theme_hc doesn't apply." | The *principle* applies: clean white background, dark axis lines, minimal gridlines, Paul-Tol palette, 16.5pt fonts. Translate it, don't skip it. |
| "Nobody prints in black and white anymore." | Reviewers do. E-ink readers do. And colorblind readers experience your color figure the way a B&W reader does. Add shape/linetype redundancy — it costs nothing and saves the figure in half its real-world renderings. |
| "I added five annotations to make the figure self-contained." | At most 1–2 annotations, and only if removing them makes the figure harder to understand. The rest goes in LaTeX notes. A figure cluttered with labels is harder to read, not easier. |

## The Process

1. **Confirm the data is validated first.** The figure is the last step, not the first. If the numbers haven't been verified, say so and offer `result-verification` — a polished figure of an unverified number is still an unverified number.
2. **Pick the geom by the message, not by habit.** Dots for discrete estimates (DiD, event study); lines for continuous observed series; stacked bars for composition; dodged bars for cross-sectional comparison. The dot-vs-line choice is a claim about what the data is — get it right.
3. **Apply the house style in your language.** Clean theme + Paul-Tol palette + large fonts (16.5pt floor) + no y-axis label (meaning in the title/subtitle) + concise x-axis label + dashed treatment line for DiD + zero line + dodged points. Use the language tables above to translate the R reference to Python or Julia.
4. **Ensure black-and-white legibility.** Every group distinction needs a redundant non-color channel — shape for points, linetype for lines, hatch for bars, or direct labels. Render in grayscale and verify you can still tell groups apart.
5. **Add at most 1–2 annotations that enhance understanding.** Absolute values on percentage bars, a "pretreatment treatment group" label for relative scale. Each must pass: "does removing this make the figure harder to understand?"
6. **Save to the standard path at the standard size.** `results/figures/fig_<name>.pdf`, 5×3 inches — unless the user asked otherwise.
7. **Render and visually examine.** Open the saved file and run the visual self-check: no clipping, no overlap, legend fits, markers visible, palette distinguishable, B&W-safe, annotations placed cleanly. Fix and re-render until clean.
8. **Move all metadata to LaTeX figure notes — in the manuscript, not the image.** N, source, sample restrictions, p-value conventions — they go in `\caption` or a `note`, never on the canvas and never rendered into the figure file (no `labs(caption =)`, no `figtext`).
9. **Hand off to `project-organization`** — confirm the figure is named and placed per convention; commit the checkpoint.

## The bottom line

```
Presentation figure  →  clean theme + Paul-Tol palette + 16.5pt fonts + no y-label (title carries it) +
                         concise axis labels + right geom (dots for estimates, lines for series, stacks for composition) +
                         dashed treatment line for DiD + zero line + B&W-safe (shape/linetype redundancy) +
                         at most 1-2 enhancing annotations + metadata in LaTeX notes (in the paper, not the image) +
                         saved to results/figures/ at 5×3 in + visually checked (no clip, no overlap) — in ANY language
Otherwise             →  a plot that runs clean but is unreadable from the back row, or from a photocopier —
                         labels clipped, text overlapping, wrong geom inventing a trend, color-only distinctions
                         collapsing in grayscale, too many annotations crowding the data
```