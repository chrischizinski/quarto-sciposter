-- sciposter.lua — map fenced div classes to Typst layout functions
--
--   ::: {.full-width}   -> #full-width[ ... ]        (span all columns)
--   ::: {.col-break}    -> #colbreak()               (force column break)
--   ::: {.poster-box}   -> #poster-box(...)[ ... ]   (framed box)
--     variants: .highlight, .alert; optional title="..." attribute
--   ::: {#refs}         -> #refs-section(...)[ ... ] per poster.refs
--     (flow | box | none)

if FORMAT ~= "typst" then
  return {}
end

local function wrap(div, open)
  local blocks = pandoc.Blocks({ pandoc.RawBlock("typst", open) })
  blocks:extend(div.content)
  blocks:insert(pandoc.RawBlock("typst", "]"))
  return blocks
end

local function read_meta(meta)
  local poster = meta["poster"]
  if not poster then
    return
  end
  -- Reference styling happens typst-side (show rule on <refs>): filters run
  -- before citeproc fills the div, so wrapping it here is impossible.
  -- refs: none maps to citeproc's own suppression switch.
  if poster["refs"] and pandoc.utils.stringify(poster["refs"]) == "none" then
    meta["suppress-bibliography"] = true
  end
  -- poster.footer accepts a plain string or a {left, center, right} map;
  -- pandoc templates can't distinguish the two, so flatten the map here.
  local footer = poster["footer"]
  if footer ~= nil and pandoc.utils.type(footer) == "table" then
    poster["footer-left"] = footer["left"]
    poster["footer-center"] = footer["center"]
    poster["footer-right"] = footer["right"]
    poster["footer"] = nil
    meta["poster"] = poster
  end
  return meta
end

local function map_div(div)
  if div.classes:includes("col-break") then
    return pandoc.RawBlock("typst", "#colbreak()")
  end

  if div.classes:includes("full-width") then
    return wrap(div, "#full-width[")
  end

  if div.classes:includes("poster-box")
      or div.classes:includes("highlight")
      or div.classes:includes("alert") then
    local kind = "default"
    if div.classes:includes("highlight") then
      kind = "highlight"
    elseif div.classes:includes("alert") then
      kind = "alert"
    end
    local args = 'kind: "' .. kind .. '"'
    local title = div.attributes["title"]
    if title then
      args = args .. ", title: [" .. title .. "]"
    end
    return wrap(div, "#poster-box(" .. args .. ")[")
  end
end

-- Meta must be read before divs are mapped; a single filter table runs
-- Meta after blocks, so use two passes.
return {
  { Meta = read_meta },
  { Div = map_div },
}
