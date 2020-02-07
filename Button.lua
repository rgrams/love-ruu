
local basePath = (...):gsub('[^%.]+$', '')
local Class = require(basePath .. "base-class")
local Button = Class:extend()

function Button.hover(self)
	self.isHovered = true
	self.theme[self.themeType].hover(self)
end

function Button.unhover(self)
	self.isHovered = false
	self.theme[self.themeType].unhover(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
end

function Button.focus(self)
	self.isFocused = true
	self.theme[self.themeType].focus(self)
end

function Button.unfocus(self)
	self.isFocused = false
	self.theme[self.themeType].unfocus(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
end

function Button.press(self, mx, my)
	self.isPressed = true
	self.theme[self.themeType].press(self, mx, my)
	if self.pressFunc then  self:pressFunc(mx, my)  end
end

function Button.release(self, dontFire, mx, my)
	self.isPressed = false
	self.theme[self.themeType].release(self, dontFire, mx, my)
	if self.releaseFunc and not dontFire then  self:releaseFunc(mx, my)  end
end

-- Have this function here, or keep it in manager?
function Button.focusNeighbor(self, dir)
	local neighbor = self.neighbors[dir]
	if neighbor then
		self:unfocus()
		neighbor:focus()
	end
	return neighbor
end

return Button
