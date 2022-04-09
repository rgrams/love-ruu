
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

local _layerDepths

local function depthSorter(a, b)
	local drawIdxA = M.getDrawIndex(a, _layerDepths)
	local drawIdxB = M.getDrawIndex(b, _layerDepths)
	return drawIdxA > drawIdxB
end

-- First item is the "top".
function M.getListByDepth(widgetDict, outList, layerDepths)
	outList = outList or {}
	for i=1,#outList do
		outList[i] = nil
	end
	for wgt,_ in pairs(widgetDict) do
		table.insert(outList, wgt)
	end
	_layerDepths = layerDepths
	table.sort(outList, depthSorter)
	return outList
end


return M
