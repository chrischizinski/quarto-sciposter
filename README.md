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
| `logo-height` | `1.5in` | Height of every title-bar logo |
| `footer` | — | String (centered) or `{left, center, right}` map |
| `refs` | `flow` | `flow` \| `box` \| `none` (see References) |
| `fig-max-height` | `45%` | Height cap for auto-sized figures, as fraction of column height |
| `base-font-size` | `24pt` | Body text size |
| `title-font-size` | `72pt` | Poster title size |

`logos.left` / `logos.right` (top-level keys) take lists of image paths —
as many as fit.

## Layout control (fenced divs)

| Div | Effect |
|---|---|
| `::: {.full-width}` | Contents span every column (floats to top or bottom edge — Typst constraint) |
| `::: {.col-break}` | Force a column break |
| `::: {.poster-box title="..."}` | Framed box; add `.highlight` or `.alert` for variants |

## Figures

- Unsized figures (including R chunk output) fill their column width,
  capped at `fig-max-height` of the column so one figure can't consume a
  whole column.
- Explicit sizes always win: `fig-width`/`fig-height` chunk options, or
  `![...](img.png){width=50%}`.
- Wrap a figure in `.full-width` to span the poster.

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
