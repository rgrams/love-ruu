
local M = {}

function M.getDrawIndex(widget, layerDepths) -- combines layer and index to get an absolute draw index
	local layer = widget.object.layer
	local index = widget.object.drawIndex
	local layerDepth = layerDepths[layer]
	if not layerDepth then
		print("WARNING: ruutil.getDrawIndex() - layer, '"..tostring(layer).."', not found in list. May not accurately get top widget unless you call ruu.registerLayers")
		return index
	end
	return layerDepth + index
end

function M.getTopWidget(widgetDict, layerDepths, conditionFn) -- find widget with highest drawIndex
	local maxIdx, topWidget = -1, nil
	for widget,_ in pairs(widgetDict) do
		local drawIdx = M.getDrawIndex(widget, layerDepths)
		if drawIdx > maxIdx then
			if conditionFn then
				if conditionFn(widget) then
					maxIdx = drawIdx
					topWidget = widget
				end
			else
				maxIdx = drawIdx
				topWidget = widget
			end
		end
	end
	return topWidget
end


return M
