# Changelog

Notable changes to this extension. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[semantic versioning](https://semver.org/spec/v2.0.0.html).

The version in `_extensions/sciposter/_extension.yml` and the git tag are two
records of the same fact — Quarto reads the file, users read the tag. Bump the
file, commit, then tag to match.

## [Unreleased]

Nothing yet.

## [0.3.0] — 2026-08-06

Four changes that came out of a design review of a real 48x36 poster. Each is
something the review asked for that the extension had no way to express, so
the poster could not be fixed in its `.qmd` alone.

### Added

- `::: {.stats}` renders an evidence strip: the 3-4 numbers a reader should
  take without entering the prose. One paragraph per cell, `**value** label`.
  An optional `label="..."` puts a kicker above the row.

  Equal columns at `base-font-size: 28pt` in a 14.7in column give each of four
  cells about 18 characters of label before it wraps. Four cells is the
  practical maximum on a three-column 48x36; five wraps every label.

- `::: {.takeaway .quiet}` keeps the takeaway type scale on the theme's warm
  surface instead of a filled primary panel. For a closing endpoint on a
  poster whose one loud takeaway is already spent.

- `::: {.full-width position="bottom"}` pins a full-width float to a page edge.
  `full-width` already took `position:` in Typst; the filter never passed it,
  so every float got `auto` and Typst chose the nearer edge.

  Worth knowing before reaching for it: a parent-scoped float costs its height
  *plus* 0.4in of clearance out of **every** column, not out of one. On a
  three-column 48x36 a 1.5in strip removes 5.7in of column content.

### Fixed

- The overflow detector now catches content hidden behind a bottom-pinned
  `.full-width` float, and reports it with its own message. A bottom float
  shortens the columns region, but the body sits in a fixed-height grid row
  that Typst will not clip, so column text that outgrows the region keeps
  drawing straight under the float — which is painted over it. The poster
  stays one page and nothing reaches the page edge, so the guard was silent
  while a heading and a paragraph went missing from `template.qmd`.

  `full-width` now records its vertical span, and the body ending inside that
  span is the collision test.

- The plain-overflow branch compares against the bottom of the columns region
  rather than the bottom of the page. Content could previously spill several
  inches past the columns, drawing over the footer bar, and still measure as
  fine. The reference comes from a marker placed on the body block's inner
  edge, so an optional footer of any height needs no arithmetic.

- `tests/overflow-float.qmd` is the positive control for the float branch;
  `template.qmd` carries a bottom float that fits and is the negative one.
  Both run in `render-check`.

### Changed

- QR labels moved from `0.65em` to `0.75em`, the poster's own caption tier. A
  QR code is the one element on a printed poster a reader can act on, and its
  label has to survive at the distance they are standing when they decide to
  scan. This is a 15% increase on one short line, so reflow risk is small, but
  it does change existing output.

## [0.2.0] — 2026-08-06

### Added

- `poster.credit` prints a small "Built with quarto-sciposter" line in a bottom
  corner. `true` uses the bottom right; `bottom-left` and `bottom-right` choose
  one. Off by default, so upgrading adds nothing to an existing poster. It
  clears the footer bar when one is present.

  Only the bottom corners are offered — the top edge of a poster is the title
  bar, where a muted line disappears into the accent fill.

## [0.1.0] — 2026-08-05

First release.

### Added

- Poster layout engine: configurable page size (named `a0`–`a4`, or `WxH` in
  inches), column count, and a `unl` or generic theme.
- Body size derived from poster width when `base-font-size` is unset, with
  `title-font-size` following at `2.3 ×` body.
- `.poster-box`, `.takeaway`, `.alert` and `.full-width` block types, plus
  `.col-break` for manual column breaks.
- QR codes through a `.qr` div, with optional `size` and `label`. Resolves the
  `tiaoma` Typst package.
- `brand.yml` support for palette and fonts.
- References placed anywhere in the flow via `::: {#refs}`, styled `flow`,
  `box`, or suppressed with `none`.
- Footer slots (`footer.left`, `footer.right`) and top-level `logos.left` /
  `logos.right`.
- Draft mode: a diagnostics panel overlaid on the render.
- Overflow warning printed onto the poster when content does not fit the page.
- `poster.palette` for figure series colors, defaulting to Okabe-Ito, readable
  from R and Python so the YAML is a single source.
- Tables inherit the poster body size and are drawn booktabs-style: a rule
  above the header, one below it, one under the last row, nothing else.
- `poster.table-css` controls how much CSS an HTML table keeps — `theme`
  (default), `size-only`, or `keep`.
- Examples: `template.qmd`, `a0-portrait`, `qr-codes`, `tables`, `r-figures`,
  `python`.
- CI renders the pure-markdown posters and checks page dimensions, page counts,
  and that no table carries an absolute font size — with a negative-control
  fixture (`tests/table-guard.qmd`) proving that check can still fail.

### Notes on table and figure sources

Established by rendering each through the extension rather than from
documentation:

| Source | Emits | Poster-safe |
|--------|-------|-------------|
| Pipe table, `knitr::kable()` | Typst table, no size of its own | Yes |
| `tinytable` | Typst table, no size of its own | Yes |
| `gt`, `great_tables` | HTML + CSS | Yes, mapped onto the theme |
| `kableExtra`'s `kbl()` | HTML | No — Quarto aborts the render |
| `flextable` | a raster PNG | No — pixelates at A0 |

An HTML table's CSS is stripped by property name rather than with Quarto's
all-or-nothing `css-property-processing: none`, so column alignment and
`font-variant-numeric: tabular-nums` survive. Dropping a font size is silent;
dropping colors or borders warns once per render, since that may have been
deliberate.

Under the Jupyter engine, per-chunk `fig-width` is ignored while the
document-level option works, and `poster.palette` must be read out of the front
matter — there is no `rmarkdown::metadata` equivalent. See `examples/python.qmd`.

[Unreleased]: https://github.com/chrischizinski/quarto-sciposter/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.2.0
[0.1.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.1.0
