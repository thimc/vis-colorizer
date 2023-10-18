local M = {
  text_colors = {
    dark = "black",
    light = "white"
  }
}

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
	local pattern = "#([0-9a-fA-F]+)"
	local matches = {}

	local init = 1
	local match_end = 0
	while true do
		match_start, match_end, hex = string.find(input_string, pattern, init + match_end)
		-- TODO: add better validation
		if match_start == nil or hex == nil then
			break
		end
		if hex:len() == 3 or hex:len() == 6 then
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
	local offset = win.viewport.start
	for i, color in ipairs(colors) do
		local fg = M.text_colors.light

		if color.hex:len() == 3 then
			color.hex = string.gsub(color.hex,
				"([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])",
				"%1%1%2%2%3%3")
		end

		local r = tonumber(color.hex:sub(1, 2), 16)
		local g = tonumber(color.hex:sub(3, 4), 16)
		local b = tonumber(color.hex:sub(5, 6), 16)

		if (r * 30) + (g * 59) + (b * 11) > 12000 then
			fg = M.text_colors.dark
		end

		local id = table.remove(styleIdStack)

		local style = "fore:" .. fg .. ",back:#" .. color.hex
		if not win:style_define(id, style) then
			break
		end
		win:style(id, color.starts - 1 + offset, color.ends - 1 + offset)
		table.insert(styleIdStack, id)
		if color.ends >= win.viewport.finish then
			break
		end
	end
end

M.on_higlight = function(win)
	local content = win.file:content(win.viewport)
	local hex_colors = M.extract_hex_colors(content)
	M.draw(win, hex_colors)
end

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, M.on_higlight)

return M
