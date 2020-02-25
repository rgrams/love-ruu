
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local InputField = Button:extend()

function InputField.focus(self)
	if not self.isFocused then
		-- TODO: Select all.
		-- Set cursor to end.
		self:setCursorPos(#self.text)
	end
	self.isFocused = true
	self.theme[self.themeType].focus(self)
end

function InputField.unfocus(self)
	self.isFocused = false
	self.theme[self.themeType].unfocus(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
end

function InputField.setCursorPos(self, absolute, delta)
	-- Modify cursor index.
	delta = delta or 0
	absolute = (absolute or self.cursorI) + delta
	self.cursorI = math.max(0, math.min(#self.text, absolute))
	-- Re-slice text around cursor.
	self.preCursorText = string.sub(self.text, 0, self.cursorI)
	self.postCursorText = string.sub(self.text, self.cursorI + 1)
	-- Update cursor pixel position, etc.
	self.cursorX = self.label.font:getWidth(self.preCursorText)
	-- TODO: Update mask scrolling.
end

function InputField.setText(self, text, isPlaceholder)
	self.text = text
	self.label.text = text
	if self.editFunc then  self:editFunc(text)  end
	self.theme[self.themeType].setText(self, isPlaceholder)
end

function InputField.textInput(self, char)
	self:setText(self.preCursorText .. char .. self.postCursorText)
	self:setCursorPos(nil, 1)
end

function InputField.backspace(self)
	self.preCursorText = string.sub(self.preCursorText, 1, -2)
	self:setText(self.preCursorText .. self.postCursorText)
	self:setCursorPos(nil, -1)
end

function InputField.delete(self)
	self.postCursorText = string.sub(self.postCursorText, 2)
	self:setText(self.preCursorText .. self.postCursorText)
end

function InputField.release(self, dontFire, mx, my, isKeyboard)
	self.super.release(self, dontFire, mx, my, isKeyboard)
	if isKeyboard and not dontFire and self.confirmFunc then  self:confirmFunc()  end
end

function InputField.getFocusNeighbor(self, dir)
	if dir == "left" then
		self:setCursorPos(nil, -1)
	elseif dir == "right" then
		self:setCursorPos(nil, 1)
	else
		return self.neighbor[dir]
	end
end

return InputField
