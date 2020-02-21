
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local Panel = Button:extend()

-- Mostly the same as Button.

function Panel.focus(self, index)
	if index then  self.panelIndex = index  end -- For drawing.
	self.isFocused = true
	self.theme[self.themeType].focus(self)
end

function Panel.unfocus(self)
	self.isFocused = false
	self.theme[self.themeType].unfocus(self)
	if self.isPressed then  self:release(true)  end
end

return Panel
