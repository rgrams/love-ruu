
local _basePath = (...):gsub("RadioButton$", "")
local ToggleButton = require(_basePath .. "ToggleButton")

local RadioButton = ToggleButton:extend()
RadioButton.className = "RadioBtn"

-- NOTE: `self.siblings` can be nil if it hasn't been set as part of a group yet.

function RadioButton.setGroup(widgets)
	local siblings = {} -- Copy the list so we're not messing with the user's table.
	for i,widget in ipairs(widgets) do
		siblings[i] = widget
		widget.siblings = siblings -- All siblings share the same table, which includes themselves.
	end
end

function RadioButton.final(self)
	if self.siblings then
		for i,widget in ipairs(self.siblings) do
			if widget == self then
				table.remove(self.siblings, i)
				break
			end
		end
	end
	-- NOTE: The user is responsible for checking another button if they delete the checked one.
end

function RadioButton.siblingWasChecked(self)
	self.isChecked = false
	self.wgtTheme.setChecked(self, false)
end

local function unCheckSiblings(self)
	if self.siblings then
		for i,widget in ipairs(self.siblings) do
			if widget ~= self then  widget:siblingWasChecked()  end
		end
	end
end

function RadioButton.release(self, depth, dontFire, mx, my, isKeyboard)
	if depth ~= 1 then  return  end
	if not self.isPressed then  dontFire = true  end
	self.isPressed = false
	if not dontFire then
		if not self.isChecked then
			self.isChecked = true
			unCheckSiblings(self)
		end
		-- Still call release function even if nothing happened (if we were already checked).
		if self.releaseFn then
			if self.releaseArgs then
				self.releaseFn(unpack(self.releaseArgs))
			else
				self.releaseFn(self)
			end
		end
	end
	self.wgtTheme.release(self, dontFire, mx, my, isKeyboard)
end

-- For outside scripts to manually check or uncheck buttons.
function RadioButton.setChecked(self, isChecked)
	if isChecked and not self.isChecked then -- Check.
		self.isChecked = true
		unCheckSiblings(self)
		self.wgtTheme.setChecked(self, true)
	elseif self.isChecked and not isChecked then -- Un-check
		self.isChecked = false
		self.wgtTheme.setChecked(self, false)
		-- NOTE: It's weird to un-check a radio button.
		--       The user is responsible for checking another button if they un-check the checked one.
	end
end

return RadioButton
