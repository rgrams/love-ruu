
local _basePath = (...):gsub("Slider$", "")
local Button = require(_basePath .. "Button")

local Slider = Button:extend()
Slider.className = "Slider"

Slider.nudgeFraction = 0.1

local max, min = math.max, math.min

local function clamp(v, bottom, top)
	return max(bottom, min(v, top))
end

function Slider.set(self, ruu, themeData, releaseFn, fraction, length, theme)
	self.fraction = fraction or 0
	self.length = length or 100
	self.toLocal = ruu.themeEssentials.toLocal
	Slider.super.set(self, ruu, themeData, releaseFn, theme)
	self.theme.drag(self, 0, 0, self.fraction)
end

function Slider.press(self, depth, mx, my, isKeyboard)
	if depth > 1 then  return  end
	Slider.super.press(self, depth, mx, my, isKeyboard)
	self.ruu:startDrag(self)
end

function Slider.release(self, depth, dontFire, mx, my, isKeyboard)
	if depth > 1 then  return  end
	Slider.super.release(self, depth, dontFire, mx, my, isKeyboard)
	self.ruu:stopDraggingWidget(self)
end

function Slider.onDrag(self, dragFn)
	self.dragFn = dragFn
	return self -- Allow chaining.
end

function Slider.drag(self, dx, dy, dragType, isLocal)
	if dragType then  return  end -- Only respond to the default drag type.

	if not isLocal then
		dx, dy = self:toLocal(dx, dy, true)
	end

	self.fraction = clamp(self.fraction + dx/self.length, 0, 1)

	if self.dragFn then
		if self.releaseArgs then
			self.dragFn(unpack(self.releaseArgs))
		else
			self.dragFn(self)
		end
	end
	self.theme.drag(self, dx, dy, self.fraction)
end

local dirs = { up = {0, 1}, down = {0, -1}, left = {-1, 0}, right = {1, 0} }
local COS_45 = math.cos(math.rad(45))

local function sign(x)
	return x >= 0 and 1 or -1
end

function Slider.getFocusNeighbor(self, depth, dir)
	if depth > 1 then  return  end
	local dirVec = dirs[dir]
	if dirVec then
		local dx, dy = dirVec[1], dirVec[2]
		dx, dy = self:toLocal(dx, dy, true)
		if math.abs(dx) > COS_45 then -- Input direction is roughly aligned with slider rotation.
			self:drag(sign(dx) * self.nudgeFraction*self.length, 0, nil, true)
			return true -- Consume input.
		else
			return self.neighbor[dir]
		end
	else
		return self.neighbor[dir]
	end
end

return Slider
