// sciposter — scientific poster layout engine for Quarto + Typst
//
// Layout model: fixed single page sized from `size`, laid out as a vertical
// grid of [title bar | body columns | optional footer bar]. Body content
// flows through columns(); `.full-width` divs escape to parent scope.

// ---------------------------------------------------------------------------
// Themes
// ---------------------------------------------------------------------------

// Figure palettes are Okabe-Ito, the standard colorblind-safe qualitative set,
// reordered per theme so the first series harmonizes with the poster chrome.
// Yellow (#F0E442) sits late: it is the one entry with poor contrast on white,
// so it should not be reached until a plot has 5+ series.
#let okabe-ito = (
  blue: "#0072B2",
  vermillion: "#D55E00",
  green: "#009E73",
  purple: "#CC79A7",
  orange: "#E69F00",
  sky: "#56B4E9",
  yellow: "#F0E442",
  black: "#000000",
)

#let default-fonts = ("Helvetica Neue", "Helvetica", "Arial", "Liberation Sans")

// A theme is a map of per-element `*-box-args` / `*-text-args` dictionaries
// (the peace-of-posters structure), not a flat colour map. Every styled element
// renders as `block(..th.<el>-box-args)` wrapping `text(..th.<el>-text-args)`,
// so a theme can reach any property of any element — stroke, radius, inset,
// tracking — instead of only the handful of colours a flat dict anticipated.
// It is also the shape partial overrides merge into: `theme-overrides` (and
// later `_brand.yml`) supply dicts that overlay the element they name, with no
// per-property plumbing in between.
//
// Sizes are deliberately absent. They derive from `base-font-size`, which is
// not known until render time, so sciposter() merges a computed `size` UNDER
// each text-args dict — a theme naming `size` explicitly still wins.
#let make-theme(
  primary: rgb("#1f4e79"),
  accent: rgb("#2e74b5"),
  bg: white,
  fg: rgb("#222222"),
  // Text drawn on top of a `primary`-filled surface: title bar, h1 bars,
  // takeaway, footer. Named separately so a light-primary theme can flip it.
  on-primary: white,
  box-bg: rgb("#f2f4f7"),
  stripe: none,
  fonts: default-fonts,
  // Headings default to the body face. Split so a theme (or `_brand.yml`'s
  // `typography.headings.family`) can give display type its own face.
  heading-fonts: none,
  code-fonts: none,
  palette: (),
) = {
  let body-font = (font: fonts)
  // EVERY text-args dict carries an explicit font, and it is not decoration.
  // With a `_brand.yml` present Quarto injects `#show heading: set text(font:
  // ...)` at top level, ahead of this template's own rules. An explicit `font`
  // argument on the text element beats any ambient set rule, so stating it
  // here makes each element's face deterministic instead of dependent on
  // show-rule ordering we do not control. Drop one and that element silently
  // renders in the brand face while the rest of the poster does not.
  let head-font = (font: if heading-fonts == none { fonts } else { heading-fonts })
  (
    palette: palette,

    page-args: (fill: bg),
    body-text-args: body-font + (fill: fg),
    caption-text-args: body-font + (fill: fg.lighten(25%)),
    link-text-args: (fill: accent),

    title-box-args: (fill: primary),
    title-text-args: head-font + (fill: on-primary),
    stripe-args: (fill: if stripe == none { accent } else { stripe }),

    heading-box-args: (
      fill: primary,
      inset: (x: 0.35in, y: 0.22in),
      radius: 6pt,
      above: 0.5in,
      below: 0.35in,
    ),
    heading-text-args: head-font + (fill: on-primary, weight: "bold"),
    subheading-box-args: (
      inset: (bottom: 0.1in),
      stroke: (bottom: 3pt + accent),
      above: 0.4in,
      below: 0.25in,
    ),
    subheading-text-args: head-font + (fill: accent, weight: "bold"),

    // poster-box `kind:` selects a `<kind>-box-args` overlay on top of the
    // base box. "default" names no overlay and so gets the base unchanged.
    box-args: (fill: box-bg, stroke: (left: 6pt + accent), radius: 4pt, inset: 0.3in),
    box-title-text-args: body-font + (fill: accent, weight: "bold"),
    highlight-box-args: (:),
    highlight-box-title-text-args: (:),
    alert-box-args: (fill: primary.lighten(85%), stroke: (left: 6pt + primary)),
    alert-box-title-text-args: (fill: primary),

    takeaway-box-args: (
      fill: primary,
      radius: 6pt,
      inset: 0.35in,
      above: 0.5in,
      below: 0.4in,
    ),
    takeaway-text-args: head-font + (fill: on-primary, weight: "bold"),
    takeaway-label-text-args: body-font
      + (fill: on-primary, weight: "medium", tracking: 0.08em),
    // `kind: "quiet"` — same type scale, inverted surface. For a closing band
    // that has to read as an endpoint without adding a second full-strength
    // primary panel to a poster that already has one.
    takeaway-quiet-box-args: (fill: box-bg),
    takeaway-quiet-text-args: (fill: primary),
    takeaway-quiet-label-text-args: (fill: fg.lighten(25%)),

    // Evidence strip: 3-4 numbers a reader can take from several feet away
    // without entering the prose. One shared surface, no per-cell border —
    // the fill is what groups them, so the cells stay unenclosed.
    //
    // `stat-value-text-args` takes `primary` deliberately. The value tier is
    // poster chrome, riding with the heading bars rather than with the data
    // marks in a figure, so a "reserve the brand colour for the one decision
    // in a plot" rule does not reach it.
    stats-box-args: (fill: box-bg, radius: 6pt, inset: 0.35in),
    stats-label-text-args: body-font
      + (fill: fg.lighten(25%), weight: "medium", tracking: 0.08em),
    stat-value-text-args: head-font + (fill: primary, weight: "bold"),
    stat-label-text-args: body-font + (fill: fg, weight: "medium"),

    // Deliberately EMPTY by default, and the emptiness is the feature: a
    // poster that names none of the code options must render exactly as it
    // did before these existed. Code inherits the body's fill and Typst's own
    // mono face, and it inherits the body SIZE, which is the size the prose
    // beside it is read at. `poster.code-font-size` sets one when the poster
    // wants code quieter than its paragraphs — 0.75 to 0.85 of body is the
    // usual choice on a large poster.
    //
    // Setting a fill here instead was tried and reverted: it repainted plain
    // (unhighlighted) code in the theme's ink on every existing poster.
    code-text-args: if code-fonts == none { (:) } else { (font: code-fonts) },

    // A grouping surface, and the same primitive with a border and a mat. The
    // frame exists for images: a dark cover or photograph dropped straight
    // onto a pale poster prints as a muddy block, and a thin rule plus an
    // inset of the warm surface is what separates it from the page.
    surface-box-args: (fill: box-bg, radius: 6pt, inset: 0.3in),
    frame-box-args: (
      fill: box-bg,
      radius: 6pt,
      inset: 0.2in,
      stroke: (paint: fg.lighten(70%), thickness: 1.5pt),
    ),

    // Booktabs rules, not a grid. Typst's default table boxes every cell,
    // which at poster stroke-to-type ratios reads as a cage and competes with
    // the numbers for attention. Horizontal rules alone let the eye track
    // across a row at 2m; verticals are what column alignment is for.
    //
    // The rules are split across two dicts because they come from two places:
    // Typst draws the header separator (Quarto emits a `table.hline()` of its
    // own after `table.header`), while the top and bottom rules are drawn by a
    // block wrapped around the table — a cell `stroke` closure is given only
    // `(x, y)` and so cannot tell which row is last.
    //
    // `table-rule-args` applies only to tables that do not rule themselves;
    // see the `show table` rule for how the two are told apart.
    table-args: (stroke: none, inset: (x: 0.5em, y: 0.45em), fill: none),
    table-rule-args: (stroke: (top: 1.2pt + fg, bottom: 1.2pt + fg)),
    table-header-text-args: body-font + (fill: accent, weight: "bold"),

    refs-box-args: (fill: box-bg, radius: 4pt, inset: 0.25in),
    footer-box-args: (fill: accent),
    footer-text-args: body-font + (fill: on-primary),

    // Deliberately quiet: a credit line is not poster content and must not
    // compete with it at reading distance. Sized off the body rather than
    // fixed, so it stays proportionally small on an A0 as on an A4.
    credit-text-args: body-font + (fill: fg.lighten(45%)),
  )
}

// Themes are stored as the *scalar arguments* to make-theme, not as built
// themes, so brand values and explicit poster overrides can be merged in
// before the theme is constructed. Building first would mean patching derived
// args after the fact — `accent` alone feeds six different elements.
#let theme-specs = (
  generic: (
    palette: (
      okabe-ito.blue, okabe-ito.vermillion, okabe-ito.green, okabe-ito.purple,
      okabe-ito.orange, okabe-ito.sky, okabe-ito.yellow, okabe-ito.black,
    ),
  ),
  unl: (
    primary: rgb("#D00000"),
    accent: rgb("#A50000"),
    fg: rgb("#242021"),
    box-bg: rgb("#F5F1E7"),
    stripe: rgb("#F5F1E7"),
    palette: (
      okabe-ito.vermillion, okabe-ito.blue, okabe-ito.green, okabe-ito.purple,
      okabe-ito.orange, okabe-ito.sky, okabe-ito.yellow, okabe-ito.black,
    ),
  ),
)

// `_brand.yml` -> make-theme scalars. Quarto emits `brand-color` into Typst
// scope (always — `(:)` when the project has no brand), and brand typography
// arrives separately as Pandoc template variables, so both are passed in.
//
// The mapping is deliberately partial. Two brand properties are NOT taken:
//   - `typography.base.size`: a brand's base size is an article size (11pt or
//     so). Poster body size is derived from the page dimensions, and letting
//     an 11pt document default through would flatten the whole type scale.
//   - `typography.headings.color`: our headings are reversed white on a filled
//     primary bar, whereas a brand heading colour assumes dark-on-light. It
//     would render invisible. `primary` already carries the brand's identity
//     into the heading bar.
#let brand-spec(colors: (:), fonts: none, heading-fonts: none) = {
  let spec = (:)
  if "primary" in colors { spec.insert("primary", colors.primary) }
  if "secondary" in colors { spec.insert("accent", colors.secondary) }
  if "background" in colors { spec.insert("bg", colors.background) }
  if "foreground" in colors { spec.insert("fg", colors.foreground) }
  if fonts != none { spec.insert("fonts", fonts) }
  if heading-fonts != none { spec.insert("heading-fonts", heading-fonts) }
  spec
}

// Set by sciposter() so helper functions (poster-box) can read theme args.
#let _theme = state("sciposter-theme", make-theme())

// Horizontal alignment arrives from YAML as a string, and Typst has no
// string-to-alignment parser. A typo panics rather than quietly falling back
// to `left`: the wrong alignment on a poster is the kind of thing that is only
// noticed at the printer.
#let _h-align(name) = if name == "left" { left } else if name == "center" {
  center
} else if name == "right" {
  right
} else {
  panic("alignment must be \"left\", \"center\" or \"right\"; got \"" + name + "\"")
}

// ---------------------------------------------------------------------------
// Size resolution
// ---------------------------------------------------------------------------

// Named sizes are stored portrait (width < height).
#let named-sizes = (
  "a0": (33.11in, 46.81in),
  "a1": (23.39in, 33.11in),
  "a2": (16.54in, 23.39in),
)

#let resolve-size(size, orientation) = {
  let dims = if type(size) == str and lower(size) in named-sizes {
    named-sizes.at(lower(size))
  } else if type(size) == str and size.contains("x") {
    let parts = size.split("x")
    (float(parts.at(0).trim()) * 1in, float(parts.at(1).trim()) * 1in)
  } else {
    (48in, 36in)
  }
  let (w, h) = dims
  if orientation == "landscape" and h > w { (h, w) } else if (
    orientation == "portrait" and w > h
  ) { (h, w) } else { (w, h) }
}

// ---------------------------------------------------------------------------
// Typography sizing
// ---------------------------------------------------------------------------

// Body size for the named A-series is taken from peace-of-posters, whose
// layout tables are tuned against real printed posters rather than derived.
// They run 10-25% larger than a first-principles angular-size calculation
// (pt ~= 25 x reading distance in metres, calibrated on 10pt book type at
// 40cm), and the gap is in the safe direction: conference halls are dim and
// posters are read by people who have been standing for hours, so erring
// large costs nothing. Two independent derivations agree on the *ratios*
// between tiers, which is why only the base is table-driven.
#let named-body-sizes = (
  "a0": 33pt,
  "a1": 27pt,
  "a2": 20pt,
  "a3": 14pt,
)

// Custom sizes use a linear fit through those values, pt = 4.9 + 0.88 x
// width_in, clamped hard. The fit is only calibrated over a3-a0, and reading
// distance stops growing once a poster is wall-sized — a reader steps to
// roughly the same distance for any large poster. Left unclamped the fit
// would hand a 48in poster 48pt body text.
#let auto-base-size(size, page-w) = {
  let key = if type(size) == str { lower(size) } else { "" }
  if key in named-body-sizes {
    named-body-sizes.at(key)
  } else {
    let s = 4.9 + 0.879 * (page-w / 1in)
    calc.clamp(calc.round(s / 2) * 2, 14, 36) * 1pt
  }
}

// Distance a given size is comfortable at, inverting the rule above. Used by
// the draft panel to report what each tier is actually sized for.
#let reading-distance(size) = (size / 1pt) / 25.0

// Characters per line. The constant 160 is measured from this template's own
// output (Helvetica-class text averages ~0.45em per character at poster
// sizes), not assumed — re-measure if a theme changes to a narrower face.
#let chars-per-line(col-w, size) = 160.0 * (col-w / 1in) / (size / 1pt)

#let column-width(page-w, margin, n-columns, gutter) = (
  (page-w - 2 * margin - (n-columns - 1) * gutter) / n-columns
)

// ---------------------------------------------------------------------------
// Body helpers (targets for the Lua div-mapping filter)
// ---------------------------------------------------------------------------

// Span all columns: parent-scoped float inside columns().
// Floats can only land at the top or bottom of the page body (Typst
// limitation); default lets Typst pick the nearer edge.
//
// The two markers record the float's vertical span for the overflow detector
// in the page background. They are the span and not just a position because
// column content that outgrows its region draws *over* a bottom-pinned float
// rather than past the page edge — "did the body end inside a float?" is the
// only way to see that, and a single marker cannot tell a bottom float (which
// content must stay above) from a top one (which it must stay below).
//
// Both go through `place`, which contributes no size, so a poster that never
// reads them lays out exactly as it did before they existed.
#let full-width(position: auto, body) = context {
  place(
    position,
    scope: "parent",
    float: true,
    clearance: 0.4in,
    block(width: 100%, {
      place(top + left, [#metadata("float") <sciposter-float-top>])
      body
      place(bottom + left, [#metadata("float") <sciposter-float-bottom>])
    }),
  )
}

#let poster-box(title: none, kind: "default", body) = context {
  let th = _theme.get()
  let box-args = th.box-args + th.at(kind + "-box-args", default: (:))
  let title-args = (
    th.box-title-text-args + th.at(kind + "-box-title-text-args", default: (:))
  )
  block(
    width: 100%,
    breakable: false,
    ..box-args,
    {
      if title != none {
        text(..title-args, title)
        v(0.15in)
      }
      body
    },
  )
}

// A tinted container for grouping related content, and — as `kind: "frame"` —
// the same block with a border and a mat around an image.
//
// Every argument defaults to `none` meaning "not given", not "no fill": the
// theme's value survives unless the author names a replacement, so
// `::: {.poster-surface}` with no attributes is the themed surface.
#let poster-surface(
  kind: "surface",
  tint: none,
  ink: none,
  pad: none,
  radius: none,
  border: none,
  body,
) = context {
  let th = _theme.get()
  let args = th.at(kind + "-box-args")
  if tint != none { args.insert("fill", tint) }
  if pad != none { args.insert("inset", pad) }
  if radius != none { args.insert("radius", radius) }
  if border != none {
    // A bare colour means "a rule in this colour at the theme's weight";
    // anything else is passed to Typst as given.
    args.insert("stroke", if type(border) == color {
      (paint: border, thickness: 1.5pt)
    } else { border })
  }
  // `ink` exists because a dark `tint` is otherwise a trap: markdown has no
  // other way to reach the text colour inside a block, so a navy surface
  // would print body-coloured text on itself with no way out but a fork.
  block(
    width: 100%,
    breakable: false,
    ..args,
    if ink != none { text(fill: ink, body) } else { body },
  )
}

// Explicit grid cells, as against the column flow the body normally uses.
//
// This is the one thing columns() cannot express. A poster column is a single
// stream: two columns line up only when their content happens to fill to the
// same height, and nothing an author writes makes that reliable. Cells in a
// grid row share a row because they are a row. Wrap the div in `.full-width`
// to align across the whole poster rather than inside one column.
//
// `widths` wins over `cols` when both are given — it is the more specific
// statement, and the asymmetric case (a narrow label column beside a wide
// diagram) is why it exists.
#let poster-grid(
  cols: 2,
  widths: none,
  gutter: 0.5in,
  row-gutter: none,
  align: top,
  ..cells,
) = {
  grid(
    columns: if widths != none { widths } else { (1fr,) * cols },
    column-gutter: gutter,
    row-gutter: if row-gutter == none { gutter } else { row-gutter },
    align: align,
    ..cells.pos(),
  )
}

// The 3-metre hook: the one element a passer-by should read from across the
// aisle. Sized as a multiple of base rather than a fixed point size so it
// tracks the poster's scale; `scale: 3.0` on an a0 lands near the 75pt that
// reads at 3m. Deliberately loud — a poster with two of these has none.
//
// `kind:` overlays a `takeaway-<kind>-*-args` dict on each of the three arg
// sets, the same way poster-box's kind works. "default" names no overlay, so
// a takeaway written before this existed renders unchanged.
#let takeaway(scale: 2.2, label: none, kind: "default", body) = context {
  let th = _theme.get()
  let base = text.size
  let overlay(name) = (
    th.at("takeaway-" + name + "-args")
      + th.at("takeaway-" + kind + "-" + name + "-args", default: (:))
  )
  block(
    width: 100%,
    breakable: false,
    ..overlay("box"),
    {
      set par(justify: false, leading: 0.5em)
      if label != none {
        text(..(size: 0.9 * base) + overlay("label-text"), upper(label))
        v(0.18in)
      }
      text(..(size: scale * base) + overlay("text"), body)
    },
  )
}

// Evidence strip: the 3-4 numbers a reader should take without entering the
// prose. Each cell is one paragraph, `**value** rest-of-line`.
//
// The value tier is reached through a `show strong` rule rather than a
// separate argument so a cell stays ordinary markdown — the Lua filter only
// has to hand each block over as a positional argument, with no inline
// parsing.
//
// Columns are equal fractions of the strip, which at `base-font-size: 28pt`
// in a 14.7in column gives each of four cells roughly 18 characters of label
// before it wraps. Four is the practical maximum on a three-column 48x36;
// five wraps every label.
#let stats-grid(label: none, ..cells) = context {
  let th = _theme.get()
  let base = text.size
  let items = cells.pos()
  block(
    width: 100%,
    breakable: false,
    ..th.stats-box-args,
    {
      set par(justify: false, leading: 0.5em)
      if label != none {
        text(..(size: 0.9 * base) + th.stats-label-text-args, upper(label))
        v(0.25in)
      }
      grid(
        columns: (1fr,) * items.len(),
        // Tighter than the poster's section gutter: cells are already told
        // apart by the value tier, and the extra width buys each label a
        // second word before it wraps.
        column-gutter: 0.35in,
        // Left by default. Centred cells read better when the values are the
        // point and the labels are short, which is the usual evidence strip;
        // left reads better when the labels run to a second line.
        align: top + th.at("stats-align", default: left),
        ..items.map(cell => {
          // A linebreak after the value keeps it on its own line without
          // asking the author to write one; the label then wraps beneath it.
          show strong: it => {
            text(..(size: 2.0 * base) + th.stat-value-text-args, it.body)
            linebreak()
          }
          text(..th.stat-label-text-args, cell)
        }),
      )
    },
  )
}

// A QR code is the only affordance a printed poster has — the one element a
// reader can act on. Generated from the URL rather than pasted as an image so
// it cannot drift out of sync, and vector so it stays sharp at any print size.
//
// The tiaoma import is scoped inside the function on purpose: Typst resolves
// package imports lazily, so a poster that never places a QR never downloads
// the package. Verified — an uncalled scoped import leaves the cache untouched.
//
// 1.5in is the practical floor for a phone to lock on from arm's length; the
// default is above it. Below that the code is decorative, not usable.
//
// `offset` nudges the whole helper down inside its layout cell. It exists
// because optical centring cannot be automated: Typst cannot inspect an
// image's alpha channel, so it cannot trim the transparent canvas off a logo
// and align its visible centre with a neighbouring QR. `layout-valign` centres
// the blocks, which is not the same thing once one of them is mostly padding.
// A hand-set nudge is the only route, so it is offered rather than implied.
#let poster-qr(url, size: 2in, label: none, offset: 0pt) = context {
  import "@preview/tiaoma:0.3.0": qrcode
  let th = _theme.get()
  // Sizing is delegated to the body `show image` rule, which already rebuilds
  // unsized images to fill their container: a plain box of the target width is
  // enough. Sizing it here instead — via Typst `scale()` or zint's own scale
  // option — fights that rule and lands at the wrong size.
  let code = box(width: size, qrcode(url))
  let body = align(center, block(breakable: false, {
    code
    if label != none {
      v(0.1in)
      set par(justify: false, leading: 0.45em)
      // A QR caption is a caption: it rides the same tier as figure captions
      // (0.75 x base), not a tier of its own. It names the destination of the
      // one thing on the poster a reader can act on, so it has to survive at
      // the distance the reader is standing when they decide to scan.
      text(..(size: 0.75em, weight: "medium") + th.caption-text-args, label)
    }
  }))
  // `pad` rather than `move`: padding RESERVES the height, so a nudge that
  // pushes the QR past the bottom of a fixed-height body row is caught by the
  // overflow guard. `move(dy: ..)` would slide it out of the row silently.
  // The zero case returns the block untouched so an author who never sets
  // `offset` gets byte-identical output.
  if offset == 0pt { body } else { pad(top: offset, body) }
}

// References: compact type, ragged right. `kind: "box"` adds the poster-box
// frame. Applied via a show rule on the <refs> block citeproc emits (a Lua
// wrap can't work: filters run before citeproc fills the div). Place the
// section anywhere with an empty `::: {#refs}` div; the heading is the
// author's own (`# References`).
#let refs-section(kind: "flow", body) = context {
  let th = _theme.get()
  let inner = {
    set text(size: 0.7em)
    set par(justify: false)
    body
  }
  if kind == "box" {
    block(width: 100%, breakable: true, ..th.refs-box-args, inner)
  } else {
    inner
  }
}

// ---------------------------------------------------------------------------
// Main template
// ---------------------------------------------------------------------------

#let sciposter(
  title: none,
  subtitle: none,
  authors: (),
  affiliations: (),
  size: "48x36",
  orientation: none,
  n-columns: 3,
  gutter: 1in,
  margin: 1in,
  theme: "generic",
  theme-colors: (:),
  theme-overrides: (:),
  // Three layout knobs that `theme-overrides` cannot carry. That route merges
  // a dict INTO a dict (`th.at(key) + value`), so an alignment or a bare
  // length has no way through it — and `heading-*-args` are spread into
  // `text()`, which has no alignment parameter at all. They sit here with
  // `block-gap` and `logo-height` instead, which are the same kind of thing:
  // poster-level layout, not theme colour.
  heading-align: "left",
  subheading-align: "left",
  stats-align: "left",
  title-gaps: (:),
  title-sizes: (:),
  block-gap: auto,
  code-fonts: none,
  code-font-size: auto,
  code-ligatures: "",
  theme-fonts: none,
  theme-heading-fonts: none,
  brand-enabled: true,
  brand-colors: (:),
  brand-fonts: none,
  brand-heading-fonts: none,
  logos-left: (),
  logos-right: (),
  logo-height: 1.5in,
  footer-text: none,
  footer-left: none,
  footer-right: none,
  base-font-size: auto,
  title-font-size: auto,
  fig-max-height: 45%,
  refs-kind: "flow",
  palette: none,
  draft: false,
  credit: none,
  body,
) = {
  // Precedence: theme supplies the base, `_brand.yml` overrides what it
  // defines, explicit `poster.colors` / `poster.fonts` beat both. Brand has to
  // outrank the theme rather than the other way round: `theme` defaults to
  // "generic", so theme-wins would leave brand applying only to posters that
  // never named a theme, which is nearly none of them. `poster.brand: false`
  // opts out entirely.
  // `poster.colors` values arrive as strings; trimming "#" before re-adding it
  // accepts both "#1f4e79" and "1f4e79" regardless of what the filter left.
  let overrides = (:)
  for (key, value) in theme-colors {
    overrides.insert(
      key,
      if type(value) == str { rgb("#" + value.trim("#")) } else { value },
    )
  }
  if theme-fonts != none { overrides.insert("fonts", theme-fonts) }
  if theme-heading-fonts != none {
    overrides.insert("heading-fonts", theme-heading-fonts)
  }
  if code-fonts != none { overrides.insert("code-fonts", code-fonts) }
  let brand = if brand-enabled {
    brand-spec(
      colors: brand-colors,
      fonts: brand-fonts,
      heading-fonts: brand-heading-fonts,
    )
  } else { (:) }
  let spec = theme-specs.at(theme, default: theme-specs.generic)
  let th = make-theme(..spec + brand + overrides)

  // One vertical rhythm for every deliberate unit of information. The theme
  // ships an asymmetric default on headings — more air above a section bar
  // than below it — so this deliberately flattens that: a single gap is the
  // point of asking for one. `poster.theme-overrides` still wins, which is
  // how a poster keeps the uniform rhythm everywhere but one element.
  if block-gap != auto {
    for key in (
      "heading-box-args", "subheading-box-args", "takeaway-box-args",
      "stats-box-args", "box-args", "surface-box-args", "frame-box-args",
    ) {
      th.insert(key, th.at(key) + (above: block-gap, below: block-gap))
    }
  }

  // Element-level overrides, merged INTO the element rather than replacing
  // it: `heading-text-args: (size: 40pt)` must not drop the font and fill the
  // theme already set. This is what makes a scarlet title bar with quiet
  // section headings expressible without forking the template — title-*-args
  // and heading-*-args were always separate elements, they were just never
  // reachable from a .qmd.
  for (key, value) in theme-overrides {
    th.insert(key, th.at(key, default: (:)) + value)
  }

  let (page-w, page-h) = resolve-size(size, orientation)

  // An explicit YAML size always wins; `auto` derives from the page.
  let base-font-size = if base-font-size == auto {
    auto-base-size(size, page-w)
  } else { base-font-size }
  // 2.3x matches the title/body ratio peace-of-posters holds across every
  // size in its table (2.27-2.35). Absolute results agree closely with theirs
  // — 76pt at a0 against their 75pt — which is the cross-check that the ratio
  // and the recalibrated base are both right. Raise per poster if the title
  // is short; the draft panel reports the distance it actually reads at.
  let title-font-size = if title-font-size == auto {
    2.3 * base-font-size
  } else { title-font-size }

  // Author palette overrides the theme's; both feed R via YAML metadata.
  let palette = if palette == none { th.at("palette", default: ()) } else { palette }

  // Footer: single string centers; left/center/right slots for the 3-part
  // layout (event | contact | url etc.). Built before `set page` because the
  // credit line has to measure it to avoid printing on top of it.
  let footerbar = if (footer-text, footer-left, footer-right) != (none, none, none) {
    block(
      width: 100%,
      inset: (x: margin, y: 0.3in),
      ..th.footer-box-args,
      {
        set text(..(size: 0.9 * base-font-size) + th.footer-text-args)
        grid(
          columns: (1fr, auto, 1fr),
          column-gutter: 0.5in,
          align: (left + horizon, center + horizon, right + horizon),
          if footer-left != none { footer-left } else { [] },
          if footer-text != none { footer-text } else { [] },
          if footer-right != none { footer-right } else { [] },
        )
      },
    )
  } else { none }

  // Credit line: off unless asked for. `true` takes the default corner,
  // `bottom-left` / `bottom-right` choose one.
  //
  // Only the bottom corners are offered. The top edge of a poster is the
  // title bar, so a muted credit placed there either disappears into the
  // accent fill or competes with the title — neither is worth a config
  // option. An unrecognised value still prints, in the default corner,
  // rather than vanishing and leaving the author to wonder why.
  let credit-label = [Built with quarto-sciposter]
  let credit-align = if credit in (none, "false", "none") {
    none
  } else if credit == "bottom-left" {
    bottom + left
  } else {
    bottom + right
  }

  set page(
    width: page-w,
    height: page-h,
    margin: 0pt,
    ..th.page-args,
    // A poster is one page; overflowing body text is CLIPPED at the page
    // edge, not moved to page 2 — so losing it silently is the real hazard.
    // A zero-size marker sits at the very end of the body; if it laid out
    // past where the columns are allowed to end (or never laid out), content
    // was cut off. Warn loudly on the poster itself so it never slips through
    // to print.
    //
    // The reference is the bottom of the columns region, NOT the page bottom.
    // The body sits in a fixed-height grid row, and Typst does not clip a
    // block that outgrows it, so overflowing content keeps drawing — over the
    // footer bar, or over a bottom-pinned `.full-width` float — while staying
    // comfortably inside the page. Against `page-h` all of that reads as fine.
    background: context {
      let warn(msg) = place(
        top + center,
        dy: 0.35 * page-h,
        block(
          fill: rgb("#c00000"),
          inset: 0.4in,
          radius: 8pt,
          text(
            fill: white,
            weight: "bold",
            size: 48pt,
            // Hardcoded, not theme-derived: this warning has to render even
            // when the theme is what is broken.
            font: default-fonts,
            msg,
          ),
        ),
      )
      if here().page() > 1 {
        warn([CONTENT OVERFLOW — does not fit the poster page])
      } else {
        let m = query(<sciposter-end>)
        // Where the columns are allowed to end. Reported by a marker placed
        // on the body block's inner bottom edge, so an optional footer bar of
        // any height needs no arithmetic here.
        let edge = query(<sciposter-body-bottom>)
        let body-bottom = if edge.len() > 0 {
          edge.first().location().position().y
        } else { page-h }
        // A float the body ended *inside* is a collision: the float is drawn
        // on top, so whatever shares those coordinates is hidden. Tops and
        // bottoms are paired by index — `full-width` emits them together and
        // query() returns both lists in layout order.
        let tops = query(<sciposter-float-top>).map(f => f.location().position().y)
        let bottoms = query(<sciposter-float-bottom>).map(f => f.location().position().y)
        let inside-float(y) = tops.zip(bottoms).any(((t, b)) => y > t and y < b)
        // Two different diagnoses, so they get two different messages: one
        // says shorten the poster, the other says the full-width float is
        // eating the column it sits under.
        if m.len() == 0 or m.first().location().page() > 1 {
          warn([CONTENT OVERFLOW — text below this page's edge is CUT OFF])
        } else {
          let y = m.first().location().position().y
          if y > body-bottom {
            warn([CONTENT OVERFLOW — text below this page's edge is CUT OFF])
          } else if inside-float(y) {
            warn([CONTENT OVERFLOW — text is HIDDEN BEHIND a full-width float])
          }
        }
      }
    },
    // Draft diagnostics: opt-in via `poster.draft: true`, never in a final
    // render. Reports the two measurable constraints (line measure, and what
    // distance each type tier is actually sized for) so they can be judged
    // before printing rather than at the poster session.
    foreground: {
    // `context` because the credit measures the footer bar to clear it rather
    // than printing on top of it. With no footer that measures zero and the
    // credit sits on the bottom margin.
    if credit-align != none {
      context place(
        credit-align,
        dx: if credit-align.x == left { margin } else { -margin },
        dy: -0.3 * margin - measure(footerbar).height,
        text(..(size: 0.5 * base-font-size) + th.credit-text-args, credit-label),
      )
    }
    if draft {
      let col-w = column-width(page-w, margin, n-columns, gutter)
      let cpl = chars-per-line(col-w, base-font-size)
      let verdict = if cpl > 75 { ("OVER", rgb("#ff6b6b")) } else if cpl < 45 {
        ("UNDER", rgb("#ffd166"))
      } else { ("ok", rgb("#7bd88f")) }
      let row(k, v, c: white) = (
        text(fill: rgb("#9aa4b2"), k), text(fill: c, v),
      )
      let tier(name, sz) = row(
        name,
        str(calc.round(sz / 1pt)) + "pt \u{2192} " + str(calc.round(reading-distance(sz), digits: 1)) + "m",
      )
      // Vertically centred rather than top-right: any overlay hides
      // something, and body text can be checked in the .qmd whereas logo
      // placement and title-bar fit can only be judged by looking.
      place(
        horizon + right,
        dx: -0.4in,
        block(
          fill: rgb(17, 24, 39, 235),
          radius: 6pt,
          inset: 16pt,
          width: 20em,
          {
            set text(font: ("Menlo", "DejaVu Sans Mono", "Courier"), size: 11pt)
            set par(justify: false, leading: 0.5em)
            // place(right) propagates its alignment into the block.
            set align(left)
            text(fill: white, weight: "bold", size: 12pt, [SCIPOSTER DRAFT])
            v(8pt)
            grid(
              columns: (auto, 1fr),
              row-gutter: 5pt,
              column-gutter: 10pt,
              ..row("page", str(calc.round(page-w / 1in, digits: 1)) + " x " + str(calc.round(page-h / 1in, digits: 1)) + " in"),
              ..row("columns", str(n-columns) + " @ " + str(calc.round(col-w / 1in, digits: 2)) + " in"),
              ..row("measure", str(calc.round(cpl)) + " ch/line  " + verdict.at(0), c: verdict.at(1)),
              ..tier("title", title-font-size),
              ..tier("heading", 1.6 * base-font-size),
              ..tier("body", base-font-size),
              ..tier("caption", 0.75 * base-font-size),
            )
            v(8pt)
            if palette.len() > 0 {
              text(fill: rgb("#9aa4b2"), [palette])
              v(4pt)
              stack(
                dir: ltr,
                spacing: 3pt,
                ..palette.map(c => block(width: 14pt, height: 14pt, radius: 2pt, fill: rgb(c))),
              )
              v(8pt)
            }
            text(
              fill: rgb("#9aa4b2"),
              size: 9pt,
              [target 45-65 ch/line \u{00b7} word count: `pdftotext out.pdf - | wc -w` (aim under 800)],
            )
          },
        ),
      )
    }
    },
  )
  // Computed sizes go UNDER the theme dict throughout, so a theme (or an
  // override) that names `size` explicitly wins over the derived default.
  set text(..(size: base-font-size) + th.body-text-args)
  // Ragged right, not justified: poster columns run 45-65 characters, and
  // justifying at that measure opens rivers and word gaps that are far more
  // disruptive at 1m than a soft right edge.
  set par(justify: false, leading: 0.65em)
  set heading(numbering: none)
  // Carried on the theme state because stats-grid() is a free helper with no
  // access to these arguments. Inserted after the theme-overrides merge above
  // so it cannot collide with a key an author named there.
  th.insert("stats-align", _h-align(stats-align))
  _theme.update(th)

  // Section headings: filled bars in theme colors.
  //
  // The `left` case returns the text bare rather than wrapping it in
  // `align(left, ..)`, so a poster that never asks for this renders
  // byte-identically. `heading-text-args` cannot do this job: it is spread
  // into `text()`, which has no alignment parameter.
  let heading-h = _h-align(heading-align)
  let subheading-h = _h-align(subheading-align)
  show heading.where(level: 1): it => block(
    width: 100%,
    ..th.heading-box-args,
    {
      let inner = text(..(size: 1.6 * base-font-size) + th.heading-text-args, it.body)
      if heading-h == left { inner } else { align(heading-h, inner) }
    },
  )
  show heading.where(level: 2): it => block(
    width: 100%,
    ..th.subheading-box-args,
    {
      let inner = text(..(size: 1.25 * base-font-size) + th.subheading-text-args, it.body)
      if subheading-h == left { inner } else { align(subheading-h, inner) }
    },
  )
  show link: set text(..th.link-text-args)
  // Code. Quarto emits its own `show raw.where(block: true)` in the preamble,
  // ahead of this template's `#show: sciposter.with(...)`, so this rule is the
  // inner one and wins on the properties it names — and only those, which is
  // why the grey code panel Quarto draws survives untouched.
  //
  // Size is `auto` unless asked for, meaning code rides the body size. That
  // is the pre-existing behaviour, so a poster written before this option
  // existed renders identically.
  show raw: set text(
    ..th.code-text-args
      + (if code-font-size != auto { (size: code-font-size) } else { (:) })
      + (if code-ligatures != "" { (ligatures: code-ligatures == "true") } else { (:) }),
  )
  // Tables inherit the body size rather than carrying one of their own: a
  // poster table is read at the same distance as the prose beside it. The Lua
  // filter drops CSS `font-size` off HTML tables for the same reason.
  set table(..th.table-args)
  show table.cell.where(y: 0): set text(..th.table-header-text-args)
  // `block` sizes to its content, so the top and bottom rules land on the
  // table's own width rather than the column's.
  //
  // Skip the wrapper for a table that already draws its own top rule: that is
  // a table arriving with a full booktabs set (tinytable emits an explicit
  // `table.hline(y: 0)`), and wrapping it in ours doubles the top and bottom.
  // Quarto's pipe tables emit only a bare `table.hline()` for the header
  // separator, with no `y`, so they still get the wrapper.
  show table: it => {
    let own-rules = it.children.any(c =>
      c.func() == table.hline and c.fields().at("y", default: auto) == 0)
    if own-rules { it } else {
      block(..(inset: (y: 0.2em)) + th.table-rule-args, it)
    }
  }
  show figure.caption: it => {
    set text(..(size: 0.75 * base-font-size) + th.caption-text-args)
    set par(justify: false)
    it
  }
  show <refs>: it => refs-section(kind: refs-kind, it)

  // ---- title bar ----
  let author-line = if authors.len() > 0 {
    authors
      .map(a => {
        let sup = a.at("affiliations", default: "")
        [#a.name#if sup != "" { super(sup) }]
      })
      .join([, ])
  } else { none }

  // Number affiliations by position — matches the numbering Quarto assigns
  // to authors' affiliation references in by-author metadata.
  let affiliation-line = if affiliations.len() > 0 {
    affiliations
      .enumerate()
      .map(((i, af)) => [#super(str(i + 1)) #af.name])
      .join(h(0.5in))
  } else { none }

  let logo-stack(logos) = if logos.len() > 0 {
    stack(dir: ltr, spacing: 0.4in, ..logos.map(p => image(p, height: logo-height)))
  } else { none }

  // The three gaps down the middle of the title bar. Named rather than scaled
  // by one factor because a poster that has to tighten them rarely tightens
  // them evenly — the gap before a six-author byline is doing different work
  // from the gap before its affiliations. Merging the author's dict over the
  // defaults means naming one gap leaves the other two alone.
  let gaps = (subtitle: 0.2in, author: 0.35in, affiliation: 0.18in) + title-gaps

  // The three type sizes under the title, same shape as `title-gaps` and for
  // the same reason. Their defaults are RATIOS of two different bases — the
  // subtitle rides the title, the byline and affiliations ride the body — so
  // a poster that needs one of them at an absolute size (a printer's house
  // minimum, say) has no way to express it by adjusting either base: moving
  // `base-font-size` to lift the byline would resize the whole poster.
  // Computed here, after both bases resolve, and merged under the author's
  // dict so naming one size leaves the other two on their ratios.
  let sizes = (
    subtitle: 0.58 * title-font-size,
    author: 1.25 * base-font-size,
    affiliation: 0.95 * base-font-size,
  ) + title-sizes

  let titlebar = block(
    width: 100%,
    inset: (x: margin, y: 0.6 * margin),
    ..th.title-box-args,
    grid(
      columns: (auto, 1fr, auto),
      column-gutter: 0.6in,
      align: (left + horizon, center + horizon, right + horizon),
      logo-stack(logos-left),
      {
        set text(..th.title-text-args)
        set align(center)
        set par(justify: false)
        text(size: title-font-size, weight: "bold", title)
        if subtitle != none {
          v(gaps.subtitle)
          text(size: sizes.subtitle, subtitle)
        }
        if author-line != none {
          v(gaps.author)
          text(size: sizes.author, weight: "medium", author-line)
        }
        if affiliation-line != none {
          v(gaps.affiliation)
          text(size: sizes.affiliation, affiliation-line)
        }
      },
      logo-stack(logos-right),
    ),
  )
  // Thin accent stripe separates the title bar from the body.
  let titlebar = stack(
    titlebar,
    block(width: 100%, height: 0.12in, ..th.stripe-args),
  )

  // Body images fill their column (or full-width span) by default. Quarto
  // wraps figure images in auto-sized box/figure containers where relative
  // widths collapse to nothing, so rebuild unsized images with an absolute
  // width measured via layout(). Explicitly sized images pass through, as do
  // title-bar logos (built outside this scope).
  let body-styled = {
    show image: it => {
      let f = it.fields()
      if f.at("width", default: auto) != auto or f.at("height", default: auto) != auto {
        it
      } else {
        layout(size => {
          // Explicit width on the probe keeps it out of this show rule
          // (guard above), avoiding infinite recursion during measure.
          let probe = measure(image(f.source, width: 1in))
          let h = size.width * (probe.height / probe.width)
          // Cap height so a column-width image can't eat the whole column:
          // full-height figures collide with parent-scoped floats and push
          // their (sticky) headings into the next column.
          let cap = fig-max-height * size.height
          if h > cap {
            image(f.source, height: cap)
          } else {
            image(f.source, width: size.width)
          }
        })
      }
    }
    body
    // End-of-body marker for the overflow detector in the page background.
    [#metadata("sciposter-end") <sciposter-end>]
  }

  grid(
    rows: if footerbar != none { (auto, 1fr, auto) } else { (auto, 1fr) },
    titlebar,
    block(
      width: 100%,
      height: 100%,
      inset: (x: margin, top: 0.6 * margin, bottom: 0.6 * margin),
      {
        // The line the columns are not allowed to cross, reported rather than
        // recomputed: `place` inside this block resolves against its content
        // area, so the marker lands exactly on the inner bottom edge. Deriving
        // it in the background instead would mean measuring the footer bar
        // there, and `measure` in a page background has no width to resolve a
        // `width: 100%` block against.
        place(bottom + left, [#metadata("body") <sciposter-body-bottom>])
        columns(n-columns, gutter: gutter, body-styled)
      },
    ),
    ..if footerbar != none { (footerbar,) } else { () },
  )
}
