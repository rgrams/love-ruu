
local M = {}

function M.getDrawIndex(node, layerDepths) -- combines layer and index to get an absolute draw index
	local layer = node.layer
	local index = node._drawIndex
	local layerDepth = layerDepths[layer]
	if not layerDepth then
		print("WARNING: ruutil.getDrawIndex() - layer not found in list. May not accurately get top widget unless you call ruu.registerLayers")
		return index
	end
	return layerDepth + index
end

function M.getTopWidget(widgetDict, wgtNodeKey, layerDepths, conditionFn) -- find widget with highest drawIndex
	local maxIdx, topWidget = -1, nil
	for widget,_ in pairs(widgetDict) do
		local node = widget[wgtNodeKey]
		local drawIdx = M.getDrawIndex(node, layerDepths)
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
