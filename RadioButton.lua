
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local RadioButton = Button:extend()

function RadioButton.release(self, dontFire)
	self.isPressed = false
	if not dontFire then
		if not self.isChecked then
			self.isChecked = true
			for i,btn in ipairs(self.siblings) do
				btn.theme[btn.themeType].uncheck(btn)
				btn.isChecked = false
			end
		end
		if self.releaseFunc then  self:releaseFunc()  end
	end
	self.theme[self.themeType].release(self, dontFire)
end

return RadioButton
