# Changelog

Notable changes to this extension. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[semantic versioning](https://semver.org/spec/v2.0.0.html).

The version in `_extensions/sciposter/_extension.yml` and the git tag are two
records of the same fact — Quarto reads the file, users read the tag. Bump the
file, commit, then tag to match.

## [Unreleased]

Nothing yet.

## [0.7.0] — 2026-08-06

### Added

- `poster.title-sizes` — a `{subtitle, author, affiliation}` map of the three
  type sizes under the poster title, merged over their defaults so naming one
  leaves the other two alone. Same shape as `title-gaps`, deliberately.

  It exists because those three defaults are ratios of two *different* bases:
  the subtitle rides `title-font-size` at `0.58 ×`, while the byline and
  affiliations ride `base-font-size` at `1.25 ×` and `0.95 ×`. Neither base can
  lift the byline alone — raising `base-font-size` to reach an author-line
  minimum resizes the whole poster, and `theme-overrides` cannot help because
  these are explicit `size:` arguments at the call site, which beat anything
  merged into `title-text-args`.

  The case that produced it: UNL's poster template specifies 48–80 pt for the
  subtitle and author line, and a poster set at 32 pt body could not reach it
  from any existing option.

### Unchanged

A poster that sets no `title-sizes` renders byte-identically to 0.6.0 —
verified by pixel diff for `template.qmd`, `a0-portrait`, `tables`,
`template-controls` and `qr-codes`. The defaults are the same expressions that
were previously inline.

## [0.6.0] — 2026-08-06

Three layout knobs, taken from a real fork. The AFS 2026 poster had been
carrying these as local edits to its vendored copy of the template because
nothing in a `.qmd` could reach them; with this release its fork is empty.

### Added

- `poster.heading-align` — `left` (default), `center` or `right` for the
  level-1 section bars.
- `poster.stats-align` — the same, for the cells of an evidence strip.
- `poster.title-gaps` — a `{subtitle, author, affiliation}` map of the three
  gaps running down the title bar, defaulting to `0.2in` / `0.35in` /
  `0.18in`. The map merges over the defaults, so naming one gap leaves the
  others alone.

  Named gaps rather than one scale factor: a poster that has to tighten the
  title bar rarely tightens it evenly. The case that produced this had six
  authors, and the gap before the byline and the gap before the affiliations
  wanted different numbers.

An invalid alignment stops the render with a named error rather than falling
back to `left`. A silently wrong alignment on a poster gets noticed at the
printer.

### Why these are poster options and not `theme-overrides`

`theme-overrides` merges a dict INTO a dict (`th.at(key) + value`), so a bare
alignment or length has no way through it. Beyond that, `heading-text-args` is
spread into `text()`, which has no alignment parameter — the centring has to
happen at the call site, one level out. They sit alongside `block-gap` and
`logo-height`, which are the same kind of thing: layout, not colour.

### Unchanged

A poster that sets none of the three renders byte-identically to 0.5.0 —
verified by pixel diff for `template.qmd`, `a0-portrait`, `tables`,
`template-controls` and `qr-codes`. The `left` case returns its content
unwrapped rather than passing through `align(left, ..)`, which is what keeps
that true.

## [0.5.0] — 2026-08-06

One control, and two holes in CI that adding it exposed.

### Added

- `::: {.qr offset="0.25in"}` nudges a QR code down inside its layout cell; a
  negative value moves it up.

  It is there for one job: pairing a code with a logo whose artwork carries
  transparent canvas, where `layout-valign="center"` centres the two *blocks*
  and therefore does not centre the two visible squares. This cannot be
  automated — Typst cannot inspect an image's alpha channel, so nothing can
  find where the visible ink starts. The number is set by eye against a render,
  and the option exists so that doing so does not mean dropping raw Typst into
  the document.

  Implemented as `pad(top:)`, not `move(dy:)`. Padding reserves the height, so
  a nudge that pushes a code past the bottom of the fixed-height body row trips
  the overflow guard. `move` would slide the code out of the row without a
  word, which is the exact failure this template spent 0.3.0 fixing.

### Fixed

- The CI overflow checks could pass on a poster that had overflowed. They
  grepped for the phrase `CONTENT OVERFLOW`, but the banner is drawn across the
  body, so `pdftotext` interleaves it with the text it crosses and returns the
  phrase split over two lines — `…the only thing onCONTENT` / `OVERFLOW`. A PDF
  visibly showing the banner matched zero times. The checks now match the bare
  token `OVERFLOW`, which interleaving cannot split.
- `examples/qr-codes.pdf` is now checked for overflow. It had only a page-count
  check, which cannot catch this: the body is a fixed-height row, so a poster
  that spills draws over its own footer and still reports one page.

### Unchanged

A poster that sets no `offset` renders byte-identically to 0.4.0 —
verified by pixel diff for `template.qmd`, `a0-portrait`, `tables`,
`template-controls`, and the previous `qr-codes` content.

## [0.4.0] — 2026-08-06

Poster-level hierarchy, code, and layout controls. Everything below was
previously reachable only by forking the template.

### Added

- `poster.theme-overrides` names any theme element directly:
  `heading-box-args`, `title-text-args`, `stat-value-text-args` and the rest.
  Entries merge into the element rather than replacing it, so naming a size
  does not drop the font and fill the theme already set, and computed sizes
  stay merged *under* the theme dict so an explicit `size:` wins over the
  built-in `1.6 ×` heading relationship.

  This is what makes a scarlet title bar above navy section bars expressible
  from a `.qmd`. `title-*-args` and `heading-*-args` were always separate
  elements — they were just never reachable.

  Values are read by shape: `"#0D3B66"` is a colour, `"40pt"` a length,
  `"50%"` a ratio, a YAML map a dictionary (which is how strokes and insets
  are written), anything else a string. The conversion happens in the Lua
  filter and reaches Typst as a `RawInline`, because an interpolated
  `MetaString` is escaped by the Typst writer and arrives as a string rather
  than as code.

- `poster.code-fonts`, `poster.code-font-size` and `poster.code-ligatures`.
  All three are unset by default and setting none of them changes nothing:
  code keeps Typst's own mono face at body size, which is what every poster
  written before this did. `code-ligatures` is a three-state — absent leaves
  the font's own setting alone, `false` turns them off, `true` forces them on.

- `poster.block-gap` sets one vertical gap above and below every styled block.
  The theme ships an asymmetric default on headings; this deliberately
  flattens it, and `theme-overrides` still wins for a single exception.

- `::: {.poster-surface}` groups content on a tint without colouring a whole
  column, and `::: {.poster-image-frame}` is the same block with a rule and a
  mat — which is what keeps a dark cover from printing as a muddy block
  against a pale poster. Attributes: `tint`, `ink`, `pad`, `radius`, `border`.

  `ink` exists because a dark `tint` is otherwise a trap: markdown has no
  other way to reach the text colour inside a block.

- `::: {.poster-grid}` lays its children out as real grid cells instead of
  flowing them, so a row is a row. `cols` for equal fractions, `widths` for
  explicit tracks, `gutter` / `row-gutter` for spacing.

  This is the honest answer to aligning content across columns. `columns()` is
  a single stream with no cross-column anchor, so alignment in *flowing*
  content is not something a setting can deliver; the grid gets it by leaving
  the flow model.

  Cell splitting runs in its own top-down filter pass. Pandoc visits divs
  bottom-up, so a `.poster-surface` used as a cell would already be three
  blocks — an opening raw block, its content, a closing one — and each would
  be split off as a cell of its own.

### Known limitation

Inline code on a dark `tint` stays dark. Quarto's syntax highlighter emits
every token with an explicit fill, and an explicit fill on the inner element
beats `ink`. Use bold rather than backticks there.

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

[Unreleased]: https://github.com/chrischizinski/quarto-sciposter/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.7.0
[0.6.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.6.0
[0.5.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.5.0
[0.4.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.4.0
[0.3.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.3.0
[0.2.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.2.0
[0.1.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.1.0
