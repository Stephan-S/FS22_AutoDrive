--
-- AutoDrive GUI
-- V1.0.0.0
--
-- @author TyKonKet
-- @date 03/12/2019

ADDebugSettingsPage = {}

local ADDebugSettingsPage_mt = Class(ADDebugSettingsPage, TabbedMenuFrameElement)

ADDebugSettingsPage.CONTROLS = {"settingsContainer", "headerIcon"}

function ADDebugSettingsPage:new(target)
    local element = TabbedMenuFrameElement.new(target, ADDebugSettingsPage_mt)
    element.returnScreenName = ""
    element.debugElements = {}
    element.lastDebugChannelMask = AutoDrive.currentDebugChannelMask
    element:registerControls(ADDebugSettingsPage.CONTROLS)
    return element
end

function ADDebugSettingsPage:setupMenuButtonInfo(parent)
    -- AutoDrive.debugMsg(nil, "[AD] ADDebugSettingsPage:setupMenuButtonInfo parent self %s", tostring(parent))
    self.menuButtonInfo = {{inputAction = InputAction.MENU_BACK, text = g_i18n:getText("button_back"), callback = parent:makeSelfCallback(parent.onClickBack), showWhenPaused = true}}
    self.hasCustomMenuButtons = true
end

function ADDebugSettingsPage:onFrameOpen()
    ADDebugSettingsPage:superClass().onFrameOpen(self)
    FocusManager:unsetHighlight(FocusManager.currentFocusData.highlightElement)
    FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
    self:updateDebugElements()
end

function ADDebugSettingsPage:onFrameClose()
    ADDebugSettingsPage:superClass().onFrameClose(self)
end

----- Get the frame's main content element's screen size.
function ADDebugSettingsPage:getMainElementSize()
    return self.settingsContainer.size
end

--- Get the frame's main content element's screen position.
function ADDebugSettingsPage:getMainElementPosition()
    return self.settingsContainer.absPosition
end

function ADDebugSettingsPage:update(dt)
    ADDebugSettingsPage:superClass().update(self, dt)
    if self.lastDebugChannelMask ~= AutoDrive.currentDebugChannelMask then
        self:updateDebugElements()
        self.lastDebugChannelMask = AutoDrive.currentDebugChannelMask
    end
end

function ADDebugSettingsPage:onCreateCheckbox(element, channel)
    element.checkbox = element.elements[1]
    element.checkbox.debugChannel = tonumber(channel)
    table.insert(self.debugElements, element)
end

function ADDebugSettingsPage:onClickToggle(element)
    AutoDrive:setDebugChannel(element.debugChannel)
end

function ADDebugSettingsPage:updateDebugElements()
    for _, element in pairs(self.debugElements) do
        local dbgChannel = element.checkbox.debugChannel
        if dbgChannel ~= AutoDrive.DC_ALL then
            element.checkbox:setIsChecked(AutoDrive.getDebugChannelIsSet(dbgChannel))
        else
            element.checkbox:setIsChecked(AutoDrive.currentDebugChannelMask == AutoDrive.DC_ALL)
        end
    end
end
