
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

	if self.dragWidget then
		didHit = true
		if self.dragWidget.drag then
			self.dragWidget:drag(dx, dy)
		end
		-- TODO: May still want to hit-check other widgets while dragging?
		--       Just for drag-and-drop?
	else
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
	end

	return didHit
end

local function getTopWidget(widgetList)
	local topIndex, topWidget = -1, nil
	for widget,_ in pairs(widgetList) do
		if widget.drawIndex > topIndex then
			topIndex = widget.drawIndex
			topWidget = widget
		end
	end
	return topWidget
end

local function input(self, name, subName, change)
	if name == "click" then
		if change == 1 then
			-- Press and focus the topmost hovered node.
			local topWidget = getTopWidget(self.hoveredWidgets)
			if topWidget then
				topWidget:press()
				setFocus(self, topWidget)
				if topWidget.isDraggable then
					self.dragWidget = topWidget
				end
			end
		elseif change == -1 then
			-- TODO: Separate keyboard pressed and mouse pressed widgets?
			--       Only release mouse pressed widget?
			--       Allow mouse to release keyboard pressed widget?

			-- Release hovered widgets if they are pressed
			self.dragWidget = nil
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
	radioButton = require(basePath .. "RadioButton"),
	sliderBar = require(basePath .. "SliderBar"),
	sliderHandle = require(basePath .. "SliderHandle"),
}

local function setWidgetEnabled(self, widget, enabled)
	-- TODO: Deal with things if a focused/hovered/pressed widget is disabled.
	self.enabledWidgets[widget] = enabled or nil
	widget.isEnabled = enabled
end

local function makeWidget(self, widgetType, obj, isEnabled, themeType, theme)
	assert(obj, "Ruu - make " .. widgetType .. " passed a nil object.")
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

local function makeButton(self, obj, isEnabled, releaseFunc, themeType, theme)
	makeWidget(self, "button", obj, isEnabled, themeType, theme)
	obj.releaseFunc = releaseFunc -- User functions.
	obj.theme[obj.themeType].init(obj)
end

local function makeToggleButton(self, obj, isEnabled, isChecked, releaseFunc, themeType, theme)
	makeWidget(self, "toggleButton", obj, isEnabled, themeType, theme)
	obj.releaseFunc = releaseFunc
	obj.isChecked = isChecked
	obj.theme[obj.themeType].init(obj)
end

local function makeRadioButtonGroup(self, objects, isEnabled, checkedObj, releaseFunc, themeType, theme)
	for i,obj in ipairs(objects) do
		makeWidget(self, "radioButton", obj, isEnabled, themeType, theme)
		obj.releaseFunc = releaseFunc
		if obj == checkedObj then  obj.isChecked = true  end
		obj.siblings = {}
		for i,sibling in ipairs(objects) do
			if sibling ~= obj then  table.insert(obj.siblings, sibling)  end
		end
		obj.theme[obj.themeType].init(obj)
	end
end

local function makeSlider(self, barObj, handleObj, isEnabled, releaseFunc, dragFunc, fraction, length, offset, nudgeDist, barClickDist, themeType, theme)
	fraction = fraction or 0
	offset = offset or 0
	length = length or 100
	nudgeDist = nudgeDist or self.defaultSliderNudgeDist
	barClickDist = barClickDist or self.defaultSliderBarClickDist

	makeWidget(self, "sliderHandle", handleObj, isEnabled, themeType, theme)
	makeWidget(self, "sliderBar", barObj, isEnabled, themeType, theme)
	barObj.handle, handleObj.bar = handleObj, barObj

	handleObj.fraction = fraction
	handleObj.isDraggable = true
	handleObj.fraction = fraction
	handleObj.offset, handleObj.length = offset, length
	handleObj.nudgeDist, handleObj.barClickDist = nudgeDist, barClickDist
	handleObj:updatePos()
	handleObj.releaseFunc, handleObj.dragFunc = releaseFunc, dragFunc

	handleObj.theme[handleObj.themeType].init(handleObj)
	barObj.theme[barObj.themeType].init(barObj)
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
		pressedWidget = nil,
		dragWidget = nil,
		theme = baseTheme or defaultTheme,
		mouseMoved = mouseMoved,
		input = input,
		setFocus = setFocus,

		makeButton = makeButton,
		makeToggleButton = makeToggleButton,
		makeRadioButtonGroup = makeRadioButtonGroup,
		makeSlider = makeSlider,

		mapNeighbors = mapNeighbors,

		defaultSliderNudgeDist = 5,
		defaultSliderBarClickDist = 25
	}
	return self
end

return new
