
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local InputField = Button:extend()

local baseAlignVals = { left = -1, center = 0, right = 1, justify = -1 }
local textAlignVals = { left = 0, center = -0.5, right = -1, justify = 0 }

local function clamp(x, min, max)
	return x > min and (x < max and x or max) or min
end

local function getTextLeftPos(self, labelLocal, flip)
	local hAlign = self.label.hAlign
	local left = self.label.w/2 * baseAlignVals[hAlign]
	local textAlign = textAlignVals[hAlign] + (flip and 1 or 0)
	left = left + self.label.font:getWidth(self.text) * textAlign


	if not labelLocal then
		local wx, wy = self.label:toWorld(left, 0)
		local lx, ly = self:toLocal(wx, wy)
		left = lx
	end
	return left
end

local function scrollTo(self, endX, limitX, toLeft)
	if toLeft and endX < limitX then
		local outDist = endX - limitX
		self.scrollX = self.scrollX - outDist
		self.mask:setOffset(self.scrollX, 0)
		return true
	elseif not toLeft and endX > limitX then
		local outDist = endX - limitX
		self.scrollX = self.scrollX - outDist
		self.mask:setOffset(self.scrollX, 0)
		return true
	end
end

-- Outside scripts may want to call this when the InputField is resized.
function InputField.updateScroll(self)
	local oldCursorX = self.cursorX
	if self.isFocused then 	-- If in focus, ensure that cursor is in view.
		local oldScrollX = self.scrollX
		if self.label.font:getWidth(self.text) <= self.innerW then
			self.scrollX = 0
			self.mask:setOffset(self.scrollX, 0)
		else
			scrollTo(self, self.cursorX, self.innerW/2, false)
			scrollTo(self, self.cursorX, -self.innerW/2, true)
		end
		local deltaScroll = self.scrollX - oldScrollX
		if deltaScroll ~= 0 then
			self.cursorX = self.cursorX + deltaScroll
			if self.selection.x1 and self.selection.x2 then
				self.selection.x1 = self.selection.x1 + deltaScroll
				self.selection.x2 = self.selection.x2 + deltaScroll
			end
		end
	else -- Not in focus, scroll to one end according to the `self.scrollToRight` setting.
		if self.label.font:getWidth(self.text) <= self.innerW then
			self.scrollX = 0
			self.mask:setOffset(self.scrollX, 0)
		else
			local endPos = getTextLeftPos(self, nil, self.scrollToRight)
			if self.scrollToRight then
				scrollTo(self, endPos, self.innerW/2, false)
				scrollTo(self, endPos, self.innerW/2, true) -- Use up any extra space if there is some.
			else
				scrollTo(self, endPos, -self.innerW/2, true)
				scrollTo(self, endPos, -self.innerW/2, false) -- Use up any extra space if there is some.
			end
		end
		-- Don't care about the cursorX when not in focus - it's not shown and will be changed on focus.
	end
end

-- Update cursor pixel position, etc.
local function updateCursorX(self)
	local left = getTextLeftPos(self)
	self.cursorX = left + self.label.font:getWidth(self.preCursorText)
	self:updateScroll()
end

local function updateCursorSlices(self)
	self.preCursorText = string.sub(self.text, 0, self.cursorI)
	self.postCursorText = string.sub(self.text, self.cursorI + 1)
end

function InputField.setSelection(self, startI, endI)
	if startI and endI then
		if startI == endI then -- Nothing actually selected
			self.selection.i1, self.selection.i2 = nil, nil
			return
		end
		local startI, endI = math.min(startI, endI), math.max(startI, endI) -- Make sure they're in order.
		self.selection.i1, self.selection.i2 = startI, endI

		-- Calculate local x positions for start and end of selection.
		local left = getTextLeftPos(self)
		local preText = string.sub(self.text, 0, startI)
		self.selection.x1 = left + self.label.font:getWidth(preText)
		self.selection.x1 = math.max(-self.innerW/2, self.selection.x1)
		local toEndText = string.sub(self.text, 0, endI)
		self.selection.x2 = left + self.label.font:getWidth(toEndText)
		self.selection.x2 = math.min(self.innerW/2, self.selection.x2)
	else
		self.selection.i1, self.selection.i2 = nil, nil
	end
end

function InputField.focus(self, isKeyboard)
	if not self.isFocused then
		self.isFocused = true
		self.oldText = self.text -- Save in case of cancel.
		if isKeyboard then
			self:setCursorPos(#self.text) -- Set cursor to end.
			self:setSelection(0, #self.text) -- Select all.
		end
	end
	self.theme[self.themeType].focus(self)
end

function InputField.unfocus(self, isKeyboard)
	self.isFocused = false
	self.theme[self.themeType].unfocus(self)
	if self.isPressed then  self:release(true)  end -- Release without firing.
	if self.confirmFunc and self.text ~= self.oldText then
		local rejected = self:confirmFunc(true)
		if rejected then  self:cancel()  end
	end
	self:updateScroll()
end

-- Takes an X coordinate local to the label, returns an index and a local X pos of that index.
local function getClosestIndexToX(self, x)
	local left = getTextLeftPos(self, true)
	if x < left then  return 0, left  end
	local font = self.label.font
	local textWidth = font:getWidth(self.text)
	if x > left + textWidth then  return #self.text, left + textWidth  end
	local minDist, minIndex, minX = math.huge, 0, 0
	for i=1,#self.text do
		local w = font:getWidth(string.sub(self.text, 0, i))
		local dist = math.abs(left + w - x)
		if dist < minDist then
			minDist, minIndex, minX = dist, i, left + w
		end
	end
	return minIndex, minX
end

function InputField.drag(self, dx, dy, dragType)
	if dragType then  return  end -- Only default drags.
	self.dragX, self.dragY = self.dragX + dx, self.dragY + dy
	local lx, ly = self.label:toLocal(self.dragX, self.dragY)
	local i, x = getClosestIndexToX(self, lx)
	local wx, wy = self.label:toWorld(x, 0)
	local lx, ly = self:toLocal(wx, wy)
	self.cursorI, self.cursorX = i, lx
	updateCursorSlices(self)
	updateCursorX(self) -- To update mask scroll.
	self:setSelection(self.dragI, i)
end

function InputField.press(self, mx, my, isKeyboard)
	self.super.press(self, mx, my, isKeyboard)
	if not isKeyboard then -- Set cursor to mouse pos.
		local lx, ly = self.label:toLocal(mx, my)
		local i, x = getClosestIndexToX(self, lx)
		self.cursorI, self.cursorX = i, x
		updateCursorSlices(self)
		updateCursorX(self)
		self.dragI, self.dragX, self.dragY = i, mx, my
		self:setSelection(nil, nil)
	end
end

function InputField.release(self, dontFire, mx, my, isKeyboard)
	self.super.release(self, dontFire, mx, my, isKeyboard)
	if isKeyboard and not dontFire and self.confirmFunc then
		if self.text ~= self.oldText then
			local rejected = self:confirmFunc(false)
			if rejected then  self:cancel()  end
		end
	end
end

function InputField.cancel(self)
	self.text, self.label.text = self.oldText, self.oldText
	self:setCursorPos(#self.text)
	self:setSelection(0, #self.text)
end

function InputField.setCursorPos(self, absolute, delta)
	-- Modify cursor index.
	delta = delta or 0
	absolute = (absolute or self.cursorI) + delta
	self.cursorI = clamp(absolute, 0, #self.text)
	-- Re-slice text around cursor.
	updateCursorSlices(self)

	updateCursorX(self)
end

function InputField.setText(self, text)
	self.text = text
	self.label.text = text

	if self.editFunc then  self:editFunc(text)  end
	self.theme[self.themeType].setText(self)
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

function InputField.textInput(self, text)
	if self.selection.i1 then
		replaceSelection(self, text)
	else
		self.preCursorText = self.preCursorText .. text
		self:setText(self.preCursorText .. self.postCursorText)
		self.cursorI = clamp(self.cursorI + #text, 0, #self.text)
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
		updateCursorX(self)
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
		self:cancel()
	elseif action == "cut" and change == 1 then
		if self.selection.i1 then
			local selText = string.sub(self.text, self.selection.i1+1, self.selection.i2)
			love.system.setClipboardText(selText)
			self:delete()
		end
	elseif action == "copy" and change == 1 then
		if self.selection.i1 then
			local selText = string.sub(self.text, self.selection.i1+1, self.selection.i2)
			love.system.setClipboardText(selText)
		end
	elseif action == "paste" and change == 1 then
		self:textInput(love.system.getClipboardText())
	elseif action == "select all" and change == 1 then
		self:setCursorPos(#self.text) -- Set cursor to end.
		self:setSelection(0, #self.text) -- Select all.
	end
end

return InputField
