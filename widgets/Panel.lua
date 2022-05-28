
local _basePath = (...):gsub("Panel$", "")
local Button = require(_basePath .. "Button")

local Panel = Button:extend()
Panel.className = "Panel"

-- Mostly the same as Button.

function Panel.set(self, ruu, themeData, wgtTheme)
	Panel.super.set(self, ruu, themeData, nil, wgtTheme) -- No callback.
end

function Panel.focus(self, depth, isKeyboard)
	self.panelIndex = depth
	self.isFocused = true
	self.wgtTheme.focus(self, isKeyboard)
end

function Panel.unfocus(self, depth, isKeyboard)
	self.isFocused = false
	self.wgtTheme.unfocus(self, isKeyboard)
	if self.isPressed then  self:release(depth, true)  end
end

return Panel
