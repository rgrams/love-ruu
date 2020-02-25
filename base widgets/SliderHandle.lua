
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local SliderHandle = Button:extend()

function SliderHandle.updatePos(self, dx, dy, isLocal)
	local startPoint = -self.length/2 + self.offset -- Slider handle must be anchored to center point.
	local endPoint = self.length/2 + self.offset

	if dx and dy then
		-- Convert dx and dx to local deltas relative to the bar.
		if not isLocal then
			local bar = self.bar
			local wx, wy = bar._to_world.x + dx, bar._to_world.y + dy
			dx, dy = bar:toLocal(wx, wy)
		end
		-- Clamp to start and end points.
		self.parentOffsetX = math.max(startPoint, math.min(endPoint, self.parentOffsetX + dx))
	else -- Set based on current fraction.
		self.parentOffsetX = startPoint + self.length * self.fraction
	end
end

function SliderHandle.drag(self, dx, dy, dragType, isLocal)
	if dragType then  return  end -- Only respond to the default drag type.
	self:updatePos(dx, dy, isLocal)

	self.fraction = (self.parentOffsetX - self.offset + self.length/2) / self.length
	if self.dragFunc then  self:dragFunc(self.fraction)  end

	self.theme[self.themeType].drag(self, dx, dy)
end

local dirs = { up = {0, -1}, down = {0, 1}, left = {-1, 0}, right = {1, 0} }
local COS45 = math.cos(math.rad(45))

function SliderHandle.getFocusNeighbor(self, dir)
	local dirVec = dirs[dir]
	local bar = self.bar
	local x, y = bar._to_world.x + dirVec[1], bar._to_world.y + dirVec[2]
	x, y = bar:toLocal(x, y)
	if math.abs(x) > COS45 then -- Input direction is roughly aligned with slider rotation.
		self:drag(x * self.nudgeDist, 0, nil, true)
		return 1 -- Consume input.
	else
		return self.neighbor[dir]
	end
end

return SliderHandle
