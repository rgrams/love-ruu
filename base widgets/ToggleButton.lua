
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local ToggleButton = Button:extend()

function ToggleButton.release(self, dontFire, mx, my, isKeyboard)
	self.isPressed = false
	if not dontFire then
		self.isChecked = not self.isChecked
		if self.releaseFunc then  self:releaseFunc(mx, my, isKeyboard)  end
	end
	self.theme[self.themeType].release(self, dontFire)
end

return ToggleButton
