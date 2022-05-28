
local _basePath = (...):gsub("widgets.Button$", "")
local Class = require(_basePath .. "base-class")

local Button = Class:extend()
Button.className = "Button"

Button.isHovered = false
Button.isPressed = false
Button.isFocused = false

function Button.__tostring(self)
	return "(Ruu "..self.className.." "..self.id..")"
end

function Button.set(self, ruu, themeData, releaseFn, wgtTheme)
	self.ruu = ruu -- Only used for InputFields.
	self.releaseFn = releaseFn
	self.isEnabled = true
	self.neighbor = {}
	self.themeData = themeData
	themeData.widget = self
	self.wgtTheme = wgtTheme
	self.wgtTheme.init(self, self.themeData)
end

function Button.args(self, arg1, ...)
	self.releaseArgs = arg1 ~= nil and {arg1,...} or nil -- `arg1` can be `false`.
	return self -- Allow chaining.
end

function Button.hitCheck(self, x, y)
	return self.themeData:hitCheck(x, y)
end

function Button.hover(self, depth)
	if depth ~= 1 then  return  end
	self.isHovered = true
	self.wgtTheme.hover(self)
end

function Button.unhover(self, depth)
	if depth ~= 1 then  return  end
	self.isHovered = false
	self.wgtTheme.unhover(self)
	if self.isPressed then  self:release(depth, true)  end -- Release without firing.
end

function Button.focus(self, depth, isKeyboard)
	if depth ~= 1 then  return  end
	self.isFocused = true
	self.wgtTheme.focus(self, isKeyboard)
end

function Button.unfocus(self, depth, isKeyboard)
	if depth ~= 1 then  return  end
	self.isFocused = false
	self.wgtTheme.unfocus(self, isKeyboard)
	if self.isPressed then  self:release(depth, true)  end -- Release without firing.
end

function Button.press(self, depth, mx, my, isKeyboard)
	if depth ~= 1 then  return  end
	self.isPressed = true
	self.wgtTheme.press(self, mx, my, isKeyboard)
	if self.pressFn then  self:pressFn(mx, my, isKeyboard)  end
end

function Button.release(self, depth, dontFire, mx, my, isKeyboard)
	if depth ~= 1 then  return  end
	if not self.isPressed then  dontFire = true  end
	self.isPressed = false
	self.wgtTheme.release(self, dontFire, mx, my, isKeyboard)
	if self.releaseFn and not dontFire then
		if self.releaseArgs then
			self.releaseFn(unpack(self.releaseArgs))
		else
			self.releaseFn(self)
		end
	end
end

function Button.getFocusNeighbor(self, depth, dir)
	if depth ~= 1 then  return  end
	return self.neighbor[dir]
end

return Button
