
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
		self.parentOffsetX = math.max(startPoint, math.min(endPoint, self.parentOffsetX + dx or 0))
	else -- Set based on current fraction.
		self.parentOffsetX = startPoint + self.length * self.fraction
	end
end

function SliderHandle.drag(self, dx, dy, isLocal)
	self:updatePos(dx, dy, isLocal)

	self.fraction = (self.parentOffsetX - self.offset + self.length/2) / self.length
	print(self.fraction)
	if self.dragFunc then  self:dragFunc(self.fraction)  end

	self.theme[self.themeType].drag(self, dx, dy)
end

--[[
function SliderHandle.focusNeighbor(self, dir)
	return self.neighbor[dir]
end
--]]

return SliderHandle
