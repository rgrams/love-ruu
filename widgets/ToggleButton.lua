
local _basePath = (...):gsub("widgets.ToggleButton$", "")
local Button = require(_basePath .. "widgets.Button")

local ToggleButton = Button:extend()
ToggleButton.className = "ToggleBtn"

function ToggleButton.set(self, ruu, themeData, releaseFn, isChecked, wgtTheme)
	self.isChecked = isChecked -- Needs to be set before theme.init.
	ToggleButton.super.set(self, ruu, themeData, releaseFn, wgtTheme)
end

function ToggleButton.release(self, depth, dontFire, mx, my, isKeyboard)
	if depth ~= 1 then  return  end
	if not self.isPressed then  dontFire = true  end
	if not dontFire then
		self.isChecked = not self.isChecked
	end
	ToggleButton.super.release(self, depth, dontFire, mx, my, isKeyboard)
end

function ToggleButton.setChecked(self, isChecked)
	self.isChecked = isChecked
	self.wgtTheme.setChecked(isChecked)
end

return ToggleButton
