
local _basePath = (...):gsub("Slider$", "")
local Button = require(_basePath .. "Button")

local Slider = Button:extend()

Slider.nudgeDist = 5

local function toLocal(self, dx, dy)
	local wm = self.themeData._to_world
	return self.themeData:toLocal(wm.x + dx, wm.y + dy)
end

function Slider.set(self, ruu, themeData, releaseFn, fraction, length, wgtTheme)
	self.fraction = fraction or 0
	self.length = length or 100
	self.xPos = 0
	Slider.super.set(self, ruu, themeData, releaseFn, wgtTheme)
	self:updatePos() -- To update slider pos based on current fraction.
end

function Slider.onDrag(self, dragFn)
	self.dragFn = dragFn
	return self -- Allow chaining.
end

function Slider.updatePos(self, dx, dy, isLocal)
	local startPoint = -self.length/2 -- Assumes that the handle at x=0 is centered on the bar.
	local endPoint = self.length/2
	local pos = self.themeData.pos

	if dx and dy then
		if not isLocal then -- Convert dx and dy to local deltas relative to the bar, so dx is always along the bar.
			dx, dy = toLocal(self, dx, dy)
		end
		pos.x = math.max(startPoint, math.min(endPoint, pos.x + dx)) -- Clamp to start and end points.

	else -- .updatePos called with no dx or dy - Set pos based on current fraction.
		pos.x = startPoint + self.length * self.fraction
	end
	self.xPos = pos.x
end

function Slider.drag(self, dx, dy, dragType, isLocal)
	if dragType then  return  end -- Only respond to the default drag type.

	self:updatePos(dx, dy, isLocal)

	self.fraction = self.xPos / self.length + 0.5
	if self.dragFn then
		if self.releaseArgs then
			self.dragFn(unpack(self.releaseArgs))
		else
			self.dragFn(self)
		end
	end
	self.wgtTheme.drag(self, dx, dy)
end

local dirs = { up = {0, 1}, down = {0, -1}, left = {-1, 0}, right = {1, 0} }
local COS_45 = math.cos(math.rad(45))

function Slider.getFocusNeighbor(self, dir)
	local dirVec = dirs[dir]
	if dirVec then
		local dx, dy = dirVec[1], dirVec[2]
		dx, dy = toLocal(self, dx, dy)
		if math.abs(dx) > COS_45 then -- Input direction is roughly aligned with slider rotation.
			self:drag(dx * self.nudgeDist, 0, nil, true)
			return 1 -- Consume input.
		else
			return self.neighbor[dir]
		end
	else
		return self.neighbor[dir]
	end
end

return Slider
