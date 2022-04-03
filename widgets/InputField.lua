
local _basePath = (...):gsub("InputField$", "")
local Button = require(_basePath .. "Button")

local InputField = Button:extend()
InputField.className = "InputField"

function InputField.set(self, ruu, themeData, confirmFn, text, wgtTheme)
	self.text = text and tostring(text) or ""
	self.confirmFn = confirmFn
	self.cursorIdx = #self.text
	InputField.super.set(self, ruu, themeData, nil, wgtTheme)
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
		self:cancel()
		self.wgtTheme.textRejected(self, rejectedText)
	else
		self.oldText = self.text -- Save text for next time.
	end
end

function InputField.release(self, dontFire, mx, my, isKeyboard)
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
	self.wgtTheme.release(self, dontFire, mx, my, isKeyboard)
end

function InputField.focus(self, isKeyboard)
	if not self.isFocused then
		self.isFocused = true
		self.oldText = self.text -- Save in case of cancel.
		self:selectAll()
	end
	self.wgtTheme.focus(self)
end

function InputField.unfocus(self, isKeyboard)
	self.isFocused = false
	if self.isPressed then  self:release(true)  end -- Release without firing.
	if self.confirmFn then
		self:confirmText()
	end
	self.wgtTheme.unfocus(self, isKeyboard)
end

--------------------  Internal Text Setting  --------------------
function InputField.updateText(self, text)
	self.text = text
	fireCallback(self, self.editFn) -- EditFn can modify self.text.
	self.wgtTheme.updateText(self)
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
	self.wgtTheme.updateSelection(self)
end

-- Set the "tail" character index of the selection.
-- The "head" position of the selection is the cursor index.
function InputField.startSelection(self, charIdx)
	self.hasSelection = true
	self.selectionTailIdx = charIdx
	self.wgtTheme.updateSelection(self)
end

function InputField.selectAll(self)
	self:startSelection(0)
	self.cursorIdx = #self.text
	self.wgtTheme.updateCursorPos(self)
end

function InputField.getSelectionLeftIdx(self)
	return math.min(self.cursorIdx, self.selectionTailIdx)
end

function InputField.getSelectionRightIdx(self)
	return math.max(self.cursorIdx, self.selectionTailIdx)
end

--------------------  Cursor Movement  --------------------
function InputField.setCursorIdx(self, index)
	if self.hasSelection and self.ruu.selectionModifierPresses == 0 then
		self:clearSelection()
	elseif not self.hasSelection and self.ruu.selectionModifierPresses > 0 then
		self:startSelection(self.cursorIdx)
	end
	self.cursorIdx = math.max(0, math.min(#self.text, index))
	self.wgtTheme.updateCursorPos(self)
end

function InputField.moveCursor(self, dx)
	if dx == 0 then  return  end

	if self.hasSelection and self.ruu.selectionModifierPresses == 0 then
		if dx > 0 then
			local selectionRightIdx = math.max(self.cursorIdx, self.selectionTailIdx)
			self.cursorIdx = selectionRightIdx
		elseif dx < 0 then
			local selectionLeftIdx = math.min(self.cursorIdx, self.selectionTailIdx)
			self.cursorIdx = selectionLeftIdx
		end
		self:clearSelection()
		self.wgtTheme.updateCursorPos(self)
		return -- Skip normal cursor movement.
	elseif not self.hasSelection and self.ruu.selectionModifierPresses > 0 then
		self:startSelection(self.cursorIdx)
	end

	if dx > 0 then
		self.cursorIdx = math.min(#self.text, self.cursorIdx + dx)
	elseif dx < 0 then
		self.cursorIdx = math.max(0, self.cursorIdx + dx)
	end
	self.wgtTheme.updateCursorPos(self)
end

--------------------  Ruu Input Methods  --------------------
function InputField.getFocusNeighbor(self, dir)
	if dir == "left" then
		self:moveCursor(-1)
	elseif dir == "right" then
		self:moveCursor(1)
	else
		return self.neighbor[dir]
	end
end

function InputField.setText(self, text)
	text = text ~= nil and tostring(text) or ""
	self.cursorIdx = #text
	self:updateText(text)
end

function InputField.textInput(self, text)
	self:insertText(text)
end

function InputField.cancel(self)
	self.text = self.oldText
	self:selectAll()
	self.wgtTheme.updateText(self)
end

function InputField.backspace(self)
	if self.hasSelection then
		self:insertText("")
	else
		local preCursorText = string.sub(self.text, 0, self.cursorIdx - 1) -- Skip back over 1 character.
		local postCursorText = string.sub(self.text, self.cursorIdx + 1)
		self.cursorIdx = math.max(0, self.cursorIdx - 1)
		self:updateText(preCursorText .. postCursorText)
	end
end

function InputField.delete(self)
	if self.hasSelection then
		self:insertText("")
	else
		local preCursorText = string.sub(self.text, 0, self.cursorIdx)
		local postCursorText = string.sub(self.text, self.cursorIdx + 2) -- Skip forward over 1 character.
		-- Deleting in front of the cursor, so cursor index stays the same.
		self:updateText(preCursorText .. postCursorText)
	end
end

function InputField.home(self)
	self:setCursorIdx(0)
end

InputField["end"] = function(self)
	self:setCursorIdx(#self.text)
end

return InputField
