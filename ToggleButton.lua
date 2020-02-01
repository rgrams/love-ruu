
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local ToggleButton = Button:extend()

function ToggleButton.release(self, dontFire)
	self.isPressed = false
	if not dontFire then
		self.isChecked = not self.isChecked
		if self.releaseFunc then  self:releaseFunc()  end
	end
	self.theme[self.themeType].release(self, dontFire)
end

return ToggleButton
