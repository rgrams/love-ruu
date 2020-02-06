
local basePath = (...):gsub('[^%.]+$', '')
local Class = require(basePath .. "base-class")

local M = {}

--##############################  BUTTON  ##############################
local button = Class:extend()
M.button = button

local function setValue(self, val)
	local c = self.color
	c[1], c[2], c[3] = val, val, val
end

function button.init(self)
	setValue(self, 0.55)
end

function button.hover(self)
	setValue(self, 0.7)
end

function button.unhover(self)
	setValue(self, 0.55)
end

function button.focus(self)
	self.sy = 1.2
end

function button.unfocus(self)
	self.sy = 1
end

function button.press(self)
	setValue(self, 1)
end

function button.release(self)
	setValue(self, self.isHovered and 0.7 or 0.55)
end

--##############################  TOGGLE-BUTTON  ##############################
local toggleButton = button:extend()
M.toggleButton = toggleButton

function toggleButton.init(self)
	toggleButton.super.init(self)
	self.angle = self.isChecked and math.pi/4 or 0
end

function toggleButton.release(self)
	toggleButton.super.release(self)
	self.angle = self.isChecked and math.pi/4 or 0
end

--##############################  TOGGLE-BUTTON  ##############################
local radioButton = toggleButton:extend()
M.radioButton = radioButton

function radioButton.uncheck(self)
	self.angle = 0
end

return M
