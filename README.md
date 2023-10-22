# vis-colorizer
Highlights hex colors. Created for the [vis editor](https://github.com/martanne/vis).

Inspired by [chrisbra/Colorizer](https://github.com/chrisbra/Colorizer).

![image](https://github.com/thimc/vis-colorizer/blob/main/screenshot.png)

## Usage

Clone the repo to `~/.config/vis/plugins/`.

Append the following line to your `visrc.lua`:

	local colorizer = require('plugins/vis-colorizer')
	colorizer.three = false -- (optional) diables three digit hex colors
	colorizer.six   = true  -- (enabled by default) six digit hex colors

