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
  { Div = map_div },
}
