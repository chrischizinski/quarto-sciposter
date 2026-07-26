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
