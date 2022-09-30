
local _basePath = (...):gsub("InputField$", "")
local Button = require(_basePath .. "Button")

local InputField = Button:extend()
InputField.className = "InputField"

function InputField.set(self, ruu, themeData, confirmFn, text, theme)
	self.text = text and tostring(text) or ""
	self.confirmFn = confirmFn
	self.cursorIdx = #self.text
	InputField.super.set(self, ruu, themeData, nil, theme)
end

function InputField.onEdit(self, editFn)
	self.editFn = editFn
	return self -- Allow chaining.
end

local function fireCallback(self, fn)
	if fn then
		if self.releaseArgs then
			return fn(unpack(self.releaseArgs))
		else
			return fn(self)
		end
	end
end

function InputField.confirmText(self)
	local isRejected = fireCallback(self, self.confirmFn)
	if isRejected then
		local rejectedText = self.text
		self:cancel(1)
		self.ruu:callTheme(self, self.theme, "textRejected", rejectedText)
	else
		self.oldText = self.text -- Save text for next time.
	end
end

function InputField.release(self, depth, dontFire, mx, my, isKeyboard)
	if depth > 1 then  return  end
	if not self.isPressed then  dontFire = true  end
	self.isPressed = false
	if self.releaseFn and not dontFire then
		fireCallback(self, self.releaseFn)
	end
	if isKeyboard and self.confirmFn and not dontFire then
		self:confirmText()
	end
	if not dontFire then
		self:selectAll()
	end
	self.ruu:callTheme(self, self.theme, "release", dontFire, mx, my, isKeyboard)
end

function InputField.focus(self, depth, isKeyboard)
	if depth > 1 then  return  end
	if not self.isFocused then
		self.isFocused = true
		self.oldText = self.text -- Save in case of cancel.
		self:selectAll()
	end
	self.ruu:callTheme(self, self.theme, "focus")
end

function InputField.unfocus(self, depth, isKeyboard)
	if depth > 1 then  return  end
	self.isFocused = false
	if self.isPressed then  self:release(depth, true)  end -- Release without firing.
	if isKeyboard and self.isEnabled and self.confirmFn then
		self:confirmText()
	end
	self.ruu:callTheme(self, self.theme, "unfocus", isKeyboard)
end

--------------------  Internal Text Setting  --------------------
function InputField.updateText(self, text)
	self.text = text
	fireCallback(self, self.editFn) -- EditFn can modify self.text.
	self.ruu:callTheme(self, self.theme, "updateText")
end

function InputField.insertText(self, text)
	text = text or ""
	local preCursorText, postCursorText

	if self.hasSelection then
		-- Slice around selection and de-select.
		local selectionLeftIdx, selectionRightIdx = self:getSelectionLeftIdx(), self:getSelectionRightIdx()
		preCursorText = string.sub(self.text, 0, selectionLeftIdx)
		postCursorText = string.sub(self.text, selectionRightIdx + 1)
		self.cursorIdx = selectionLeftIdx
		self:clearSelection()
	else
		preCursorText = string.sub(self.text, 0, self.cursorIdx)
		postCursorText = string.sub(self.text, self.cursorIdx + 1)
	end

	self.cursorIdx = self.cursorIdx + #text
	self:updateText(preCursorText .. text .. postCursorText)
end

--------------------  Selection  --------------------
function InputField.clearSelection(self)
	self.hasSelection = false
	self.selectionTailIdx = nil
	self.ruu:callTheme(self, self.theme, "updateSelection")
end

-- Set the "tail" character index of the selection.
-- The "head" position of the selection is the cursor index.
function InputField.startSelection(self, charIdx)
	self.hasSelection = true
	self.selectionTailIdx = charIdx
	self.ruu:callTheme(self, self.theme, "updateSelection")
end

function InputField.selectAll(self)
	self:startSelection(0)
	self.cursorIdx = #self.text
	self.ruu:callTheme(self, self.theme, "updateCursorPos")
end

function InputField.getSelectionLeftIdx(self)
	return math.min(self.cursorIdx, self.selectionTailIdx)
end

function InputField.getSelectionRightIdx(self)
	return math.max(self.cursorIdx, self.selectionTailIdx)
end

--------------------  Cursor Movement  --------------------
function InputField.setCursorIdx(self, index)
	local isSelecting = self.ruu:isSelectionModifierPressed()
	if self.hasSelection and not isSelecting then
		self:clearSelection()
	elseif not self.hasSelection and isSelecting then
		self:startSelection(self.cursorIdx)
	end
	self.cursorIdx = math.max(0, math.min(#self.text, index))
	self.ruu:callTheme(self, self.theme, "updateCursorPos")
end

function InputField.moveCursor(self, dx)
	if dx == 0 then  return  end

	local isSelecting = self.ruu:isSelectionModifierPressed()

	if self.hasSelection and not isSelecting then
		if dx > 0 then
			local selectionRightIdx = math.max(self.cursorIdx, self.selectionTailIdx)
			self.cursorIdx = selectionRightIdx
		elseif dx < 0 then
			local selectionLeftIdx = math.min(self.cursorIdx, self.selectionTailIdx)
			self.cursorIdx = selectionLeftIdx
		end
		self:clearSelection()
		self.ruu:callTheme(self, self.theme, "updateCursorPos")
		return -- Skip normal cursor movement.
	elseif not self.hasSelection and isSelecting then
		self:startSelection(self.cursorIdx)
	end

	if dx > 0 then
		self.cursorIdx = math.min(#self.text, self.cursorIdx + dx)
	elseif dx < 0 then
		self.cursorIdx = math.max(0, self.cursorIdx + dx)
	end
	self.ruu:callTheme(self, self.theme, "updateCursorPos")
end

--------------------  Ruu Input Methods  --------------------
function InputField.getFocusNeighbor(self, depth, dir)
	if depth > 1 then  return  end
	if dir == "left" then
		self:moveCursor(-1)
		return true
	elseif dir == "right" then
		self:moveCursor(1)
		return true
	else
		return self.neighbor[dir]
	end
end

function InputField.setText(self, text)
	text = text ~= nil and tostring(text) or ""
	self.cursorIdx = #text
	self:updateText(text)
end

function InputField.textInput(self, depth, text)
	if depth > 1 then  return  end
	self:insertText(text)
	return true
end

function InputField.cancel(self, depth)
	if depth > 1 then  return  end
	self.text = self.oldText
	self:selectAll()
	self.ruu:callTheme(self, self.theme, "updateText")
	return true
end

function InputField.backspace(self, depth)
	if depth > 1 then  return  end
	if self.hasSelection then
		self:insertText("")
	else
		local preCursorText = string.sub(self.text, 0, self.cursorIdx - 1) -- Skip back over 1 character.
		local postCursorText = string.sub(self.text, self.cursorIdx + 1)
		self.cursorIdx = math.max(0, self.cursorIdx - 1)
		self:updateText(preCursorText .. postCursorText)
	end
	return true
end

function InputField.delete(self, depth)
	if depth > 1 then  return  end
	if self.hasSelection then
		self:insertText("")
	else
		local preCursorText = string.sub(self.text, 0, self.cursorIdx)
		local postCursorText = string.sub(self.text, self.cursorIdx + 2) -- Skip forward over 1 character.
		-- Deleting in front of the cursor, so cursor index stays the same.
		self:updateText(preCursorText .. postCursorText)
	end
	return true
end

function InputField.home(self, depth)
	if depth > 1 then  return  end
	self:setCursorIdx(0)
	return true
end

InputField["end"] = function(self, depth)
	if depth > 1 then  return  end
	self:setCursorIdx(#self.text)
	return true
end

return InputField
