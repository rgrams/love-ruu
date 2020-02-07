
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local SliderBar = Button:extend()

function SliderBar.press(self, mx, my)
	if not dontFire then
		-- Figure on which side of the handle the user clicked & slide in that direction.
		local handleX = self.handle.parentOffsetX
		local localClickX, localClickY = self:toLocal(mx, my)
		if localClickX > handleX then
			self.handle:drag(self.handle.barClickDist, 0, true)
		elseif localClickX < handleX then
			self.handle:drag(-self.handle.barClickDist, 0, true)
		end
	end
	SliderBar.super.press(self, mx, my)
end

return SliderBar
