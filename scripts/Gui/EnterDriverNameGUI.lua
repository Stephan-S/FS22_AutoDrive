--
-- AutoDrive Enter Driver Name GUI
-- V1.1.0.0
--
-- @author Stephan Schlosser
-- @date 09/06/2019

ADEnterDriverNameGui = {}
ADEnterDriverNameGui.CONTROLS = {"textInputElement"}

local ADEnterDriverNameGui_mt = Class(ADEnterDriverNameGui, ScreenElement)

function ADEnterDriverNameGui:new(target)
    local element = ScreenElement.new(target, ADEnterDriverNameGui_mt)
    element.returnScreenName = ""
    element.textInputElement = nil
    element:registerControls(ADEnterDriverNameGui.CONTROLS)
    return element
end

function ADEnterDriverNameGui:onOpen()
    ADEnterDriverNameGui:superClass().onOpen(self)
    self.textInputElement.blockTime = 0
    self.textInputElement:onFocusActivate()
    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil then
        self.textInputElement:setText(g_currentMission.controlledVehicle.ad.stateModule:getName())
    end
end

function ADEnterDriverNameGui:onClickOk()
    ADEnterDriverNameGui:superClass().onClickOk(self)
    if g_currentMission.controlledVehicle ~= nil then
        AutoDrive.renameDriver(g_currentMission.controlledVehicle, self.textInputElement.text)
    end
    self:onClickBack()
end

function ADEnterDriverNameGui:onClickCancel()
    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil then
        self.textInputElement:setText(g_currentMission.controlledVehicle.ad.stateModule:getName())
    end
end

function ADEnterDriverNameGui:onClickBack()
    ADEnterDriverNameGui:superClass().onClickBack(self)
end

function ADEnterDriverNameGui:onEnterPressed(_, isClick)
    if not isClick then
        self:onClickOk()
    end
end

function ADEnterDriverNameGui:onEscPressed()
    self:onClickBack()
end
