
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local SliderBar = Button:extend()

function SliderBar.release(self, dontFire, mx, my)
	if not dontFire then
		-- TODO: Get release X and Y from RUU.
		-- TODO: Figure which side of the slider handle the user clicked.
		--       Move self.barClickDist in that direction.
		--          self.handle:drag(dx, 0, true)
	end
	SliderBar.super.release(self, dontFire)
end

return SliderBar
