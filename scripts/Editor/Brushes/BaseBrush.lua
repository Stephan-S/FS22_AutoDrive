--[[
	Brushes that can be used for waypoint selection/manipulation.
]]
---@class ADBrush : ConstructionBrush
ADBrush = {
	imageFilename ="textures/input_record_4.dds",
	name = "base",
	radius = 0.5,
	translationPrefix = "gui_ad_editor_",
	primaryButtonText = "primary_text",
	primaryAxisText = "primary_axis_text",
	secondaryButtonText = "secondary_text",
	secondaryAxisText = "secondary_axis_text",
	tertiaryButtonText = "tertiary_text",
	inputTitle = "input_title",
	yesNoTitle = "yesNo_title"
}
local ADBrush_mt = Class(ADBrush, ConstructionBrush)
function ADBrush.new(customMt, cursor)
	local self =  ConstructionBrush.new(customMt or ADBrush_mt, cursor)
	self.cursor:setShapeSize(self.radius)
	self.cursor:setShape(GuiTopDownCursor.SHAPES.CIRCLE)
	return self
end

function ADBrush:isAtPos(position, x, y, z)
	if MathUtil.getPointPointDistance(position.x, position.z, x, z) < self.radius then 
		return math.abs(position.y - y) < 3
	end
end

function ADBrush:getHoveredNodeId(excludeLambda)
	local x, y, z = self.cursor:getPosition()
	-- try to get a waypoint in mouse range
	for _, point in pairs(self.graphWrapper:getVisiblePoints()) do
		if self:isAtPos(point, x, y, z) then
			if excludeLambda == nil or not excludeLambda(point.id) then
				return point.id
			end
		end
	end
end

function ADBrush:setParameters(graphWrapper, camera, translation)
	self.graphWrapper = graphWrapper
	self.camera = camera
	self.translation = translation
end

function ADBrush:update()
	self.graphWrapper:setHovered(self:getHoveredNodeId())
end

function ADBrush:openTextInput(callback,title,args)
	g_gui:showTextInputDialog({
			disableFilter = true,
			callback = callback,
			target = self,
			defaultText = "",
			dialogPrompt = title,
			imePrompt = title,
			maxCharacters = 50,
			confirmText = g_i18n:getText("button_ok"),
			args = args
		})
end

function ADBrush:showYesNoDialog(callback,title,args)
	g_gui:showYesNoDialog({
			text = title,
			callback = callback,
			target = self,
			args = args
		})
end

function ADBrush.getName(class)
	return g_i18n:getText(ADBrush.translationPrefix .. class.name .. "_name")
end

function ADBrush:getTranslation(translation, ...)
	return string.format(g_i18n:getText(self.translation .. translation), ...)
end

function ADBrush:debug(str, ...)
	--- TODO: add proper debug!
	--print(string.format("AD brush(%s/%s): ".. str, g_time, g_updateLoopIndex, ...))	
end