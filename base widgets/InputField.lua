
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local InputField = Button:extend()

local function clamp(x, min, max)
	return x > min and (x < max and x or max) or min
end

function InputField.setSelection(self, startI, endI)
	if startI and endI then
		if startI == endI then -- Nothing actually selected
			self.selection.i1, self.selection.i2 = nil, nil
			return
		end
		local startI, endI = math.min(startI, endI), math.max(startI, endI) -- Make sure they're in order.
		self.selection.i1, self.selection.i2 = startI, endI
		local left = -self.w/2 + self.padX
		local preText = string.sub(self.text, 0, startI)
		self.selection.x1 = self.label.font:getWidth(preText)
		local toEndText = string.sub(self.text, 0, endI)
		self.selection.x2 = self.label.font:getWidth(toEndText)
	else
		self.selection.i1, self.selection.i2 = nil, nil
	end
end

function InputField.focus(self)
	if not self.isFocused then
		self:setSelection(0, #self.text) -- Select all.
		self:setCursorPos(#self.text) -- Set cursor to end.
		self.oldText = self.text -- Save in case of cancel.
	end
	self.isFocused = true
	self.theme[self.themeType].focus(self)
end

function InputField.unfocus(self)
	self.isFocused = false
	self.theme[self.themeType].unfocus(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
	if self.confirmFunc and self.text ~= self.oldText then  self:confirmFunc()  end
end

-- Update cursor pixel position, etc.
local function updateCursorX(self)
	self.cursorX = self.label.font:getWidth(self.preCursorText)
	-- TODO: Update mask scrolling.
end

function InputField.setCursorPos(self, absolute, delta)
	-- Modify cursor index.
	delta = delta or 0
	absolute = (absolute or self.cursorI) + delta
	self.cursorI = clamp(absolute, 0, #self.text)
	-- Re-slice text around cursor.
	self.preCursorText = string.sub(self.text, 0, self.cursorI)
	self.postCursorText = string.sub(self.text, self.cursorI + 1)

	updateCursorX(self)
end

function InputField.setText(self, text, isPlaceholder)
	self.text = text
	self.label.text = text
	if self.editFunc then  self:editFunc(text)  end
	self.theme[self.themeType].setText(self, isPlaceholder)
end

local function replaceSelection(self, replaceWith)
	replaceWith = replaceWith or ""
	local cursorPos = self.selection.i1 + #replaceWith
	self.preCursorText = string.sub(self.text, 0, self.selection.i1)
	self.preCursorText = self.preCursorText .. replaceWith
	self.postCursorText = string.sub(self.text, self.selection.i2 + 1)
	self.selection.i1, self.selection.i2 = nil, nil

	self:setText(self.preCursorText .. self.postCursorText)
	self.cursorI = clamp(cursorPos, 0, #self.text)
	updateCursorX(self)
end

function InputField.textInput(self, char)
	if self.selection.i1 then
		replaceSelection(self, char)
	else
		self.preCursorText = self.preCursorText .. char
		self:setText(self.preCursorText .. self.postCursorText)
		self.cursorI = clamp(self.cursorI + 1, 0, #self.text)
		updateCursorX(self)
	end
end

function InputField.backspace(self)
	if self.selection.i1 then
		replaceSelection(self)
	else
		self.preCursorText = string.sub(self.preCursorText, 1, -2)
		self:setText(self.preCursorText .. self.postCursorText)
		self.cursorI = clamp(self.cursorI - 1, 0, #self.text)
		updateCursorX(self)
	end
end

function InputField.delete(self)
	if self.selection.i1 then
		replaceSelection(self)
	else
		self.postCursorText = string.sub(self.postCursorText, 2)
		self:setText(self.preCursorText .. self.postCursorText)
	end
end

function InputField.release(self, dontFire, mx, my, isKeyboard)
	self.super.release(self, dontFire, mx, my, isKeyboard)
	if isKeyboard and not dontFire and self.confirmFunc then
		if self.text ~= self.oldText then  self:confirmFunc()  end
	end
end

local function moveCursor(self, delta, absolute)
	if self.ruu.getInput("shift") == 1 then
		-- Find the selection direction - check which selection index is at the cursor.
		local key = self.selection.i1 == self.cursorI and "i1" or "i2"
		local otherKey = key == "i1" and "i2" or "i1"
		local oldCursorI = self.cursorI
		self:setCursorPos(absolute, delta)
		self.selection[key] = self.cursorI -- Move the correct end of the selection.
		if not self.selection[otherKey] then -- Starting a new selection.
			self.selection[otherKey] = oldCursorI
		end
		self:setSelection(self.selection.i1, self.selection.i2) -- Updates the selection x and y coords.
	else
		if self.selection.i1 then
			local cursorI
			if delta and math.abs(delta) == 1 then -- If it's only one move, jump to end of selection.
				local key = delta < 0 and "i1" or "i2" -- Choose selection end in movement direction.
				cursorI = self.selection[key]
			else -- Larger move, ignore selection and follow the user input.
				cursorI = absolute
			end
			self.selection.i1, self.selection.i2 = nil, nil
			self:setCursorPos(cursorI, delta)
		else
			self:setCursorPos(absolute, delta)
		end
	end
end

function InputField.getFocusNeighbor(self, dir)
	if dir == "left" then
		moveCursor(self, -1)
		return 1 -- Consume input.
	elseif dir == "right" then
		moveCursor(self, 1)
		return 1 -- Consume input.
	else
		return self.neighbor[dir]
	end
end

function InputField.ruuinput(self, action, value, change, isRepeat)
	if action == "home" and change == 1 then
		moveCursor(self, nil, 0)
	elseif action == "end" and change == 1 then
		moveCursor(self, nil, #self.text)
	elseif action == "cancel" and change == 1 then
		self.text, self.label.text = self.oldText, self.oldText
		self.isFocused = false
		self:focus()
	end
end

return InputField
