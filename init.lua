local M = {
    text_colors = {
        -- use vis defaults
        dark = "black",
        light = "white"
    },
    -- Highlight six digit hex color codes
    six = true,
    -- Highlight three digit hex color hexcodes
    three = false,
}

local hex_map = {}
for i = 0, 9 do 
    hex_map[48 + i] = i -- 0-9
end
for i = 0, 5 do
    hex_map[65 + i] = 10 + i -- A-F
    hex_map[97 + i] = 10 + i -- a-f
end

local fstring = string.format
local byte = string.byte

local function hex_to_rgb(hex)
    -- skip #
    local offset = byte(hex, 1) == 35 and 1 or 0
    local len = #hex - offset

    if len == 6 then
        local r1, r2, g1, g2, b1, b2 = byte(hex, offset + 1, offset + 6)
        return hex_map[r1] * 16 + hex_map[r2],
               hex_map[g1] * 16 + hex_map[g2],
               hex_map[b1] * 16 + hex_map[b2]
    elseif len == 3 then
        local r, g, b = byte(hex, offset + 1, offset + 3)
        -- 0~255 = 0~15 * 16 + 0~15 = 0~15 * 17
        return hex_map[r] * 17,
               hex_map[g] * 17,
               hex_map[b] * 17
    end
end

local styleIdStack = {}

M.styleIdIterator = function()
    local i = 0
    local MAX_STYLE_ID = 64 -- UI_STYLE_LEXER_MAX = 64
    return function()
        i = i + 1
        if i <= MAX_STYLE_ID then
            return i
        end
        return nil
    end
end

M.initStyleIds = function()
    styleIdStack = {}
    for i in M.styleIdIterator() do
        table.insert(styleIdStack, i)
    end
end

M.initStyleIds()

M.extract_hex_colors = function(input_string)
    local pattern = "#(%x%x%x+)"
    local matches = {}

    local init = 1
    local match_end = 0
    while true do
        match_start, match_end, hex = input_string:find(pattern, init + match_end)
        -- TODO: add better validation
        if match_start == nil or hex == nil then
            break
        end
        if (hex:len() == 3 and M.three)  or (hex:len() == 6 and M.six) then
            table.insert(matches, {
                starts = match_start,
                ends = match_end,
                hex = hex,
            })
        end
    end

    return matches
end

M.draw = function(win, colors)
    local offset = win.viewport['bytes'].start
    for i, color in ipairs(colors) do
        local fg = M.text_colors.light
        local r, g, b = hex_to_rgb(color.hex)
        local style

        if (r * 30) + (g * 59) + (b * 11) > 12000 then
            fg = M.text_colors.dark
        end
        
        -- workaround if terminal doesnt support #000000 #000
        if r+g+b == 0 then
            style = fstring("fore:%s,back:black", fg)
        else
            style = fstring("fore:%s,back:#%2X%2X%2X", fg, r, g, b)
        end
        local id = table.remove(styleIdStack)

        -- fallback using win.style_define if vis.ui.style_define not exist
        if vis.ui.style_define and not vis.ui:style_define(id, style) then 
            break
        elseif win.style_define and not win:style_define(id, style) then
	        break
        end
        win:style(id, color.starts - 1 + offset, color.ends - 1 + offset)
        table.insert(styleIdStack, id)
        if color.ends >= win.viewport['bytes'].finish then
            break
        end
     end
end

M.on_higlight = function(win)
    local content = win.file:content(win.viewport['bytes'])
    local hex_colors = M.extract_hex_colors(content)
    M.draw(win, hex_colors)
end

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, M.on_higlight)

return M
