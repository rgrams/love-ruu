
local _basePath = (...):gsub("defaultThemes$", "")
local Class = require(_basePath .. "base-class")

local M = {}

local essentials = {}
M.essentials = essentials

local PanelWgt = require(_basePath .. "widgets.Panel")

-- Wrapper for all calls from Widget --> Theme.
-- Will be set on Ruu instance as `ruu.callTheme`.
-- So you can customize how the theme gets events, what arguments are used, etc.
function essentials.call(ruu, wgt, theme, fnName, ...)
	local fn = theme[fnName]
	return fn(wgt, ...)
end

function essentials.hitsPoint(widget, x, y)
	if widget.object:hitCheck(x, y) then
		local mask = widget.object.maskNode
		if mask then
			return mask:hitCheck(x, y)
		else
			return true
		end
	end
end

function essentials.getAncestorPanels(wgt, outputList)
	local ruu = wgt.ruu
	local parentObj = wgt.themeData.parent -- Don't include self: we just want ancestors.
	local treeRoot = parentObj.tree
	while parentObj ~= treeRoot do
		if not parentObj then  break  end
		wgt = parentObj.widget
		if wgt and ruu:hasWidget(wgt) and wgt:is(PanelWgt) then -- Widget can belong to a different Ruu instance.
			outputList = outputList or {}
			table.insert(outputList, wgt)
		end
		parentObj = parentObj.parent
	end
	return outputList
end

--##############################  BUTTON  ##############################
local Button = Class:extend()
M.Button = Button

local function setValue(self, val)
	local c = self.object.color
	c[1], c[2], c[3] = val, val, val
end

function Button.init(self, themeData)
	self.object = themeData
	themeData.widget = self
	setValue(self, 0.55)
end

function Button.hover(self)
	setValue(self, 0.7)
end

function Button.unhover(self)
	setValue(self, 0.55)
end

function Button.focus(self)
	self.object.sy = 1.2
end

function Button.unfocus(self)
	self.object.sy = 1
end

function Button.press(self, mx, my, isKeyboard)
	setValue(self, 1)
end

function Button.release(self, dontFire, mx, my, isKeyboard)
	setValue(self, self.isHovered and 0.7 or 0.55)
end

--##############################  TOGGLE-BUTTON  ##############################
local ToggleButton = Button:extend()
M.ToggleButton = ToggleButton

function ToggleButton.init(self, themeData)
	ToggleButton.super.init(self, themeData)
	self.object.angle = self.isChecked and math.pi/6 or 0
end

function ToggleButton.release(self, dontFire, mx, my, isKeyboard)
	ToggleButton.super.release(self)
	self.object.angle = self.isChecked and math.pi/6 or 0
end

function ToggleButton.setChecked(self, isChecked)
	self.object.angle = self.isChecked and math.pi/6 or 0
end

--##############################  RADIO-BUTTON  ##############################
local RadioButton = ToggleButton:extend()
M.RadioButton = RadioButton

--##############################  INPUT-FIELD  ##############################
local InputField = Button:extend()
M.InputField = InputField

function InputField.init(self, themeData)
	self.object = themeData
	themeData.widget = self
	self.textObj = self.object.text
	self.cursorObj = self.object.cursor
	self.selectionObj = self.object.selection

	setValue(self, 0.3)

	if self.object.tree then
		self.cursorObj:setVisible(self.isFocused)
		self.selectionObj:setVisible(self.isFocused)
	else
		self.cursorObj.visible = self.isFocused
		self.selectionObj.visible = self.isFocused
	end

	self.font = self.textObj.font
	self.scrollOX = 0
	self.textOriginX = self.textObj.pos.x

	self.theme.updateMaskSize(self)
	self.theme.updateText(self)
end

function InputField.hover(self)
	setValue(self, 0.4)
end

function InputField.unhover(self)
	setValue(self, 0.3)
end

function InputField.press(self)
	setValue(self, 0.9)
end

function InputField.release(self)
	setValue(self, self.isHovered and 0.4 or 0.3)
end

function InputField.focus(self, isKeyboard)
	InputField.super.focus(self, isKeyboard)
	self.cursorObj:setVisible(true)
	self.selectionObj:setVisible(self.hasSelection)
end

function InputField.unfocus(self, isKeyboard)
	InputField.super.unfocus(self, isKeyboard)
	self.cursorObj:setVisible(false)
	self.selectionObj:setVisible(false)
	self.theme.scrollCharOffsetIntoView(self, 0)
end

function InputField.updateSelection(self)
	if self.selectionTailIdx then
		self.theme.updateSelectionXPos(self) -- Only need to update X pos now, and when scroll actually changes.
	else
		self.selectionTailX = nil
	end
end

function InputField.updateSelectionXPos(self)
	if self.hasSelection then
		self.selectionTailX = self.theme.getCharXOffset(self, self.selectionTailIdx) + self.scrollOX
	end
end

-- Called from widget whenever text is changed.
function InputField.updateText(self)
	self.textObj.text = self.text
	self.theme.updateTotalTextWidth(self)
	if self.isFocused then
		self.theme.updateCursorPos(self)
	end
end

function InputField.textRejected(self, rejectedText)
end

-- Save left and right edge positions of the text-mask, relative to the parent.
-- Only called once, on init.
-- TODO: Needs to be called again if the InputField changes size.
function InputField.updateMaskSize(self)
	local maskObj = self.object.mask
	local pivotX = maskObj.px / 2
	local width = maskObj._contentRect.w
	local originX = 0
	local centerX = originX - pivotX * width

	self.maskWidth = width
	self.maskLeftEdgeX, self.maskRightEdgeX = centerX - width/2, centerX + width/2
end

function InputField.updateTotalTextWidth(self)
	self.totalTextWidth = self.font:getWidth(self.text)
end

function InputField.setScrollOffset(self, scrollOX)
	-- if true then  return  end

	local oldScrollOX = self.scrollOX
	local normalViewWidth = self.maskRightEdgeX - self.maskLeftEdgeX
	if self.totalTextWidth <= normalViewWidth then
		scrollOX = 0
	else -- Don't let the right edge of the text be inside the right edge of the mask.
		local maxNegScroll = self.totalTextWidth - normalViewWidth
		scrollOX = math.max(-maxNegScroll, scrollOX)
	end

	if scrollOX ~= oldScrollOX then
		self.scrollOX = scrollOX
		self.textObj:setPos(self.textOriginX + self.scrollOX)

		self.theme.updateSelectionXPos(self)
	end
end

function InputField.scrollCharOffsetIntoView(self, x)
	local scrolledX = x + self.scrollOX
	if scrolledX > self.maskRightEdgeX then -- Scroll text to the left.
		local distOutside = scrolledX - self.maskRightEdgeX
		self.theme.setScrollOffset(self, self.scrollOX - distOutside)
	elseif scrolledX < self.maskLeftEdgeX then -- Scroll text to the right.
		local distOutside = self.maskLeftEdgeX - scrolledX
		self.theme.setScrollOffset(self, self.scrollOX + distOutside)
	else
		self.theme.setScrollOffset(self, self.scrollOX)
	end
end

-- Gets the un-scrolled X pos of the -right edge- of the character at `charIdx`.
function InputField.getCharXOffset(self, charIdx)
	local preText = self.text:sub(0, charIdx)
	return self.textOriginX + self.font:getWidth(preText)
end

-- Called from widget.
function InputField.updateCursorPos(self)
	local baseCursorX = self.theme.getCharXOffset(self, self.cursorIdx)
	self.theme.scrollCharOffsetIntoView(self, baseCursorX)
	self.cursorX = baseCursorX + self.scrollOX

	self.cursorObj:setPos(self.cursorX - self.maskWidth/2)
	if self.selectionTailX then
		self.selectionObj:setVisible(true)
		local selectionX = self.cursorX
		local selectionWidth = self.selectionTailX - self.cursorX -- Width can be negative, it works fine.
		self.selectionObj:setPos(self.maskLeftEdgeX + selectionX)
		self.selectionObj:size(selectionWidth)
	else
		self.selectionObj:setVisible(false)
	end
end

--##############################  SLIDER - HANDLE  ##############################
local Slider = Button:extend()
M.Slider = Slider

function Slider.init(self, themeData)
	Slider.super.init(self, themeData)
	self.theme.drag(self)
end

function Slider.drag(self)
	-- self.angle = self.fraction * math.pi
	self.object.kx = self.fraction - 0.5
end

--[[
--##############################  SLIDER - BAR  ##############################
local SliderBar = Button:extend()
M.SliderBar = SliderBar

function SliderBar.hover(self)  end
function SliderBar.unhover(self)  end

function SliderBar.focus(self)  end
function SliderBar.unfocus(self)  end

function SliderBar.press(self)
	setValue(self, 1)
end

function SliderBar.release(self)
	setValue(self, 0.55)
end

--##############################  SCROLL-AREA  ##############################
local ScrollArea = Button:extend()
M.ScrollArea = ScrollArea

function ScrollArea.init(self)  end
function ScrollArea.hover(self)  end
function ScrollArea.unhover(self)  end
function ScrollArea.focus(self)  end
function ScrollArea.unfocus(self)  end
function ScrollArea.press(self)  end
function ScrollArea.release(self)  end
--]]

--##############################  PANEL  ##############################
local Panel = Class:extend()
M.Panel = Panel

function Panel.init(self, themeData)
	self.object = themeData
	themeData.widget = self
end
function Panel.hover(self)  end
function Panel.unhover(self)  end
function Panel.focus(self)  end
function Panel.unfocus(self)  end
function Panel.press(self)  end
function Panel.release(self)  end

return M
