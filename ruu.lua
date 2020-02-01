
local basePath = (...):gsub('[^%.]+$', '')
local defaultTheme = require(basePath .. "defaultTheme")

local function setFocus(self, widget)
	if widget == self.focusedWidget then  return  end
	if self.focusedWidget then
		self.focusedWidget:unfocus()
	end
	self.focusedWidget = widget
	widget:focus()
end

local function mouseMoved(self, x, y, dx, dy)
	local didHit = false

	for widget,_ in pairs(self.enabledWidgets) do
		if widget:hitCheck(x, y) then
			didHit = true
			if not widget.isHovered then
				self.hoveredWidgets[widget] = true
				widget:hover()
			end
		elseif widget.isHovered then
			self.hoveredWidgets[widget] = nil
			widget:unhover()
		end
	end

	return didHit
end

local function input(self, name, subName, change)
	if name == "click" then
		if change == 1 then
			local first = true
			-- Press all hovered nodes.
			for widget,_ in pairs(self.hoveredWidgets) do
				widget:press()
				if first then
					first = false
					-- Focus on first widget.
					setFocus(self, widget)
				end
			end
		elseif change == -1 then
			-- release hovered widgets if they are pressed
			for widget,_ in pairs(self.hoveredWidgets) do
				if widget.isPressed then
					widget:release()
				end
			end
		end
	elseif name == "enter" then
		if change == 1 then
			if self.focusedWidget then
				self.focusedWidget:press()
			end
		elseif change == -1 then
			if self.focusedWidget then
				if self.focusedWidget.isPressed then
					self.focusedWidget:release()
				end
			end
		end
	elseif name == "direction" and change == 1 then
		local widget = self.focusedWidget
		if widget then
			local neighbor = widget.neighbor[subName]
			if neighbor then
				setFocus(self, neighbor)
			end
		end
	end
end

local baseFunctions = {
	button = require(basePath .. "Button"),
	toggleButton = require(basePath .. "ToggleButton"),
	radioButton = require(basePath .. "RadioButton")
}

local function setWidgetEnabled(self, widget, enabled)
	self.enabledWidgets[widget] = enabled or nil
	widget.isEnabled = enabled
end

local function makeWidget(self, widgetType, obj, isEnabled, themeType, theme)
	-- UI Widget Lists
	self.allWidgets[obj] = true
	if isEnabled then
		self.enabledWidgets[obj] = true
		obj.isEnabled = true
	end
	-- Theme
	obj.themeType, obj.theme = themeType or widgetType, theme or self.theme
	-- Widget Base Functions - hover, unhover, press, release, etc.
	obj.widgetType = widgetType
	for k,v in pairs(baseFunctions[widgetType]) do
		obj[k] = v
	end
	-- Neighbors
	obj.neighbor = {}
	-- State
	obj.isHovered, obj.isFocused, obj.isPressed = false, false, false
end

local function makeButton(self, obj, isEnabled, releaseFunc, pressFunc, themeType, theme)
	makeWidget(self, "button", obj, isEnabled, themeType, theme)
	obj.pressFunc, obj.releaseFunc = pressFunc, releaseFunc -- User functions.
	obj.theme[obj.themeType].init(obj)
end

local function makeToggleButton(self, obj, isEnabled, isChecked, releaseFunc, pressFunc, themeType, theme)
	makeWidget(self, "toggleButton", obj, isEnabled, themeType, theme)
	obj.pressFunc, obj.releaseFunc = pressFunc, releaseFunc
	obj.isChecked = isChecked
	obj.theme[obj.themeType].init(obj)
end

local function makeRadioButtonGroup(self, objects, isEnabled, checkedObj, releaseFunc, pressFunc, themeType, theme)
	for i,obj in ipairs(objects) do
		makeWidget(self, "radioButton", obj, isEnabled, themeType, theme)
		if obj == checkedObj then  obj.isChecked = true  end
		obj.siblings = {}
		for i,sibling in ipairs(objects) do
			if sibling ~= obj then  table.insert(obj.siblings, sibling)  end
		end
		obj.theme[obj.themeType].init(obj)
	end
end

local function makeSlider(self, obj, isEnabled, fraction, releaseFunc, dragFunc, pressFunc,
		length, handleLength, autoResizeHandle, nudgeDist, themeType, theme)
	--
end

local function makeScrollArea(self, obj, isEnabled, fraction, scrollDist, nudgeDist, themeType, theme)
end

local function makeInputField(self, obj, isEnabled, editFunc, confirmFunc, placeholderText, themeType, theme)
end

local function loopIndex(list, start, by)
	return (start - 1 + by) % #list + 1
end

local function findNextInMap(self, map, x, y, axis, dir)
	local foundWidget = nil
	while not foundWidget do
		if axis == "y" then
			y = loopIndex(map, y, dir)
		elseif axis == "x" then
			x = loopIndex(map[y], x, dir)
		end
		foundWidget = map[y][x]
		if foundWidget == self then  break  end
	end
	return foundWidget ~= self and foundWidget or nil
end

--[[
-- EMPTY CELLS MUST BE `FALSE`.
local map_horizontal = {
	[1] = { 1, 2, 3 }
}
local map_vertical = {
	[1] = { 1 },
	[2] = { 2 },
	[3] = { 3 }
}
local map_square = {
	[1] = { 1, 2, 3 },
	[2] = { 1, 2, 3 },
	[3] = { 1, 2, 3 }
}
]]

local function mapNeighbors(self, map)
	for y,row in ipairs(map) do
		for x,widget in ipairs(row) do
			if widget then -- Skip empty cells.
				-- Up and Down
				if #map > 1 then
					widget.neighbor.up = findNextInMap(widget, map, x, y, "y", -1)
					widget.neighbor.down = findNextInMap(widget, map, x, y, "y", 1)
				end
				-- Left and Right
				if #row > 1 then
					widget.neighbor.left = findNextInMap(widget, map, x, y, "x", -1)
					widget.neighbor.right = findNextInMap(widget, map, x, y, "x", 1)
				end
			end
		end
	end
end

local function new(baseTheme)
	local self = {
		allWidgets = {},
		enabledWidgets = {},
		hoveredWidgets = {},
		focusedWidget = nil,
		theme = baseTheme or defaultTheme,
		isDragging = false,
		mouseMoved = mouseMoved,
		input = input,
		setFocus = setFocus,

		makeButton = makeButton,
		makeToggleButton = makeToggleButton,
		makeRadioButtonGroup = makeRadioButtonGroup,

		mapNeighbors = mapNeighbors
	}
	return self
end

return new
