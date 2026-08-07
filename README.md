# quarto-sciposter

Flexible scientific conference posters from plain Quarto markdown, rendered
with [Typst](https://typst.app) (bundled with Quarto ≥ 1.4 — no LaTeX
needed). Any poster size, 1–5 columns, any number of logos, optional
references, computed R figures.

## Install

Start a new poster (copies `template.qmd` and the extension):

```bash
quarto use template chrischizinski/quarto-sciposter
```

Or add the format to an existing project:

```bash
quarto add chrischizinski/quarto-sciposter
```

Render with:

```bash
quarto render my-poster.qmd --to sciposter-typst
```

## Quick start

```yaml
---
title: "Poster Title"
subtitle: "Optional subtitle"
author:
  - name: First Author
    affiliations:
      - name: School of Natural Resources, University of Nebraska–Lincoln
  - name: Second Author
    affiliations:
      - name: Cooperating Institution
format:
  sciposter-typst:
    poster:
      size: "48x36"          # inches, or a0 / a1 / a2
      columns: 3
      theme: unl             # unl | generic
      footer:
        left: "Conference 2026"
        center: "myproject.org"
        right: "me@university.edu"
logos:
  left:  [logos/university.svg]
  right: [logos/sponsor.png, logos/cooperator.png]
---
```

## Options (`poster:` key)

| Option | Default | Description |
|---|---|---|
| `size` | `"48x36"` | `"WxH"` in inches, or named `a0` / `a1` / `a2` |
| `orientation` | — | `portrait` or `landscape`; flips named sizes |
| `columns` | `3` | Body column count (1–5 sensible) |
| `gutter` | `1in` | Space between columns |
| `margin` | `1in` | Outer margin; title/footer bars bleed full width |
| `theme` | `generic` | `unl` (scarlet/cream) or `generic` (blue) |
| `colors` | theme default | Map of theme color overrides (see Colors and branding) |
| `fonts` | theme default | Font stack for body text, as a list |
| `heading-fonts` | body fonts | Font stack for title, headings, and takeaway |
| `code-fonts` | Typst default | Font stack for code, as a list |
| `code-font-size` | body size | Size for code; `0.75`–`0.85 ×` body is usual on a large poster |
| `code-ligatures` | font default | `false` turns off a coding font's ligatures |
| `theme-overrides` | — | Per-element style overrides (see Overriding theme elements) |
| `block-gap` | theme default | One vertical gap above and below every styled block |
| `heading-align` | `left` | `left` \| `center` \| `right` for level-1 section bars |
| `subheading-align` | `left` | Same, for level-2 subheadings |
| `stats-align` | `left` | Same, for the cells of an evidence strip |
| `title-gaps` | see Title bar | `{subtitle, author, affiliation}` gaps down the title bar |
| `title-sizes` | see Title bar | `{subtitle, author, affiliation}` type sizes under the title |
| `brand` | `true` | Set `false` to ignore the project's `_brand.yml` |
| `logo-height` | `1.5in` | Height of every title-bar logo |
| `footer` | — | String (centered) or `{left, center, right}` map |
| `refs` | `flow` | `flow` \| `box` \| `none` (see References) |
| `fig-max-height` | `45%` | Height cap for auto-sized figures, as fraction of column height |
| `base-font-size` | auto | Body text size; derived from poster width if unset (see Typography) |
| `title-font-size` | auto | Poster title size; `2.3 ×` body size if unset |
| `palette` | theme default | Figure colors, shared with R chunks (see Figure colors) |
| `table-css` | `theme` | How much CSS to drop from HTML tables: `theme`, `size-only`, `keep` (see Tables) |
| `draft` | `false` | Overlay a diagnostics panel on the render (see Draft mode) |
| `credit` | `false` | Print a "Built with quarto-sciposter" line (see Credit line) |

`logos.left` / `logos.right` (top-level keys) take lists of image paths —
as many as fit.

## Layout control (fenced divs)

| Div | Effect |
|---|---|
| `::: {.full-width}` | Contents span every column (floats to top or bottom edge — Typst constraint); `position="top"` or `"bottom"` picks which |
| `::: {.col-break}` | Force a column break |
| `::: {.poster-box title="..."}` | Framed box; add `.highlight` or `.alert` for variants |
| `::: {.takeaway label="..."}` | Headline finding, sized to read from across the aisle; optional `scale="2.2"`, add `.quiet` for the warm-surface variant |
| `::: {.stats label="..."}` | Evidence strip: one paragraph per cell, `**value** label` |
| `::: {.poster-grid}` | Aligned cells instead of column flow; `cols` / `widths` / `gutter` / `row-gutter` |
| `::: {.poster-surface}` | Tinted grouping block; `tint` / `ink` / `pad` / `radius` / `border` |
| `::: {.poster-image-frame}` | The same block with a rule and a mat, for images |
| `::: {.qr url="..."}` | Scannable QR code; optional `size="2in"`, `label="..."` and `offset="0.25in"` |

A `.full-width` float is not cheap. It costs its own height **plus** 0.4 in of
clearance out of *every* column, not out of one — a 1.5 in strip on a
three-column 48×36 removes 5.7 in of column content. Budget for it before
writing the body, and expect at most one or two per poster.

### QR codes

```markdown
::: {.qr url="https://github.com/you/project" label="Source and data"}
:::
```

Generated from the URL at render time, so the code cannot drift out of sync
with the link, and vector, so it stays sharp at any print size. Default size
is 2 in; **1.5 in is the practical floor** — below that a phone struggles to
lock on from standing distance. Keep codes in the lower two-thirds of a
mounted poster so people can hold a phone to them.

Uses [`tiaoma`](https://typst.app/universe/package/tiaoma/), downloaded on
first use and cached. The import is scoped, so a poster with no QR codes never
fetches it. See `examples/qr-codes.qmd`.

`offset` nudges the code down inside its layout cell, and negative values move
it up:

```markdown
::: {.qr url="https://example.org" size="2in" offset="0.25in"}
:::
```

It is for one job: putting a QR next to a logo whose artwork carries
transparent padding. `layout-valign="center"` centres the two *blocks*, which
is not the same as centring the two visible squares once one of them is mostly
empty canvas. **This cannot be automated** — Typst cannot inspect an image's
alpha channel, so it cannot find where the visible ink starts. Set the nudge by
eye against a render; there is no number to compute.

The offset reserves its height rather than sliding the block, so a nudge that
pushes a QR past the bottom of the body is reported by the overflow guard
instead of disappearing under the footer.

### Takeaway

A poster is read in three passes: the title and one key finding from 3–5 m,
headings and figures from ~1.5 m, body text from under 1 m. Most posters have
nothing built for the first pass, so nobody makes the second.

```markdown
::: {.takeaway label="Key finding"}
Catch rates fell 40% after the regulation change.
:::
```

Renders as a filled block at `2.2 ×` body size. Use one per poster — two
takeaways is none. `scale="3.0"` gets you to roughly 75 pt on an A0, which is
the size that genuinely reads at 3 m.

Adding `.quiet` keeps the type scale but puts it on the theme's warm surface
in the primary colour instead of reversed out of a filled panel:

```markdown
::: {.takeaway .quiet label="Take-home" scale="1.4"}
An open, reproducible path from survey planning to reported estimates.
:::
```

That is what a closing statement wants once the loud takeaway is spent — a
visual endpoint that does not read as a second headline.

### Stats strip

The 3–4 numbers a reader should be able to take without entering the prose.
One paragraph per cell; the leading `**bold**` becomes the value tier.

```markdown
::: {.stats label="One simulated reservoir season"}
**30** sampled days

**90** counts

**476** interviews

**Every** estimate has a CI
:::
```

Values render at `2 ×` body size in the theme's primary colour, labels beneath
them at body size, all on one shared warm surface — the fill is what groups
the cells, so they carry no borders of their own.

Four cells is the practical maximum on a three-column 48×36: equal columns at
`base-font-size: 28pt` in a 14.7 in column give each cell about 18 characters
of label before it wraps. Five cells wraps every label.

## Typography

`base-font-size` defaults to a size derived from the poster's width, because
larger posters are read from further away and comfortable reading holds
angular size roughly constant (`pt ≈ 25 × distance in metres`, calibrated
against 10 pt book type at 40 cm):

| Poster | Derived body size |
|---|---|
| a3 | 14 pt |
| a2 | 20 pt |
| a1 | 27 pt |
| a0 | 33 pt |
| custom (e.g. 48×36) | fitted from width, capped at 36 pt |

Named A-series sizes come from
[peace-of-posters](https://jonaspleyer.github.io/peace-of-posters/), whose
tables are tuned against real printed posters. Custom sizes use a linear fit
through those values, capped — a reader stands about the same distance from
any wall-sized poster, so type size stops growing once the poster is large.

Setting `base-font-size` explicitly always wins. Headings, captions,
references and the title are all multiples of it, so one value moves the whole
scale.

Body text is set ragged right rather than justified: poster columns run 45–65
characters, and justifying at that measure opens rivers and word gaps that are
more disruptive at reading distance than a soft right edge.

Line length is the constraint that most often goes wrong. Aim for 45–65
characters per line — `draft` mode measures it for you.

## Colors and branding

Three sources feed a poster's colors and fonts. They layer in this order, each
overriding the one before it, property by property:

1. **`theme`** — the base (`generic` or `unl`).
2. **`_brand.yml`** — a Quarto project brand, if one exists.
3. **`poster.colors` / `poster.fonts` / `poster.heading-fonts`** — explicit,
   and always final.

Brand outranks theme because `theme` defaults to `generic`: were it the other
way round, a brand would apply only to posters that never named a theme.
Set `poster.brand: false` to opt out and pin the theme as authored.

```yaml
poster:
  theme: unl
  colors:
    primary: "#7A1FA2"     # title bar, h1 bars, takeaway
    accent: "#B07D2B"      # h2 rules, links, box rules, footer
  fonts: ["Source Sans Pro", "Helvetica"]
  heading-fonts: ["Source Serif Pro"]
```

Overridable colors: `primary`, `accent`, `bg`, `fg`, `on-primary` (text drawn
on primary-filled surfaces), `box-bg`, `stripe`. Values are hex, with or
without the leading `#`.

From `_brand.yml`, sciposter reads `color.primary` → `primary`,
`color.secondary` → `accent`, `color.background` → `bg`, `color.foreground` →
`fg`, and the base and heading font families. It deliberately ignores two
brand properties:

- **`typography.base.size`** — a brand's base size is an article size. Poster
  body size derives from the page dimensions, and an 11pt document default
  would flatten the whole type scale.
- **`typography.headings.color`** — poster headings are reversed white on a
  filled primary bar, whereas a brand heading color assumes dark-on-light. It
  would render close to invisible.

### Overriding theme elements

`poster.colors` reaches the seven colors every element derives from. When a
poster needs one *element* to differ — a scarlet title bar above navy section
bars, or 38 pt headings when the built-in `1.6 ×` relationship gives 45 —
`poster.theme-overrides` names the element directly.

```yaml
poster:
  theme: unl
  title-font-size: 80pt
  base-font-size: 28pt
  theme-overrides:
    heading-box-args:
      fill: "#0D3B66"          # navy section bars
    heading-text-args:
      size: "38pt"             # not 1.6 x 28
    subheading-text-args:
      size: "32pt"
      fill: "#0D3B66"
```

Each entry **merges into** the element rather than replacing it, so naming a
size does not drop the font and fill the theme already set. Computed sizes are
merged *under* the theme dict, which is why an explicit `size:` wins over the
built-in ratio.

Element names follow the theme's own structure — `<element>-box-args` for the
container, `<element>-text-args` for the type inside it:

| Element | Reaches |
|---|---|
| `title-box-args` / `title-text-args` | The title bar, independent of headings |
| `heading-box-args` / `heading-text-args` | Level-1 section bars |
| `subheading-box-args` / `subheading-text-args` | Level-2 headings |
| `box-args`, `highlight-box-args`, `alert-box-args` | Poster boxes and variants |
| `takeaway-box-args`, `takeaway-quiet-box-args` | Both takeaway kinds |
| `stats-box-args`, `stat-value-text-args`, `stat-label-text-args` | The evidence strip |
| `surface-box-args`, `frame-box-args` | Surfaces and image frames |
| `code-text-args` | Code, when the three shorthands are not enough |
| `body-text-args`, `caption-text-args`, `link-text-args` | Prose, captions, links |
| `footer-box-args`, `footer-text-args`, `stripe-args` | Footer bar and title stripe |

Values are read by shape, not declared:

| You write | Typst gets |
|---|---|
| `"#0D3B66"` or `"0D3B66"` | a color |
| `"40pt"`, `"0.35in"`, `"1.2em"` | a length |
| `"50%"`, `"1fr"` | a ratio or fraction |
| `"none"`, `"auto"`, `true`, `42` | the literal |
| anything else | a string — `"bold"`, `"Fira Code"` |
| a YAML list | an array |
| a YAML map | a dictionary — which is how strokes and insets are written |

```yaml
    heading-box-args:
      inset: { x: "0.4in", y: "0.25in" }
      radius: "6pt"
    subheading-box-args:
      stroke: { bottom: "3pt" }
```

### One vertical rhythm

`poster.block-gap` sets a single gap above and below every styled block —
heading bars, subheadings, boxes, takeaways, stat strips, surfaces:

```yaml
poster:
  block-gap: "0.45in"
```

The theme ships an asymmetric default on headings, more air above a section
bar than below it. `block-gap` deliberately flattens that; a single gap is the
point of asking for one. `theme-overrides` still wins, so a poster can hold
the uniform rhythm everywhere and make one exception.

### Alignment, and why it is not in `theme-overrides`

```yaml
poster:
  heading-align: center
  subheading-align: center
  stats-align: center
```

`heading-align` centres the level-1 section bars, `subheading-align` the
level-2 subheadings, and `stats-align` the cells of an evidence strip. All
three default to `left`. A value other than `left`,
`center` or `right` stops the render with a named error rather than quietly
falling back — the wrong alignment on a poster tends to be noticed at the
printer.

These are poster options rather than `theme-overrides` entries because that
route cannot carry them. `theme-overrides` merges a dict *into* a dict, so a
bare alignment has no way through it, and `heading-text-args` is spread into
`text()`, which has no alignment parameter at all. They sit with `block-gap`
and `logo-height` instead, which are the same kind of thing: layout, not
colour.

### Title bar

Three gaps run down the middle of the title bar — below the title, above the
byline, above the affiliations. Name the ones you want to change:

```yaml
poster:
  title-gaps:
    subtitle: "0.07in"
    author: "0.18in"
    affiliation: "0.08in"
```

Defaults are `0.2in`, `0.35in` and `0.18in`. The dict merges over them, so
naming one gap leaves the other two alone. They are named rather than scaled by
a single factor because a poster that has to tighten them rarely tightens them
evenly: a six-author byline needs different treatment from its affiliation
line. Reach for this when the title bar's bottom inset starts eating the
affiliations.

The three type sizes take the same shape:

```yaml
poster:
  title-sizes:
    subtitle: "48pt"
    author: "48pt"
    affiliation: "32pt"
```

Their defaults are ratios of two *different* bases — the subtitle rides
`title-font-size` at `0.58 ×`, the byline and affiliations ride
`base-font-size` at `1.25 ×` and `0.95 ×`. That is why they need their own
option: neither base can lift the byline on its own, because raising
`base-font-size` to reach it resizes the entire poster. Set one when a venue
imposes an absolute floor — several university print shops specify a minimum
for the author line — and the other two stay on their ratios.

## Code at poster scale

Code inherits the body size by default, which is the size the prose beside it
is read at. On a large poster that is usually louder than it should be:

```yaml
poster:
  code-fonts: ["Fira Code", "DejaVu Sans Mono"]
  code-font-size: "22pt"     # against a 28pt body
  code-ligatures: false
```

All three are unset by default and setting none of them changes nothing —
code keeps Typst's own mono face at body size. `code-ligatures` is a
three-state: absent leaves the font's own setting alone, `false` turns
ligatures off, `true` forces them on. It only matters for a coding font that
has them, which is the reason to name Fira Code in the first place.

The grey panel Quarto draws behind a code block is Quarto's, not this
extension's, and these options leave it alone. Reach for
`theme-overrides.code-text-args` if the shorthands are not enough.

## Surfaces and frames

`.poster-surface` groups related content on a tint without coloring a whole
column. With no attributes it takes the theme's surface:

```markdown
::: {.poster-surface}
Grouped on the theme's warm surface.
:::

::: {.poster-surface tint="#0D3B66" ink="#FFFFFF" pad="0.35in" radius="6pt"}
A dark surface needs its own text color; `ink` is the only way markdown can
reach it.
:::
```

`.poster-image-frame` is the same block with a rule and a mat. It exists for
images: a dark cover or photograph dropped straight onto a pale poster prints
as a muddy block, and a thin rule plus an inset of the warm surface is what
separates it from the page.

```markdown
::: {.poster-image-frame pad="0.3in" border="#D8DEE4"}
![](book-cover.jpg){width=70%}
:::
```

Attributes: `tint` (fill), `ink` (text color), `pad` (inset), `radius`,
`border`. A bare color for `border` means a rule in that color at the theme's
weight; a length sets the weight.

**One limitation.** Inline code on a dark `tint` stays dark. Quarto's syntax
highlighter emits every token with an explicit fill, and an explicit fill on
the inner element beats `ink`. Use bold rather than backticks there.

## Aligning across columns

A poster column is a single stream. Two columns line up only when their
content happens to fill to the same height, and nothing an author writes makes
that reliable — Typst offers no cross-column anchor, so this is not something
a setting can fix.

`.poster-grid` gets alignment by leaving the flow model. Each top-level block
inside it becomes a grid cell, and a row is a row:

```markdown
::: {.poster-grid widths="1fr,1.4fr" gutter="0.4in"}
::: {.poster-surface}
Left cell. Its top edge shares a row with the cell beside it, whatever
either one contains.
:::

::: {.poster-surface}
Right cell, wider by `widths`.
:::
:::
```

`cols=3` gives equal fractions; `widths` overrides it with explicit tracks and
is the one to reach for when a narrow label column sits beside a wide diagram.
`gutter` sets both axes unless `row-gutter` names the other. Wrap the whole div
in `.full-width` to align across the poster rather than inside one column —
and read the float-cost note above before you do.

## Figure colors

`poster.palette` sets the figure series colors and is readable from R, so
plots and poster chrome cannot drift apart:

```yaml
poster:
  palette: ["#D55E00", "#0072B2", "#009E73", "#CC79A7"]
```

```r
sciposter_palette <- function(n = NULL) {
  p <- rmarkdown::metadata$format$`sciposter-typst`$poster$palette
  if (is.null(p)) p <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7")
  p <- unlist(p, use.names = FALSE)
  if (is.null(n)) p else rep_len(p, n)
}

ggplot(d, aes(x, y, color = grp)) +
  geom_point() +
  scale_color_manual(values = sciposter_palette(3))
```

Both themes default to [Okabe-Ito](https://jfly.uni-koeln.de/color/), a
colorblind-safe qualitative palette, reordered so the leading series matches
the theme. Neither R nor Python can see the Typst theme's built-in palette, so
declare `poster.palette` explicitly when computing figures — that is what makes
the YAML the single source. See `examples/r-figures.qmd`.

Keep figure `base_size` high enough that axis text survives being scaled into
a column; it needs to be legible at the 1.5 m scan, not just in RStudio.

#### Two ways enlarging figure type fails silently

Both of these clip the plot inside the SVG, before Typst ever sees it. Nothing
warns, and the damage is only visible in the rendered PDF.

**Raise `fig-width` and `base_size` together.** Effective on-poster type size
is `base_size × (column width ÷ fig-width)`. Raising `base_size` alone
eventually makes an axis title longer than the canvas it is drawn on, and
ggplot cuts it at the canvas edge. Hold the ratio instead: `fig-width: 7` with
`base_size = 11` and `fig-width: 10` with `base_size = 21` both land near
30 pt in a 14.7 in column, but only the second has room to draw the labels.

**Set `plot.margin` yourself.** `theme_minimal()`'s margin is half the base
size, which at 21 pt is not wide enough to hold the half of an outermost axis
label that hangs past the panel — the last tick label loses its right edge.
While you are there, `plot.title.position = "plot"` starts a left-aligned
panel title at the plot edge instead of after the y-axis labels, which is
what keeps a two-panel `patchwork` title from running off the canvas.

```r
theme_creel(base_size = 21) +
  theme(
    plot.margin = margin(t = 10, r = 26, b = 8, l = 8),
    plot.title.position = "plot"
  )
```

### Python

Everything above works under the Jupyter engine — figures come out as vector
SVG, and `great_tables` goes through the same CSS path as `gt`. Two
differences, neither of which warns:

- **`poster.palette` has to be read out of the YAML.** There is no
  `rmarkdown::metadata` equivalent, so the document parses its own front
  matter, locating itself via `QUARTO_DOCUMENT_PATH` / `QUARTO_DOCUMENT_FILE`.
- **Per-chunk `fig-width` is ignored.** Document-level `fig-width` reaches the
  kernel, but a chunk-level one does not; size individual figures in Python
  (`figsize=`, seaborn's `height`/`aspect`, plotnine's `figure_size`).

Because figures are scaled to their column, a physically larger figure prints
*smaller* labels. seaborn's `relplot` pads for an outside legend and so shrinks
more than a bare matplotlib figure asking for the same nominal size.

See `examples/python.qmd`.

## Draft mode

```yaml
poster:
  draft: true
```

Overlays a panel reporting page size, column width, measured characters per
line, the palette, and what reading distance each type tier is actually sized
for. Off by default — nothing changes in a final render. Word count is not
computed in Typst; check it with `pdftotext out.pdf - | wc -w` and aim under
800 words.

## Credit line

```yaml
poster:
  credit: true            # or: bottom-left / bottom-right
```

Prints a small, muted **Built with quarto-sciposter** in a bottom corner.
`true` uses the bottom right; `bottom-left` and `bottom-right` choose. Off
unless asked for, so upgrading never adds text to a poster that was already
laid out and printed.

It sits above the footer bar when there is one, and on the bottom margin when
there is not. Only the bottom corners are offered: the top edge of a poster is
the title bar, where a muted line either disappears into the accent fill or
competes with the title.

## Figures

- Unsized figures (including R chunk output) fill their column width,
  capped at `fig-max-height` of the column so one figure can't consume a
  whole column.
- Explicit sizes always win: `fig-width`/`fig-height` chunk options, or
  `![...](img.png){width=50%}`.
- Wrap a figure in `.full-width` to span the poster.

## Tables

**Short version: use a pipe table, `knitr::kable()`, or `tinytable`. Avoid
`kableExtra` and `flextable`.** `gt` works but keeps its own styling instead
of the poster's.

Tables inherit the poster body size and are drawn booktabs-style: a rule
above the header, one below it, one under the last row, nothing else. A full
grid at poster stroke weights cages the numbers and reads as texture from
three metres away.

What a table package emits for Typst decides whether it works on a poster.
Each row below was checked by rendering it through this extension.

| Source | Emits | Poster-safe |
|--------|-------|-------------|
| Pipe table, `knitr::kable()` | Typst table, no size of its own | Yes |
| `tinytable` | Typst table, no size of its own | Yes |
| `gt` | HTML + CSS | Yes, via this extension's filter |
| `kableExtra`'s `kbl()` | HTML | No — Quarto refuses to render it |
| `flextable` | a raster PNG | No |

Only one of those failures announces itself, so if a table looks wrong:

| Symptom | Cause |
|---------|-------|
| Render aborts, *"Functions that produce HTML output…"* | `kableExtra::kbl()` |
| Table is tiny — roughly a third of the body size | A CSS font size survived; see the escape hatches below |
| Table is blurry when you zoom the PDF | `flextable` — it is a PNG, not text |
| Table is the right size but the wrong colors | `table-css` set to `size-only` or `keep` |
| Rules doubled above the header or under the last row | A table drawing its own rules that this template did not recognise; file an issue |

**`tinytable` is the recommendation for R tables** — `tt()` emits a native
Typst table that inherits the poster body size and picks up the theme's header
color and booktabs rules. Pipe tables and `knitr::kable()` are equally safe and
need no package.

**`gt` works and picks up the theme.** It emits HTML carrying a screen's worth
of CSS: a pixel font size that Quarto's Typst writer would turn into an
absolute `12pt` — under half a 27pt A1 body, with no warning at render time —
plus gt's own greys, borders and pixel padding. This extension drops the
properties the poster theme should be deciding (type, color, rules, spacing)
so a `gt` table renders the same as a pipe table. Column alignment and
`font-variant-numeric: tabular-nums` are deliberately kept, which is why this
strips by property name rather than using Quarto's all-or-nothing
`css-property-processing: none`.

If you styled a `gt` table on purpose and want that styling on the poster, set
`table-css` (below) to keep it.

**`kableExtra`'s `kbl()` does not render at all.** Quarto stops the render with
*"Functions that produce HTML output found in document targeting typst
output"* before any filter runs, so this extension cannot rescue it. Passing
`format = "markdown"` sidesteps the guard by emitting a pipe table, but that
discards the `kable_styling()` work that is the reason to reach for the
package. `knitr::kable()` on its own is unaffected.

**`flextable` rasterizes.** Its Typst output is a PNG, which cannot inherit
the body size and will pixelate at A0.

`table-css` under `poster:` controls how much of an HTML table's CSS is
dropped:

| Value | Effect |
|-------|--------|
| `theme` (default) | Drop type, color, rules and spacing — the table looks like the poster |
| `size-only` | Drop just the font size — keeps the package's own look, at a readable size |
| `keep` | Drop nothing |

Alignment survives all three. `size-only` is the setting for a table you
styled deliberately; `keep` will produce a table nobody can read from the
aisle, so reach for it only to diagnose something.

Dropping a font size passes without comment — nobody sets `12px` meaning
"illegible at two metres". Dropping colors or borders prints a warning at
render time, since that styling may well have been deliberate:

```
sciposter: replaced a table's own colors, borders or spacing with the poster
theme. Set `table-css: size-only` under `poster:` to keep the table's styling
at a readable size.
```

Per-table rather than per-poster, `typst:text:size` on an individual table
sizes that one deliberately and exempts it from all of the above.

Keep poster tables to about six rows and four columns. Past that, draw it.

See `examples/tables.qmd`.

## References

Add `bibliography: refs.bib` and cite as usual. Place the section anywhere:

```markdown
# References

::: {#refs}
:::
```

`poster.refs` controls presentation: `flow` (compact text), `box` (framed),
`none` (suppress the bibliography entirely — omit the heading and div too).
Swap citation styles with the standard `csl:` key.

## Overflow protection

A poster is one page. If content is lost, the render paints a loud red
**CONTENT OVERFLOW** banner on the poster instead of dropping text silently.
Fix by trimming content, adding columns, or growing the poster size.

Two things can go wrong, and the banner names which:

- **“text below this page’s edge is CUT OFF”** — the body outgrew the columns
  region and kept drawing past its bottom, over the footer bar or off the
  page.
- **“text is HIDDEN BEHIND a full-width float”** — a bottom-pinned
  `.full-width` block shortens the columns region, and the body ran into the
  space the float occupies. The float is painted on top, so the text is
  invisible even though the poster is still one page and nothing reaches the
  page edge. This is the quiet one: a poster in this state looks finished.

## Examples

- [`template.qmd`](template.qmd) — 48×36 landscape, UNL theme, logos, boxes
- [`examples/a0-portrait.qmd`](examples/a0-portrait.qmd) — A0 portrait, generic theme, references
- [`examples/r-figures.qmd`](examples/r-figures.qmd) — ggplot2 figures in columns and full-width
- [`examples/python.qmd`](examples/python.qmd) — matplotlib, seaborn and plotnine under the Jupyter engine
- [`examples/qr-codes.qmd`](examples/qr-codes.qmd) — QR codes at several sizes, with labels
- [`examples/tables.qmd`](examples/tables.qmd) — table styling and the HTML/CSS font-size trap
- [`examples/template-controls.qmd`](examples/template-controls.qmd) — theme overrides, code sizing, surfaces, grid alignment

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).
