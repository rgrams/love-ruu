
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local InputField = Button:extend()

function InputField.setText(self, text, isPlaceholder)
	self.text = text
	self.textObj.text = text
	if self.editFunc then  self:editFunc(text)  end
	self.theme[self.themeType].setText(self, isPlaceholder)
end

function InputField.textInput(self, char)
	self:setText(self.text .. char)
end

function InputField.backspace(self)
	self:setText(string.sub(self.text, 1, -2))
end

function InputField.release(self, dontFire, mx, my, isKeyboard)
	self.super.release(self, dontFire, mx, my, isKeyboard)
	if isKeyboard and not dontFire and self.confirmFunc then  self:confirmFunc()  end
end

function InputField.getFocusNeighbor(self, dir)
	return self.neighbor[dir]
end

return InputField