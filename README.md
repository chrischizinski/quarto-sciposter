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
| `brand` | `true` | Set `false` to ignore the project's `_brand.yml` |
| `logo-height` | `1.5in` | Height of every title-bar logo |
| `footer` | — | String (centered) or `{left, center, right}` map |
| `refs` | `flow` | `flow` \| `box` \| `none` (see References) |
| `fig-max-height` | `45%` | Height cap for auto-sized figures, as fraction of column height |
| `base-font-size` | auto | Body text size; derived from poster width if unset (see Typography) |
| `title-font-size` | auto | Poster title size; `2.3 ×` body size if unset |
| `palette` | theme default | Figure colors, shared with R chunks (see Figure colors) |
| `table-font-size` | `inherit` | `keep` leaves CSS font sizes on HTML tables alone (see Tables) |
| `draft` | `false` | Overlay a diagnostics panel on the render (see Draft mode) |

`logos.left` / `logos.right` (top-level keys) take lists of image paths —
as many as fit.

## Layout control (fenced divs)

| Div | Effect |
|---|---|
| `::: {.full-width}` | Contents span every column (floats to top or bottom edge — Typst constraint) |
| `::: {.col-break}` | Force a column break |
| `::: {.poster-box title="..."}` | Framed box; add `.highlight` or `.alert` for variants |
| `::: {.takeaway label="..."}` | Headline finding, sized to read from across the aisle; optional `scale="2.2"` |
| `::: {.qr url="..."}` | Scannable QR code; optional `size="2in"` and `label="..."` |

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
the theme. R cannot see the Typst theme's built-in palette, so declare
`poster.palette` explicitly when using R figures — that is what makes the YAML
the single source. See `examples/r-figures.qmd`.

Keep figure `base_size` high enough that axis text survives being scaled into
a column; it needs to be legible at the 1.5 m scan, not just in RStudio.

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

## Figures

- Unsized figures (including R chunk output) fill their column width,
  capped at `fig-max-height` of the column so one figure can't consume a
  whole column.
- Explicit sizes always win: `fig-width`/`fig-height` chunk options, or
  `![...](img.png){width=50%}`.
- Wrap a figure in `.full-width` to span the poster.

## Tables

Tables inherit the poster body size and are drawn booktabs-style: a rule
above the header, one below it, one under the last row, nothing else. A full
grid at poster stroke weights cages the numbers and reads as texture from
three metres away.

What a table package emits for Typst decides whether it works on a poster.

| Source | Emits | Poster-safe |
|--------|-------|-------------|
| Pipe table, `knitr::kable()` | Typst table, no size of its own | Yes |
| `tinytable` | Typst table, no size of its own | Yes |
| `gt` | Typst, hardcoded `12pt` | No |
| `flextable` | a raster PNG | No |

**`tinytable` is the recommendation for R tables** — `tt()` emits a native
Typst table that inherits the poster body size and picks up the theme's header
color. Pipe tables and `knitr::kable()` are equally safe and need no package.

**`gt` hardcodes a size this extension cannot reach.** It emits Typst
directly — `set text(font: (...), size: 12pt)` — rather than a table this
extension's filter can rewrite, and against a 27pt A1 body that is under half
the size, with no warning at render time. Use `tinytable` instead.

**`flextable` rasterizes.** Its Typst output is a PNG, which cannot inherit
the body size and will pixelate at A0.

**HTML tables lose their CSS size.** `kableExtra` and anything else emitting
HTML carry CSS sized for a screen, which Quarto's Typst writer turns into
absolute points. This extension drops `font-size` from table CSS so the table
inherits the body size; every other CSS property (colors, borders, alignment)
still reaches the writer, unlike Quarto's own `css-property-processing: none`,
which discards all of them.

Two escape hatches, neither a starting point:

- `table-font-size: keep` under `poster:` — leave all table CSS sizes alone.
- `typst:text:size` on an individual table — size that one deliberately.

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

A poster is one page. If content is cut off at the page edge, the render
paints a loud red **CONTENT OVERFLOW** banner on the poster instead of
losing text silently. Fix by trimming content, adding columns, or growing
the poster size.

## Examples

- [`template.qmd`](template.qmd) — 48×36 landscape, UNL theme, logos, boxes
- [`examples/a0-portrait.qmd`](examples/a0-portrait.qmd) — A0 portrait, generic theme, references
- [`examples/r-figures.qmd`](examples/r-figures.qmd) — ggplot2 figures in columns and full-width
- [`examples/qr-codes.qmd`](examples/qr-codes.qmd) — QR codes at several sizes, with labels
- [`examples/tables.qmd`](examples/tables.qmd) — table styling and the HTML/CSS font-size trap
