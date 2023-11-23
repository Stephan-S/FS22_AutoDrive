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
    if self.textInputElement.overlay and self.textInputElement.overlay.colorFocused then
        if AutoDrive.currentColors and AutoDrive.currentColors.ad_color_textInputBackground then
            self.textInputElement.overlay.colorFocused = AutoDrive.currentColors.ad_color_textInputBackground
        end
    end
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

function ADEnterDestinationFilterGui:onCreateAutoDriveHeaderText(box)
    if self.storedHeaderKey == nil then
        self.storedHeaderKey = box.text
    end
    if self.storedHeaderKey ~= nil then

        local hasText = self.storedHeaderKey ~= nil and self.storedHeaderKey ~= ""
        if hasText then
            local text = self.storedHeaderKey
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADEnterDestinationFilterGui:onCreateAutoDriveText1(box)
    if self.storedKey1 == nil then
        self.storedKey1 = box.text
    end
    if self.storedKey1 ~= nil then

        local hasText = self.storedKey1 ~= nil and self.storedKey1 ~= ""
        if hasText then
            local text = self.storedKey1
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADEnterDestinationFilterGui:copyAttributes(src)
	ADEnterDestinationFilterGui:superClass().copyAttributes(self, src)
    self.storedHeaderKey = src.storedHeaderKey
    self.storedKey1 = src.storedKey1
end
