
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local RadioButton = Button:extend()

function RadioButton.release(self, dontFire, mx, my, isKeyboard)
	self.isPressed = false
	if not dontFire then
		if not self.isChecked then
			self.isChecked = true
			for i,btn in ipairs(self.siblings) do
				btn.isChecked = false
				btn.theme[btn.themeType].setChecked(btn)
			end
		end
		if self.releaseFunc then  self:releaseFunc(mx, my, isKeyboard)  end
	end
	self.theme[self.themeType].release(self, dontFire, mx, my)
end

-- For outside scripts to manually check or uncheck buttons.
function RadioButton.setChecked(self, isChecked)
	if self.isChecked and not isChecked then -- Un-check.
		local _,sibToCheck = next(self.siblings)
		if sibToCheck then
			sibToCheck.isChecked = true
			sibToCheck.theme[sibToCheck.themeType].setChecked(sibToCheck)
		end
	elseif isChecked and not self.isChecked then -- Check.
		for i,sib in ipairs(self.siblings) do
			sib.isChecked = false
			sib.theme[sib.themeType].setChecked(sib)
		end
	end
	self.isChecked = isChecked
	self.theme[self.themeType].setChecked(self)
end

return RadioButton
