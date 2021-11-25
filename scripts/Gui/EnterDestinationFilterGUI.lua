--
-- AutoDrive Enter filter for destinations shown in drop down menus GUI
-- V1.1.0.0
--
-- @author Stephan Schlosser
-- @date 09/06/2019

ADEnterDestinationFilterGui = {}
ADEnterDestinationFilterGui.CONTROLS = {"textInputElement"}

local ADEnterDestinationFilterGui_mt = Class(ADEnterDestinationFilterGui, ScreenElement)

function ADEnterDestinationFilterGui:new(target)
    local element = ScreenElement.new(target, ADEnterDestinationFilterGui_mt)
    element.returnScreenName = ""
    element.textInputElement = nil
    element:registerControls(ADEnterDestinationFilterGui.CONTROLS)
    return element
end

function ADEnterDestinationFilterGui:onOpen()
    ADEnterDestinationFilterGui:superClass().onOpen(self)
    self.textInputElement.blockTime = 0
    self.textInputElement:onFocusActivate()
    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil then
        self.textInputElement:setText(g_currentMission.controlledVehicle.ad.destinationFilterText)
    end
end

function ADEnterDestinationFilterGui:onClickOk()
    ADEnterDestinationFilterGui:superClass().onClickOk(self)
    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil then
        g_currentMission.controlledVehicle.ad.destinationFilterText = self.textInputElement.text
    end
    self:onClickBack()
end

function ADEnterDestinationFilterGui:onClickCancel()
    self.textInputElement:setText("")
end

function ADEnterDestinationFilterGui:onClickBack()
    ADEnterDestinationFilterGui:superClass().onClickBack(self)
end

function ADEnterDestinationFilterGui:onEnterPressed(_, isClick)
    if not isClick then
        self:onClickOk()
    end
end

function ADEnterDestinationFilterGui:onEscPressed()
    self:onClickBack()
end
