--
-- AutoDrive Enter Group Name GUI
-- V1.1.0.0
--
-- @author Stephan Schlosser
-- @date 09/06/2019

ADEnterGroupNameGui = {}
ADEnterGroupNameGui.CONTROLS = {"textInputElement"}

local ADEnterGroupNameGui_mt = Class(ADEnterGroupNameGui, ScreenElement)

function ADEnterGroupNameGui:new(target)
    local element = ScreenElement.new(target, ADEnterGroupNameGui_mt)
    element.returnScreenName = ""
    element.textInputElement = nil
    element:registerControls(ADEnterGroupNameGui.CONTROLS)
    return element
end

function ADEnterGroupNameGui:onOpen()
    ADEnterGroupNameGui:superClass().onOpen(self)
    self.textInputElement.blockTime = 0
    self.textInputElement:onFocusActivate()
    self.textInputElement:setText("")
end

function ADEnterGroupNameGui:onClickOk()
    ADEnterGroupNameGui:superClass().onClickOk(self)

    if  self.textInputElement.text ~= ADGraphManager.debugGroupName then
        -- do not allow user to create debug group
        ADGraphManager:addGroup(self.textInputElement.text)
    end
    
    self:onClickBack()
end

function ADEnterGroupNameGui:onClickBack()
    ADEnterGroupNameGui:superClass().onClickBack(self)
end

function ADEnterGroupNameGui:onEnterPressed(_, isClick)
    if not isClick then
        self:onClickOk()
    end
end

function ADEnterGroupNameGui:onEscPressed()
    self:onClickBack()
end
