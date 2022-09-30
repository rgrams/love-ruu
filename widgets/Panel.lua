
local _basePath = (...):gsub("Panel$", "")
local Button = require(_basePath .. "Button")

local Panel = Button:extend()
Panel.className = "Panel"

-- Mostly the same as Button.

function Panel.set(self, ruu, themeData, theme)
	Panel.super.set(self, ruu, themeData, nil, theme) -- No callback.
end

function Panel.focus(self, depth, isKeyboard)
	self.panelIndex = depth
	self.isFocused = true
	self.theme.focus(self, isKeyboard)
end

function Panel.unfocus(self, depth, isKeyboard)
	self.isFocused = false
	self.theme.unfocus(self, isKeyboard)
	if self.isPressed then  self:release(depth, true)  end
end

return Panel
