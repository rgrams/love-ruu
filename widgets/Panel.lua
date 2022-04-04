
local _basePath = (...):gsub("Panel$", "")
local Button = require(_basePath .. "Button")

local Panel = Button:extend()
Panel.className = "Panel"

-- Mostly the same as Button.

function Panel.set(self, ruu, themeData, wgtTheme)
	Panel.super.set(self, ruu, themeData, nil, wgtTheme) -- No callback.
end

function Panel.focus(self, isKeyboard, depthIndex)
	self.panelIndex = depthIndex or 1
	self.isFocused = true
	self.wgtTheme.focus(self, isKeyboard, depthIndex)
end

function Panel.unfocus(self, isKeyboard)
	self.isFocused = false
	self.wgtTheme.unfocus(self, isKeyboard)
	if self.isPressed then  self:release(true)  end
end

return Panel
