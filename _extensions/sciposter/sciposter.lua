-- sciposter.lua — map fenced div classes to Typst layout functions
--
--   ::: {.full-width}   -> #full-width[ ... ]        (span all columns)
--   ::: {.col-break}    -> #colbreak()               (force column break)
--   ::: {.poster-box}   -> #poster-box(...)[ ... ]   (framed box)
--     variants: .highlight, .alert; optional title="..." attribute
--   ::: {.takeaway}     -> #takeaway(...)[ ... ]     (3m headline finding)
--     optional label="..." and scale="..." attributes
--   ::: {.qr url="..."} -> #poster-qr(...)           (scannable QR code)
--     optional size="..." and label="..." attributes
--   ::: {#refs}         -> #refs-section(...)[ ... ] per poster.refs
--     (flow | box | none)
--
-- It also drops the CSS an HTML table brings with it, so the table inherits
-- the poster's type, colour and rules; see strip_table_css below.

if FORMAT ~= "typst" then
  return {}
end

local function wrap(div, open)
  local blocks = pandoc.Blocks({ pandoc.RawBlock("typst", open) })
  blocks:extend(div.content)
  blocks:insert(pandoc.RawBlock("typst", "]"))
  return blocks
end

-- How much of an HTML table's CSS to drop so it looks like the poster:
-- "theme" (default) strips the presentation properties, "size-only" strips
-- just the font size, "keep" strips nothing. See strip_css below.
local table_css = "theme"

local function read_meta(meta)
  local poster = meta["poster"]
  if not poster then
    return
  end
  if poster["table-css"] then
    table_css = pandoc.utils.stringify(poster["table-css"])
  end
  -- Reference styling happens typst-side (show rule on <refs>): filters run
  -- before citeproc fills the div, so wrapping it here is impossible.
  -- refs: none maps to citeproc's own suppression switch.
  if poster["refs"] and pandoc.utils.stringify(poster["refs"]) == "none" then
    meta["suppress-bibliography"] = true
  end
  -- Strip the leading "#" from poster.colors values. Pandoc escapes "#" as
  -- "\#" when a template variable is interpolated into Typst output (it is
  -- Typst's code marker), which reaches rgb() as a non-hexadecimal character
  -- and fails the compile. Quarto's own brand colours dodge this only because
  -- it emits them as generated code rather than through a template variable.
  -- The template re-adds the "#", so bare hex in YAML works too.
  local colors = poster["colors"]
  if colors ~= nil and pandoc.utils.type(colors) == "table" then
    for key, value in pairs(colors) do
      colors[key] = (pandoc.utils.stringify(value):gsub("^#", ""))
    end
    poster["colors"] = colors
    meta["poster"] = poster
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

-- An HTML table brings a screen's worth of CSS with it. `gt` is the case that
-- matters: it sets a font size in pixels, which Quarto's Typst writer turns
-- into absolute points (16px -> 12pt) — under half an A1 poster's 27pt body,
-- unreadable at viewing distance and with no warning. It also paints its own
-- greys, borders and pixel padding, so a gt table that renders at the right
-- size still arrives looking like gt rather than like the poster around it.
--
-- Quarto's own `css-property-processing: none` is all-or-nothing and would
-- also discard column alignment, so this drops properties by name instead.
--
-- Everything omitted from both lists below is passed through, which is the
-- point: alignment survives, and so does `font-variant-numeric: tabular-nums`,
-- which is exactly what a column of figures wants.
local size_only = {
  ["font-size"] = true,
}

-- Presentation the poster theme should be deciding instead: type, colour,
-- rules and spacing. Prefixes cover the longhand families (`border-top-color`,
-- `padding-left`, and so on).
local theme_owned = {
  ["font-family"] = true,
  ["font-size"] = true,
  ["font-weight"] = true,
  ["font-style"] = true,
  ["color"] = true,
  ["background-color"] = true,
  ["line-height"] = true,
}
local theme_owned_prefixes = { "border", "padding", "margin" }

local function is_stripped(property)
  if table_css == "size-only" then
    return size_only[property] == true
  end
  if theme_owned[property] then
    return true
  end
  for _, prefix in ipairs(theme_owned_prefixes) do
    if property:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

-- An explicit `typst:text:size` is the author saying they meant it, so those
-- elements are left untouched, as is everything under `poster.table-css:
-- keep`.
local function strip_css(attr)
  if not attr or not attr.attributes then
    return
  end
  local style = attr.attributes["style"]
  if not style or attr.attributes["typst:text:size"] then
    return
  end
  local kept = {}
  for decl in style:gmatch("[^;]+") do
    local property = decl:match("^%s*([%w%-]+)%s*:")
    -- `font` is the shorthand that can also carry a size; it is not emitted by
    -- gt or kableExtra, so it is passed through rather than parsed.
    if property == nil or not is_stripped(property:lower()) then
      kept[#kept + 1] = decl
    end
  end
  if #kept == 0 then
    attr.attributes["style"] = nil
  else
    attr.attributes["style"] = table.concat(kept, ";") .. ";"
  end
end

local function strip_table_css(tbl)
  if table_css == "keep" then
    return
  end
  strip_css(tbl.attr)
  local function walk_rows(rows)
    for _, row in ipairs(rows) do
      strip_css(row.attr)
      for _, cell in ipairs(row.cells) do
        strip_css(cell.attr)
      end
    end
  end
  walk_rows(tbl.head.rows)
  walk_rows(tbl.foot.rows)
  for _, body in ipairs(tbl.bodies) do
    walk_rows(body.head)
    walk_rows(body.body)
  end
  return tbl
end

local function map_div(div)
  if div.classes:includes("col-break") then
    return pandoc.RawBlock("typst", "#colbreak()")
  end

  if div.classes:includes("full-width") then
    return wrap(div, "#full-width[")
  end

  -- ::: {.qr url="https://..."} — url is required; without it the div is
  -- left alone rather than emitting a QR that encodes nothing.
  if div.classes:includes("qr") and div.attributes["url"] then
    local args = { '"' .. div.attributes["url"] .. '"' }
    if div.attributes["size"] then
      table.insert(args, "size: " .. div.attributes["size"])
    end
    if div.attributes["label"] then
      table.insert(args, "label: [" .. div.attributes["label"] .. "]")
    end
    return pandoc.RawBlock("typst", "#poster-qr(" .. table.concat(args, ", ") .. ")")
  end

  if div.classes:includes("takeaway") then
    local args = {}
    if div.attributes["scale"] then
      table.insert(args, "scale: " .. div.attributes["scale"])
    end
    if div.attributes["label"] then
      table.insert(args, "label: [" .. div.attributes["label"] .. "]")
    end
    return wrap(div, "#takeaway(" .. table.concat(args, ", ") .. ")[")
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
  { Div = map_div, Table = strip_table_css },
}
