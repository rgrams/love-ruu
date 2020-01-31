
local M = {}

local button = {}
M.button = button

local function setValue(self, val)
	local c = self.color
	c[1], c[2], c[3] = val, val, val
end

function button.init(self)
	setValue(self, 0.6)
end

function button.hover(self)
	setValue(self, 0.8)
end

function button.unhover(self)
	setValue(self, 0.6)
end

function button.focus(self)
	self.sy = 1.2
end

function button.unfocus(self)
	self.sy = 1
end

function button.press(self)
	setValue(self, 0.45)
end

function button.release(self)
	setValue(self, self.isHovered and 0.8 or 0.6)
end


return M
