#show: sciposter.with(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(poster.size)$
  size: "$poster.size$",
$endif$
$if(poster.orientation)$
  orientation: "$poster.orientation$",
$endif$
$if(poster.columns)$
  n-columns: $poster.columns$,
$endif$
$if(poster.gutter)$
  gutter: $poster.gutter$,
$endif$
$if(poster.margin)$
  margin: $poster.margin$,
$endif$
$if(poster.theme)$
  theme: "$poster.theme$",
$endif$
$if(poster.colors)$
$-- Values arrive as bare hex (the Lua filter strips "#", which Pandoc would
$-- otherwise escape into rgb() as "\#"). sciposter() converts them.
  theme-colors: ($for(poster.colors/pairs)$$it.key$: "$it.value$", $endfor$),
$endif$
$if(poster.fonts)$
  theme-fonts: ($for(poster.fonts)$"$it$", $endfor$),
$endif$
$if(poster.heading-fonts)$
  theme-heading-fonts: ($for(poster.heading-fonts)$"$it$", $endfor$),
$endif$
$if(poster.code-fonts)$
  code-fonts: ($for(poster.code-fonts)$"$it$", $endfor$),
$endif$
$-- These three arrive as finished Typst source, built by the Lua filter.
$-- Interpolating them as "$var$" would hand Typst an escaped string instead
$-- of a length, a colour or a dictionary; see typst_value in sciposter.lua.
$if(poster.code-font-size-typst)$
  code-font-size: $poster.code-font-size-typst$,
$endif$
$if(poster.block-gap-typst)$
  block-gap: $poster.block-gap-typst$,
$endif$
$if(poster.theme-overrides-typst)$
  theme-overrides: $poster.theme-overrides-typst$,
$endif$
$-- A dict of lengths, so it takes the same route as theme-overrides.
$if(poster.title-gaps-typst)$
  title-gaps: $poster.title-gaps-typst$,
$endif$
$-- These two are plain strings; sciposter() maps them to Typst alignments.
$if(poster.heading-align)$
  heading-align: "$poster.heading-align$",
$endif$
$if(poster.stats-align)$
  stats-align: "$poster.stats-align$",
$endif$
$-- Tri-state, so it is forwarded unconditionally: `$if()$` cannot tell an
$-- absent key from an explicit `false`, and here they mean different things —
$-- absent leaves the font's own ligature setting alone, false turns it off.
$-- Interpolation can tell them apart: "" against "true" / "false".
  code-ligatures: "$poster.code-ligatures$",
$-- Quarto always defines these in Typst scope — `(:)` when the project has no
$-- `_brand.yml` — so they can be forwarded unconditionally.
  brand-colors: brand-color,
$-- `$if()$` cannot tell an absent key from an explicit `false` (both take the
$-- else branch), but interpolation can: absent renders "", `false` renders
$-- "false". That is what makes `poster.brand: false` an opt-out while the
$-- default stays on.
  brand-enabled: "$poster.brand$" != "false",
$if(mainfont)$
  brand-fonts: ("$mainfont$",),
$elseif(brand.typography.base.family)$
  brand-fonts: $brand.typography.base.family$,
$endif$
$if(brand.typography.headings.family)$
  brand-heading-fonts: $brand.typography.headings.family$,
$endif$
$if(poster.logo-height)$
  logo-height: $poster.logo-height$,
$endif$
$if(poster.base-font-size)$
  base-font-size: $poster.base-font-size$,
$endif$
$if(poster.title-font-size)$
  title-font-size: $poster.title-font-size$,
$endif$
$if(poster.fig-max-height)$
  fig-max-height: $poster.fig-max-height$,
$endif$
$if(poster.refs)$
  refs-kind: "$poster.refs$",
$endif$
$if(poster.palette)$
  palette: ($for(poster.palette)$"$it$", $endfor$),
$endif$
$if(poster.draft)$
  draft: true,
$endif$
$-- Interpolated rather than tested with `$if()$`, so that `true`, `false` and
$-- a corner name all reach the template as strings; `$if()$` cannot tell
$-- `false` from absent. sciposter() maps "false"/"none" to no credit.
$if(poster.credit)$
  credit: "$poster.credit$",
$endif$
$if(poster.footer)$
  footer-text: [$poster.footer$],
$endif$
$if(poster.footer-center)$
  footer-text: [$poster.footer-center$],
$endif$
$if(poster.footer-left)$
  footer-left: [$poster.footer-left$],
$endif$
$if(poster.footer-right)$
  footer-right: [$poster.footer-right$],
$endif$
$if(logos.left)$
  logos-left: ($for(logos.left)$"$it$", $endfor$),
$endif$
$if(logos.right)$
  logos-right: ($for(logos.right)$"$it$", $endfor$),
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
    (
      name: [$it.name.literal$],
      affiliations: "$for(it.affiliations)$$it.number$$sep$,$endfor$",
    ),
$endfor$
  ),
$endif$
$if(by-affiliation)$
  affiliations: (
$for(by-affiliation)$
    (number: "$it.number$", name: [$it.name$]),
$endfor$
  ),
$endif$
)
