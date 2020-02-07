
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

function Button.press(self, mx, my, isKeyboard)
	self.isPressed = true
	self.theme[self.themeType].press(self, mx, my)
	if self.pressFunc then  self:pressFunc(mx, my)  end
end

function Button.release(self, dontFire, mx, my, isKeyboard)
	self.isPressed = false
	self.theme[self.themeType].release(self, dontFire, mx, my)
	if self.releaseFunc and not dontFire then  self:releaseFunc(mx, my)  end
end

function Button.getFocusNeighbor(self, dir)
	return self.neighbor[dir]
end

return Button
