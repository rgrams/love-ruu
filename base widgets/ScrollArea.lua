
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local ScrollArea = Button:extend()

function ScrollArea.scroll(self, dx, dy)
	dx = (dx or 0) * self.scrollDist
	dy = (dy or 0) * self.scrollDist
	self.scrollX, self.scrollY = self.scrollX + dx, self.scrollY + dy
	self:setOffset(self.scrollX, self.scrollY)
end

return ScrollArea