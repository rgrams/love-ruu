
local M = {}

function M.hover(self)
	self.isHovered = true
	self.theme[self.themeType].hover(self)
end

function M.unhover(self)
	self.isHovered = false
	self.theme[self.themeType].unhover(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
end

function M.focus(self)
	self.isFocused = true
	self.theme[self.themeType].focus(self)
end

function M.unfocus(self)
	self.isFocused = false
	self.theme[self.themeType].unfocus(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
end

function M.press(self)
	self.isPressed = true
	self.theme[self.themeType].press(self)
	if self.pressFunc then  self:pressFunc()  end
end

function M.release(self, dontFire)
	self.isPressed = false
	self.theme[self.themeType].release(self, dontFire)
	if self.releaseFunc and not dontFire then  self:releaseFunc()  end
end

-- Have this function here, or keep it in manager?
function M.focusNeighbor(self, dir)
	local neighbor = self.neighbors[dir]
	if neighbor then
		self:unfocus()
		neighbor:focus()
	end
	return neighbor
end

return M
