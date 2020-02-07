
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local InputField = Button:extend()

function InputField.setText(self, text, isPlaceholder)
	self.text = text
	self.textObj.text = text
	self.theme[self.themeType].setText(self, isPlaceholder)
end

function InputField.textInput(self, char)
	self:setText(self.text .. char)
end

function InputField.backspace(self)
	self:setText(string.sub(self.text, 1, -2))
end

function InputField.getFocusNeighbor(self, dir)
	return self.neighbor[dir]
end

return InputField