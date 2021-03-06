
local basePath = (...):gsub('[^%.]+$', '')
local Class = require(basePath .. "base widgets.base-class")

local M = {}

--##############################  BUTTON  ##############################
local Button = Class:extend()
M.Button = Button

local function setValue(self, val)
	local c = self.color
	c[1], c[2], c[3] = val, val, val
end

function Button.init(self)
	setValue(self, 0.55)
end

function Button.hover(self)
	setValue(self, 0.7)
end

function Button.unhover(self)
	setValue(self, 0.55)
end

function Button.focus(self)
	self.sy = 1.2
end

function Button.unfocus(self)
	self.sy = 1
end

function Button.press(self)
	setValue(self, 1)
end

function Button.release(self)
	setValue(self, self.isHovered and 0.7 or 0.55)
end

--##############################  TOGGLE-BUTTON  ##############################
local ToggleButton = Button:extend()
M.ToggleButton = ToggleButton

function ToggleButton.init(self)
	ToggleButton.super.init(self)
	self.angle = self.isChecked and math.pi/4 or 0
end

function ToggleButton.release(self)
	ToggleButton.super.release(self)
	self.angle = self.isChecked and math.pi/4 or 0
end

--##############################  RADIO-BUTTON  ##############################
local RadioButton = ToggleButton:extend()
M.RadioButton = RadioButton

function RadioButton.setChecked(self)
	self.angle = self.isChecked and math.pi/4 or 0
end

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

--##############################  SLIDER - HANDLE  ##############################
local SliderHandle = Button:extend()
M.SliderHandle = SliderHandle

function SliderHandle.init(self)
	SliderHandle.super.init(self)
	SliderHandle.drag(self)
end

function SliderHandle.drag(self)
	self.angle = self.fraction * math.pi
end

function SliderHandle.focus(self)
	self.w, self.h = self.w * 1.2, self.h * 1.2
	self:_updateInnerSize()
end

function SliderHandle.unfocus(self)
	self.w, self.h = self.w / 1.2, self.h / 1.2
	self:_updateInnerSize()
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

--##############################  INPUT-FIELD  ##############################
local InputField = Button:extend()
M.InputField = InputField

function InputField.init(self)
	InputField.super.init(self)
	self.textObj.color[4] = 0.5
end

function InputField.setText(self)
	self.textObj.color[4] = 1
end

--##############################  PANEL  ##############################
local Panel = Class:extend()
M.Panel = Panel

function Panel.init(self)  end
function Panel.hover(self)  end
function Panel.unhover(self)  end
function Panel.focus(self)  end
function Panel.unfocus(self)  end
function Panel.press(self)  end
function Panel.release(self)  end

return M
