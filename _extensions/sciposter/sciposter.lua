-- sciposter.lua — map fenced div classes to Typst layout functions
--
--   ::: {.full-width}   -> #full-width[ ... ]        (span all columns)
--   ::: {.col-break}    -> #colbreak()               (force column break)
--   ::: {.poster-box}   -> #poster-box(...)[ ... ]   (framed box)
--     variants: .highlight, .alert; optional title="..." attribute

if FORMAT ~= "typst" then
  return {}
end

local function wrap(div, open)
  local blocks = pandoc.Blocks({ pandoc.RawBlock("typst", open) })
  blocks:extend(div.content)
  blocks:insert(pandoc.RawBlock("typst", "]"))
  return blocks
end

function Div(div)
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
