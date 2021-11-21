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
    local o = ScreenElement:new(target, ADEnterDestinationFilterGui_mt)
    o.returnScreenName = ""
    o.textInputElement = nil
    o:registerControls(ADEnterDestinationFilterGui.CONTROLS)
    return o
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
