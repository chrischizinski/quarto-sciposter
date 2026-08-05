# Changelog

Notable changes to this extension. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[semantic versioning](https://semver.org/spec/v2.0.0.html).

The version in `_extensions/sciposter/_extension.yml` and the git tag are two
records of the same fact — Quarto reads the file, users read the tag. Bump the
file, commit, then tag to match.

## [Unreleased]

Nothing yet.

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

[Unreleased]: https://github.com/chrischizinski/quarto-sciposter/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/chrischizinski/quarto-sciposter/releases/tag/v0.1.0
