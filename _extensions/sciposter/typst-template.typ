// sciposter — scientific poster layout engine for Quarto + Typst
//
// Layout model: fixed single page sized from `size`, laid out as a vertical
// grid of [title bar | body columns | optional footer bar]. Body content
// flows through columns(); `.full-width` divs escape to parent scope.

// ---------------------------------------------------------------------------
// Themes
// ---------------------------------------------------------------------------

#let poster-themes = (
  generic: (
    primary: rgb("#1f4e79"),
    accent: rgb("#2e74b5"),
    bg: white,
    titlebar-bg: rgb("#1f4e79"),
    titlebar-fg: white,
    heading-fg: white,
    body-fg: rgb("#222222"),
    box-bg: rgb("#f2f4f7"),
    fonts: ("Helvetica Neue", "Helvetica", "Arial", "Liberation Sans"),
  ),
  unl: (
    primary: rgb("#D00000"),
    accent: rgb("#A50000"),
    bg: white,
    titlebar-bg: rgb("#D00000"),
    titlebar-fg: white,
    heading-fg: white,
    body-fg: rgb("#242021"),
    box-bg: rgb("#F5F1E7"),
    stripe: rgb("#F5F1E7"),
    fonts: ("Helvetica Neue", "Helvetica", "Arial", "Liberation Sans"),
  ),
)

// Set by sciposter() so helper functions (poster-box) can read theme colors.
#let _theme = state("sciposter-theme", poster-themes.generic)

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
// Body helpers (targets for the Lua div-mapping filter)
// ---------------------------------------------------------------------------

// Span all columns: parent-scoped float inside columns().
// Floats can only land at the top or bottom of the page body (Typst
// limitation); default lets Typst pick the nearer edge.
#let full-width(position: auto, body) = context {
  place(
    position,
    scope: "parent",
    float: true,
    clearance: 0.4in,
    block(width: 100%, body),
  )
}

#let poster-box(title: none, kind: "default", body) = context {
  let th = _theme.get()
  let fill = if kind == "highlight" { th.box-bg } else if kind == "alert" {
    th.primary.lighten(85%)
  } else { th.box-bg }
  let stroke-color = if kind == "alert" { th.primary } else { th.accent }
  block(
    width: 100%,
    fill: fill,
    stroke: (left: 6pt + stroke-color),
    radius: 4pt,
    inset: 0.3in,
    breakable: false,
    {
      if title != none {
        text(weight: "bold", fill: stroke-color, title)
        v(0.15in)
      }
      body
    },
  )
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
    block(
      width: 100%,
      fill: th.box-bg,
      radius: 4pt,
      inset: 0.25in,
      breakable: true,
      inner,
    )
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
  logos-left: (),
  logos-right: (),
  logo-height: 1.5in,
  footer-text: none,
  footer-left: none,
  footer-right: none,
  base-font-size: 24pt,
  title-font-size: 72pt,
  fig-max-height: 45%,
  refs-kind: "flow",
  body,
) = {
  let th = poster-themes.at(theme, default: poster-themes.generic)
  let (page-w, page-h) = resolve-size(size, orientation)

  set page(
    width: page-w,
    height: page-h,
    margin: 0pt,
    fill: th.bg,
    // A poster is one page; overflowing body text is CLIPPED at the page
    // edge, not moved to page 2 — so losing it silently is the real hazard.
    // A zero-size marker sits at the very end of the body; if it laid out
    // past the page bottom (or never laid out), content was cut off. Warn
    // loudly on the poster itself so it never slips through to print.
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
            font: ("Helvetica Neue", "Helvetica", "Arial", "Liberation Sans"),
            msg,
          ),
        ),
      )
      if here().page() > 1 {
        warn([CONTENT OVERFLOW — does not fit the poster page])
      } else {
        let m = query(<sciposter-end>)
        let overflowed = m.len() == 0 or {
          let pos = m.first().location().position()
          m.first().location().page() > 1 or pos.y > page-h
        }
        if overflowed {
          warn([CONTENT OVERFLOW — text below this page's edge is CUT OFF])
        }
      }
    },
  )
  set text(font: th.fonts, size: base-font-size, fill: th.body-fg)
  set par(justify: true, leading: 0.65em)
  set heading(numbering: none)
  _theme.update(th)

  // Section headings: filled bars in theme colors.
  show heading.where(level: 1): it => block(
    width: 100%,
    fill: th.primary,
    inset: (x: 0.35in, y: 0.22in),
    radius: 6pt,
    above: 0.5in,
    below: 0.35in,
    text(fill: th.heading-fg, size: 1.6 * base-font-size, weight: "bold", it.body),
  )
  show heading.where(level: 2): it => block(
    width: 100%,
    inset: (bottom: 0.1in),
    stroke: (bottom: 3pt + th.accent),
    above: 0.4in,
    below: 0.25in,
    text(fill: th.accent, size: 1.25 * base-font-size, weight: "bold", it.body),
  )
  show link: set text(fill: th.accent)
  show figure.caption: it => {
    set text(size: 0.75 * base-font-size, fill: th.body-fg.lighten(25%))
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

  let titlebar = block(
    width: 100%,
    fill: th.titlebar-bg,
    inset: (x: margin, y: 0.6 * margin),
    grid(
      columns: (auto, 1fr, auto),
      column-gutter: 0.6in,
      align: (left + horizon, center + horizon, right + horizon),
      logo-stack(logos-left),
      {
        set text(fill: th.titlebar-fg)
        set align(center)
        set par(justify: false)
        text(size: title-font-size, weight: "bold", title)
        if subtitle != none {
          v(0.2in)
          text(size: 0.58 * title-font-size, subtitle)
        }
        if author-line != none {
          v(0.35in)
          text(size: 1.25 * base-font-size, weight: "medium", author-line)
        }
        if affiliation-line != none {
          v(0.18in)
          text(size: 0.95 * base-font-size, affiliation-line)
        }
      },
      logo-stack(logos-right),
    ),
  )
  // Thin accent stripe separates the title bar from the body.
  let titlebar = stack(
    titlebar,
    block(width: 100%, height: 0.12in, fill: th.at("stripe", default: th.accent)),
  )

  // Footer: single string centers; left/center/right slots for the 3-part
  // layout (event | contact | url etc.).
  let footerbar = if (footer-text, footer-left, footer-right) != (none, none, none) {
    block(
      width: 100%,
      fill: th.accent,
      inset: (x: margin, y: 0.3in),
      {
        set text(fill: th.titlebar-fg, size: 0.9 * base-font-size)
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
      columns(n-columns, gutter: gutter, body-styled),
    ),
    ..if footerbar != none { (footerbar,) } else { () },
  )
}
