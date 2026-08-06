-- sciposter.lua — map fenced div classes to Typst layout functions
--
--   ::: {.full-width}   -> #full-width[ ... ]        (span all columns)
--     optional position="top"|"bottom" attribute
--   ::: {.col-break}    -> #colbreak()               (force column break)
--   ::: {.poster-box}   -> #poster-box(...)[ ... ]   (framed box)
--     variants: .highlight, .alert; optional title="..." attribute
--   ::: {.takeaway}     -> #takeaway(...)[ ... ]     (3m headline finding)
--     variant: .quiet; optional label="..." and scale="..." attributes
--   ::: {.stats}        -> #stats-grid(...)          (evidence number strip)
--     one paragraph per cell, `**value** label`; optional label="..."
--   ::: {.poster-grid}  -> #poster-grid(...)         (aligned cells, not flow)
--     one cell per block; cols / widths / gutter / row-gutter
--   ::: {.poster-surface} -> #poster-surface(...)[ ] (tinted grouping block)
--     variant: .poster-image-frame; tint / ink / pad / radius / border
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

-- Cells: one positional argument per top-level block, so the Typst side can
-- lay them out on a grid. Used by .stats and .poster-grid, which differ only
-- in the function they hand the cells to.
--
-- This runs in its own TOP-DOWN pass, and that is load-bearing. Pandoc visits
-- divs bottom-up by default, so a `.poster-surface` used as a grid cell would
-- already have become three blocks — an opening raw block, its content, a
-- closing one — and each would be split off as a cell of its own, producing
-- `[#poster-surface(...)[` as one argument and `]` as another. Splitting from
-- the outside first means a child div is still a single block when its cell
-- boundary is drawn, and the pass that converts it runs afterwards.
local function wrap_cells(div, open)
  local blocks = pandoc.Blocks({ pandoc.RawBlock("typst", open) })
  for _, block in ipairs(div.content) do
    blocks:insert(pandoc.RawBlock("typst", "["))
    blocks:insert(block)
    blocks:insert(pandoc.RawBlock("typst", "],"))
  end
  blocks:insert(pandoc.RawBlock("typst", ")"))
  return blocks
end

-- ---------------------------------------------------------------------------
-- YAML -> Typst values
-- ---------------------------------------------------------------------------
--
-- `poster.theme-overrides` and the sizing attributes on .poster-surface /
-- .poster-grid carry Typst values, not strings: lengths, colours, arrays,
-- nested dictionaries. Those cannot travel as `"$var$"` in the Pandoc
-- template — the Typst writer escapes an interpolated MetaString, so
-- `(a: 40pt, fill: rgb("#0D3B66"))` arrives as
-- `"\(a: 40pt, fill: rgb(\"\#0D3B66\"))"` and is a string, not code.
--
-- A `RawInline` of format "typst" is passed through verbatim instead, so the
-- conversion happens here and the template interpolates finished source. That
-- also means the value language is decided in one place:
--
--   "#0D3B66" / "0D3B66"     -> rgb(13, 59, 102)      (6 or 8 hex digits)
--   "40pt" "0.35in" "1.2em"  -> the length literal, unchanged
--   "50%" "1fr"              -> ratio / fraction, unchanged
--   "none" "auto"            -> the bare keyword
--   42  3.5  true  false     -> the literal
--   anything else            -> a quoted string ("bold", "Fira Code")
--   a YAML list              -> an array
--   a YAML map               -> a dictionary
--
-- Colours become `rgb(r, g, b)` rather than `rgb("#...")` deliberately: "#"
-- is Typst's code marker, and keeping it out of the emitted source means the
-- author can write hex with or without it and nothing downstream has to care.
local function hex_to_rgb(hex)
  local channels = {}
  for pair in hex:gmatch("%x%x") do
    channels[#channels + 1] = tostring(tonumber(pair, 16))
  end
  return "rgb(" .. table.concat(channels, ", ") .. ")"
end

-- Units Typst accepts on a bare number. `fr` and `%` are not lengths but read
-- and emit identically, so they ride along.
local length_units = {
  pt = true, mm = true, cm = true, ["in"] = true,
  em = true, fr = true,
}

local function typst_scalar(s)
  if s == "none" or s == "auto" or s == "true" or s == "false" then
    return s
  end
  if s:match("^%-?%d+%.?%d*$") then
    return s
  end
  local hex = s:match("^#?(%x+)$")
  if hex and (#hex == 6 or #hex == 8) then
    return hex_to_rgb(hex)
  end
  local number, unit = s:match("^(%-?%d+%.?%d*)%s*(%a+)$")
  if number and length_units[unit] then
    return number .. unit
  end
  if s:match("^%-?%d+%.?%d*%%$") then
    return s
  end
  return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

local function typst_value(value)
  local kind = pandoc.utils.type(value)
  if kind == "boolean" then
    return tostring(value)
  end
  if kind == "List" then
    local items = {}
    for _, item in ipairs(value) do
      items[#items + 1] = typst_value(item)
    end
    -- A one-element Typst array needs the trailing comma or it is just a
    -- parenthesised value — which is how a single-font list becomes a string.
    local tail = #items == 1 and "," or ""
    return "(" .. table.concat(items, ", ") .. tail .. ")"
  end
  if kind == "table" then
    local keys = {}
    for key in pairs(value) do
      keys[#keys + 1] = key
    end
    -- Sorted so the emitted source is reproducible; Typst does not care.
    table.sort(keys)
    if #keys == 0 then
      return "(:)"
    end
    local entries = {}
    for _, key in ipairs(keys) do
      entries[#entries + 1] = key .. ": " .. typst_value(value[key])
    end
    return "(" .. table.concat(entries, ", ") .. ")"
  end
  return typst_scalar(pandoc.utils.stringify(value))
end

-- Div attributes are always strings, and an absent one must stay absent
-- rather than become `none` — the Typst side distinguishes "not given" from
-- "given as none".
local function attr_args(div, names)
  local args = {}
  for _, name in ipairs(names) do
    local value = div.attributes[name]
    if value then
      args[#args + 1] = name .. ": " .. typst_scalar(value)
    end
  end
  return args
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
  -- poster.theme-overrides is a map of theme element name -> dict of Typst
  -- values. Converted here and handed to the template as raw Typst, for the
  -- reasons in the comment above typst_value.
  local overrides = poster["theme-overrides"]
  if overrides ~= nil and pandoc.utils.type(overrides) == "table" then
    poster["theme-overrides-typst"] = pandoc.MetaInlines({
      pandoc.RawInline("typst", typst_value(overrides)),
    })
    meta["poster"] = poster
  end
  -- Same treatment for the two scalars that carry a length: they would
  -- otherwise arrive as strings and Typst has no string-to-length parser.
  for _, key in ipairs({ "block-gap", "code-font-size" }) do
    local value = poster[key]
    if value ~= nil then
      poster[key .. "-typst"] = pandoc.MetaInlines({
        pandoc.RawInline("typst", typst_scalar(pandoc.utils.stringify(value))),
      })
      meta["poster"] = poster
    end
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

-- Dropping a font size silently is fair: nobody sets 12px meaning "illegible
-- at two metres". Dropping colours and borders is not — that may well have
-- been deliberate, and a poster that quietly ignores it is the kind of thing
-- an author only notices at the print shop. Warn once per render instead.
local dropped_styling = false

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
    elseif property:lower() ~= "font-size" then
      dropped_styling = true
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

local function split_cells(div)
  -- ::: {.stats} — one paragraph per cell, each `**value** label`.
  if div.classes:includes("stats") then
    local args = {}
    if div.attributes["label"] then
      table.insert(args, "label: [" .. div.attributes["label"] .. "]")
    end
    local open = "#stats-grid(" .. table.concat(args, ", ")
    if #args > 0 then
      open = open .. ", "
    end
    return wrap_cells(div, open)
  end

  -- ::: {.poster-grid} — one cell per top-level block, laid out as real grid
  -- rows. This is the answer to "align a box in one column with a step in the
  -- next": column flow cannot do it, because columns() is a single stream with
  -- no cross-column anchor, but cells in a row share a row by construction.
  if div.classes:includes("poster-grid") then
    local args = attr_args(div, { "cols", "gutter", "row-gutter" })
    -- widths is the one attribute that is a list rather than a scalar:
    -- widths="2fr,1fr" has to reach Typst as an array, not as a string.
    local widths = div.attributes["widths"]
    if widths then
      local tracks = {}
      for track in widths:gmatch("[^,%s]+") do
        tracks[#tracks + 1] = typst_scalar(track)
      end
      local tail = #tracks == 1 and "," or ""
      table.insert(args, "widths: (" .. table.concat(tracks, ", ") .. tail .. ")")
    end
    local open = "#poster-grid(" .. table.concat(args, ", ")
    if #args > 0 then
      open = open .. ", "
    end
    return wrap_cells(div, open)
  end

end

local function map_div(div)
  if div.classes:includes("col-break") then
    return pandoc.RawBlock("typst", "#colbreak()")
  end

  if div.classes:includes("full-width") then
    -- position="bottom" (or "top") pins the float to one page edge; without it
    -- Typst picks the nearer one, which for a closing band is a coin toss.
    -- The value is interpolated as a bare Typst alignment, so a typo is a
    -- compile error rather than a silent fallback — the right failure for
    -- something that gets printed once.
    local position = div.attributes["position"]
    if position then
      return wrap(div, "#full-width(position: " .. position .. ")[")
    end
    return wrap(div, "#full-width[")
  end

  -- ::: {.poster-surface} — a tinted container for grouping, and
  -- ::: {.poster-image-frame} — the same primitive with a border and a mat,
  -- which is what keeps a dark book cover from printing as a muddy block
  -- against a pale poster.
  if div.classes:includes("poster-surface")
      or div.classes:includes("poster-image-frame") then
    local kind = div.classes:includes("poster-image-frame") and "frame" or "surface"
    local args = attr_args(div, { "tint", "ink", "pad", "radius", "border" })
    table.insert(args, 1, 'kind: "' .. kind .. '"')
    return wrap(div, "#poster-surface(" .. table.concat(args, ", ") .. ")[")
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
    if div.classes:includes("quiet") then
      table.insert(args, 'kind: "quiet"')
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

local function warn_dropped_styling()
  if not dropped_styling then
    return
  end
  local warn = quarto and quarto.log and quarto.log.warning
  local msg = "sciposter: replaced a table's own colors, borders or spacing "
    .. "with the poster theme. Set `table-css: size-only` under `poster:` to "
    .. "keep the table's styling at a readable size."
  if warn then
    warn(msg)
  else
    io.stderr:write(msg .. "\n")
  end
end

-- Meta must be read before divs are mapped; a single filter table runs
-- Meta after blocks, so use two passes. The warning needs a third: Pandoc
-- runs last within a pass, but only once every Table in that pass has been
-- walked.
return {
  { Meta = read_meta },
  -- Top-down, so a div used as a grid cell is still one block when its cell
  -- boundary is drawn. See the comment on wrap_cells.
  { traverse = "topdown", Div = split_cells },
  { Div = map_div, Table = strip_table_css },
  { Pandoc = warn_dropped_styling },
}
