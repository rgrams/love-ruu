
local basePath = (...):gsub('[^%.]+$', '')
local Button = require(basePath .. "Button")
local Panel = Button:extend()

-- The same as Button.

return Panel
