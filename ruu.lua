
local basePath = (...):gsub('[^%.]+$', '')
local defaultTheme = require(basePath .. "defaultTheme")

local baseWidgetPath = basePath .. "base widgets."

local baseFunctions = {
	Button = require(baseWidgetPath .. "Button"),
	ToggleButton = require(baseWidgetPath .. "ToggleButton"),
	RadioButton = require(baseWidgetPath .. "RadioButton"),
	SliderBar = require(baseWidgetPath .. "SliderBar"),
	SliderHandle = require(baseWidgetPath .. "SliderHandle"),
	ScrollArea = require(baseWidgetPath .. "ScrollArea"),
	InputField = require(baseWidgetPath .. "InputField"),
	Panel = require(baseWidgetPath .. "Panel")
}

local LAYER_DEPTH_MULT = 10000

local function registerLayers(self, layers)
	local i = 1
	for li=#layers,1,-1 do
		local layerName = layers[li]
		self.layers[layerName] = i * LAYER_DEPTH_MULT
		i = i + 1
	end
end

local function getTopWidget(self, widgetList)
	local topIndex, topWidget = -1, nil
	for widget,_ in pairs(widgetList) do
		local layerIndex = widget.layer and self.layers[widget.layer] or 0
		local index = widget.drawIndex + layerIndex
		if index > topIndex then
			topIndex = index
			topWidget = widget
		end
	end
	return topWidget
end

-- Takes an object, a nonRecursive flag, and an optional ancestors table to add onto.
-- Returns:
--    A single ancestor object, if `nonRecursive` is true, or nil.
--    A sequence of ancestor objects that are Panels in child-parent order, or nil.
local function getAncestorPanels(self, obj, nonRecursive, ancestors)
	if not obj then  return  end
	local p = obj.parent -- Don't include starting object: keep current focus and ancestors separate.
	while p ~= obj.tree do
		if not p then  break  end
		if p.widgetType == "Panel" and self.allWidgets[p] then -- Widget can belong to a different Ruu instance.
			if nonRecursive then  return p  end
			ancestors = ancestors or {}
			table.insert(ancestors, p)
		end
		p = p.parent
	end
	return ancestors
end

local function setPanelsFocused(panels, focused)
	if focused then
		for i=#panels,1,-1 do
			panels[i]:focus(i)
		end
	else
		for i=#panels,1,-1 do
			panels[i]:unfocus()
			panels[i] = nil
		end
	end
end

local function setFocus(self, widget, isKeyboard)
	if widget == self.focusedWidget then  return  end
	if self.focusedWidget then
		self.focusedWidget:unfocus(isKeyboard)
	end
	self.focusedWidget = widget
	if widget then
		local firstAncestorPanel = getAncestorPanels(self, widget, true)
		if self.focusedPanels[1] ~= firstAncestorPanel then
			setPanelsFocused(self.focusedPanels, false)
			if firstAncestorPanel then -- Of course will be `nil` if there isn't one.
				self.focusedPanels[1] = firstAncestorPanel
				getAncestorPanels(self, firstAncestorPanel, false, self.focusedPanels)
				setPanelsFocused(self.focusedPanels, true)
			end
		end
		-- New widget may have been an old ancestor panel, so focused it after panels.
		widget:focus(isKeyboard)
	else
		setPanelsFocused(self.focusedPanels, false)
	end
end

local function focusAtCursor(self)
	local topWidget = getTopWidget(self, self.hoveredWidgets)
	if topWidget then
		setFocus(self, topWidget)
	end
	return topWidget
end

local function mouseMoved(self, x, y, dx, dy)
	local didHit = false
	self.mx, self.my = x, y

	if self.drags then
		didHit = true
		for i,drag in ipairs(self.drags) do
			drag.object:drag(dx, dy, drag.type)
		end
	end
	-- Still hit-check all widgets while dragging, for scroll areas and drag-and-drop.
	for widget,_ in pairs(self.enabledWidgets) do
		-- Don't need to hitCheck dragged widgets, but make sure they are hovered.
		local hitWgt = widget:hitCheck(x, y)
		if hitWgt and widget.maskObject then
			hitWgt = widget.maskObject:hitCheck(x, y)
		end
		if self.objDragCount[widget] or hitWgt then
			didHit = true
			if not widget.isHovered then
				self.hoveredWidgets[widget] = true
				widget:hover()
				-- TODO: separate callback for hover while drag-and-dropping.
			end
			if widget.mouseMovedFunc then
				widget:mouseMovedFunc(x, y, dx, dy)
			end
		else
			self.hoveredWidgets[widget] = nil
			if widget.isHovered then
				widget:unhover()
			end
		end
	end
	return didHit
end

-- Starts a drag of a certain type for a specific object.
local function startDrag(self, obj, dragType)
	if obj.isDraggable then
		local dragCount = (self.objDragCount[obj] or 0) + 1
		self.objDragCount[obj] = dragCount
		self.drags = self.drags or {}
		local drag = { object = obj, type = dragType }
		table.insert(self.drags, drag)
	end
end

-- Stop drags by some criteria: either "type" or "object".
--   (if drag[key] == `val` then  remove the drag.)
--   By default: dragType == nil (the default dragType).
local function stopDrag(self, key, val)
	key = key or "type"
	if self.drags then
		for i=#self.drags,1,-1 do
			local drag = self.drags[i]
			if drag[key] == val then
				self.drags[i] = nil
				local dragCount = self.objDragCount[drag.object] - 1
				if dragCount <= 0 then  self.objDragCount[drag.object] = nil
				else self.objDragCount[drag.object] = dragCount  end
			end
		end
		if #self.drags == 0 then  self.drags = nil  end
	end
end

-- Calls the named function on an object and its scripts, stopping on the first truthy return value.
local function consumableCall(obj, funcName, ...)
	local r
	if obj[funcName] then
		r = obj[funcName](obj, ...)
		if r then  return r  end
	end
	if obj.script then
		for i=1,#obj.script do
			local scr = obj.script[i]
			if scr[funcName] then
				r = scr[funcName](obj, ...)
				if r then  return r  end
			end
		end
	end
end

local navDirs = { up = 1, down = 1, left = 1, right = 1, next = 1, prev = 1 }

local function input(self, inputType, action, value, change, isRepeat, x, y, dx, dy)
	if action == "left click" then
		if change == 1 then
			-- Press and focus the topmost hovered node.
			local topWidget = focusAtCursor(self)
			if topWidget then
				topWidget:press(self.mx, self.my)
				startDrag(self, topWidget, nil) -- `nil` == default dragType.
			end
			return topWidget
		elseif change == -1 then
			-- TODO: Separate keyboard pressed and mouse pressed widgets?
			--       Only release mouse pressed widget?
			--       Allow mouse to release keyboard pressed widget?

			stopDrag(self) -- Stop default drags.
			-- Release hovered widgets if they are pressed
			for widget,_ in pairs(self.hoveredWidgets) do
				if widget.isPressed then
					widget:release(false, self.mx, self.my)
				end
			end
			if next(self.hoveredWidgets) then
				return true
			end
		end
	elseif action == "enter" then
		if change == 1 then
			if self.focusedWidget then
				self.focusedWidget:press(nil, nil, true)
				return true
			end
		elseif change == -1 then
			if self.focusedWidget then
				if self.focusedWidget.isPressed then
					self.focusedWidget:release(nil, nil, nil, true)
				end
				return true
			end
		end
	elseif navDirs[action] and value == 1 then
		local widget = self.focusedWidget
		if widget then
			local neighbor = widget:getFocusNeighbor(action)
			if neighbor == 1 then -- No neighbor, but used input.
				return true
			elseif neighbor then
				setFocus(self, neighbor, true)
				return true
			end
		end
	elseif action == "scrollx" then
		local didScroll = false
		for widget,_ in pairs(self.hoveredWidgets) do
			if widget.scroll then
				widget:scroll(dx, dy)
				didScroll = true
			end
		end
		return didScroll
	elseif action == "scrolly" then
		local didScroll = false
		for widget,_ in pairs(self.hoveredWidgets) do
			if widget.scroll then
				widget:scroll(dx, dy)
				didScroll = true
			end
		end
		return didScroll
	elseif action == "text" then
		local widget = self.focusedWidget
		if widget and widget.textInput then
			widget:textInput(value)
			return true
		end
	elseif action == "backspace" and value == 1 then
		local widget = self.focusedWidget
		if widget and widget.backspace then
			widget:backspace()
			return true
		end
	elseif action == "delete" and value == 1 then
		local widget = self.focusedWidget
		if widget and widget.delete then
			widget:delete()
			return true
		end
	end

	-- For any unused input:
	-- Call a separate function name than normal input so we can't get infinite loops.
	local r
	if inputType == "focus" then
		if self.focusedWidget then
			r = consumableCall(self.focusedWidget, "ruuinput", action, value, change, isRepeat)
			if r then  return r  end
		end
		for i,panel in ipairs(self.focusedPanels) do
			r = consumableCall(panel, "ruuinput", action, value, change, isRepeat)
			if r then  return r  end
		end
	elseif inputType == "hover" then
		for widget,_ in pairs(self.hoveredWidgets) do
			r = consumableCall(widget, "ruuinput", action, value, change, isRepeat)
			if r then  return r  end
		end
	end
end

local function setWidgetEnabled(self, widget, enabled)
	self.enabledWidgets[widget] = enabled or nil
	widget.isEnabled = enabled

	if not enabled then
		self.hoveredWidgets[widget] = nil
		if self.objDragCount[widget] then  stopDrag(self, "object", widget)  end
		if self.focusedWidget == widget then
			widget:unfocus()
			self.focusedWidget = nil -- Just remove it, don't change ancestor panel focus.
		end
		if widget.isHovered then  widget:unhover()  end
		if widget.isPressed then  widget:release(true)  end
	end
end

local destroyRadioButton

local function destroyWidget(self, widget)
	setWidgetEnabled(self, widget, false)
	self.allWidgets[widget] = nil
	if widget.widgetType == "RadioButton" then
		destroyRadioButton(self, widget)
	end
end

local function makeWidget(self, widgetType, obj, isEnabled, themeType, theme)
	assert(obj, "Ruu - make " .. widgetType .. " passed a nil object.")
	obj.ruu = self
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
	makeWidget(self, "Button", obj, isEnabled, themeType, theme)
	obj.releaseFunc = releaseFunc -- User functions.
	obj.theme[obj.themeType].init(obj)
end

local function makeToggleButton(self, obj, isEnabled, isChecked, releaseFunc, themeType, theme)
	makeWidget(self, "ToggleButton", obj, isEnabled, themeType, theme)
	obj.releaseFunc = releaseFunc
	obj.isChecked = isChecked
	obj.theme[obj.themeType].init(obj)
end

-- Local var initialized above `destroyWidget`.
-- Destroy a single RadioButton.
function destroyRadioButton(self, obj)
	if obj.isChecked then
		local _,sibToCheck = next(obj.siblings)
		if sibToCheck then
			sibToCheck.isChecked = true
			sibToCheck.theme[sibToCheck.themeType].setChecked(sibToCheck)
		end
	end
	for i,sib in ipairs(obj.siblings) do
		local siblings = sib.siblings
		for i,sibObj in ipairs(siblings) do
			if sibObj == obj then
				table.remove(siblings, i)
				break
			end
		end
	end
	if self.allWidgets[obj] then
		obj.widgetType = nil -- So destroyWidget doesn't call this function again in an infinite loop.
		destroyWidget(self, obj)
	end
end

-- Makes a single RadioButton and adds it to an existing RadioButtonGroup.
local function makeRadioButton(self, obj, sibling, isEnabled, isChecked, releaseFunc, themeType, theme)
	assert(obj ~= sibling, "Ruu.makeRadioButton - Can't use the new object as the existing sibling. "..tostring(sibling))
	makeWidget(self, "RadioButton", obj, isEnabled, themeType, theme)
	obj.releaseFunc = releaseFunc
	obj.isChecked = isChecked
	obj.siblings = { sibling }
	local siblings = sibling.siblings
	for i,sib in ipairs(siblings) do
		table.insert(sib.siblings, obj) -- Add new obj to all siblings' lists.
		table.insert(obj.siblings, sib) -- Add each sibling to new obj's list.
	end
	table.insert(sibling.siblings, obj) -- Sibling won't have itself in its list, so it won't be in the iteration.
	if obj.isChecked then
		for i,sib in ipairs(obj.siblings) do
			sib.isChecked = false
			sib.theme[sib.themeType].setChecked(sib)
		end
	end
	obj.theme[obj.themeType].init(obj)
end

local function makeRadioButtonGroup(self, objects, isEnabled, checkedObj, releaseFunc, themeType, theme)
	for i,obj in ipairs(objects) do
		makeWidget(self, "RadioButton", obj, isEnabled, themeType, theme)
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

	makeWidget(self, "SliderHandle", handleObj, isEnabled, themeType, theme)
	makeWidget(self, "SliderBar", barObj, isEnabled, themeType, theme)
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

local function makeScrollArea(self, obj, isEnabled, ox, oy, scrollDist, nudgeDist, themeType, theme)
	assert(
		obj.enableMask and obj.disableMask and obj.setOffset,
		"Ruu.makeScrollArea - object: '" .. tostring(obj) .. "' is not a Mask."
	)
	ox, oy = ox or 0, oy or 0
	scrollDist = scrollDist or self.defaultScrollAreaScrollDist
	nudgeDist = nudgeDist or self.defaultScrollAreaNudgeDist

	makeWidget(self, "ScrollArea", obj, isEnabled, themeType, theme)
	obj.scrollX, obj.scrollY = 0, 0
	obj.scrollDist, obj.nudgeDist = scrollDist, nudgeDist
	obj.childBounds = { lt=0, rt=0, top=0, bot=0, w=0, h=0 }
	obj:scroll(ox, oy)

	obj.theme[obj.themeType].init(obj)
end

local function makeInputField(self, obj, textObj, maskObj, isEnabled, editFunc, confirmFunc, scrollToRight, themeType, theme)
	makeWidget(self, "InputField", obj, isEnabled, themeType, theme)
	obj.label = textObj
	obj.mask = maskObj
	obj.scrollX, obj.scrollToRight = 0, scrollToRight
	obj.placeholderText = placeholderText
	obj.editFunc, obj.confirmFunc = editFunc, confirmFunc
	obj.text = textObj.text
	obj.cursorI, obj.cursorX = 0, 0
	obj.selection = {}
	obj.isDraggable = true
	obj:setCursorPos()
	obj.theme[obj.themeType].init(obj)
end

local function makePanel(self, obj, isEnabled, themeType, theme)
	makeWidget(self, "Panel", obj, isEnabled, themeType, theme)
	obj.theme[obj.themeType].init(obj)
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

local function mapNextPrev(self, map)
	if #map <= 1 then  return  end

	map = { map } -- Make into a 2D array.

	for i,widget in ipairs(map[1]) do
		if widget then
			widget.neighbor.next = findNextInMap(widget, map, i, 1, "x", 1)
			widget.neighbor.prev = findNextInMap(widget, map, i, 1, "x", -1)
		end
	end
end

local function new(getInput, baseTheme)
	assert(type(getInput) == "function", "Ruu() - Requires a function for getting current input values.")
	local self = {
		allWidgets = {},
		enabledWidgets = {},
		hoveredWidgets = {},
		focusedWidget = nil,
		focusedPanels = {},
		drags = nil,
		objDragCount = {},
		startDrag = startDrag,
		stopDrag = stopDrag,
		theme = baseTheme or defaultTheme,
		mouseMoved = mouseMoved,
		mx = 0, my = 0,
		input = input,
		getInput = getInput,
		registerLayers = registerLayers,
		layers = {},
		setFocus = setFocus,
		focusAtCursor = focusAtCursor,

		setWidgetEnabled = setWidgetEnabled,
		destroyWidget = destroyWidget,

		makeButton = makeButton,
		makeToggleButton = makeToggleButton,

		destroyRadioButton = destroyRadioButton,
		makeRadioButton = makeRadioButton,
		makeRadioButtonGroup = makeRadioButtonGroup,

		makeSlider = makeSlider,
		makeScrollArea = makeScrollArea,
		makeInputField = makeInputField,
		makePanel = makePanel,

		mapNeighbors = mapNeighbors,
		mapNextPrev = mapNextPrev,

		defaultSliderNudgeDist = 5,
		defaultSliderBarClickDist = 25,
		defaultScrollAreaScrollDist = 20,
		defaultScrollAreaNudgeDist = 20
	}
	return self
end

return new
