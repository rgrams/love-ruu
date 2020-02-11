
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")

local SliderBar = Button:extend()

function SliderBar.press(self, mx, my, isKeyboard)
	if mx and my then
		-- Figure on which side of the handle the user clicked & slide in that direction.
		local handleX = self.handle.parentOffsetX
		local localClickX, localClickY = self:toLocal(mx, my)
		if localClickX > handleX then
			self.handle:drag(self.handle.barClickDist, 0, true)
		elseif localClickX < handleX then
			self.handle:drag(-self.handle.barClickDist, 0, true)
		end
	end
	SliderBar.super.press(self, mx, my)
end

local dirs = { up = {0, -1}, down = {0, 1}, left = {-1, 0}, right = {1, 0} }
local COS45 = math.cos(math.rad(45))

function SliderBar.getFocusNeighbor(self, dir)
	local dirVec = dirs[dir]
	local x, y = self._to_world.x + dirVec[1], self._to_world.y + dirVec[2]
	x, y = self:toLocal(x, y)
	if math.abs(x) > COS45 then -- Input direction is roughly aligned with slider rotation.
		self.handle:drag(x * self.handle.nudgeDist, 0, true)
		return false
	else
		return self.handle.neighbor[dir]
	end
end

return SliderBar
