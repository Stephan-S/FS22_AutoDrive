--
-- AutoDrive GUI
-- V1.0.0.0
--
-- @author TyKonKet
-- @date 03/12/2019

ADDebugSettingsPage = {}

local ADDebugSettingsPage_mt = Class(ADDebugSettingsPage, TabbedMenuFrameElement)

-- ADDebugSettingsPage.CONTROLS = {"settingsContainer", "headerIcon", "headerText"}
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
    local menuButtonInfo = {{inputAction = InputAction.MENU_BACK, text = g_i18n:getText("button_back"), callback = parent:makeSelfCallback(parent.onButtonBack), showWhenPaused = true}}
    self:setMenuButtonInfo(menuButtonInfo)
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

function ADDebugSettingsPage:onCreateAutoDriveHeaderText(box)
    if self.storedHeaderText == nil then
        self.storedHeaderText = box.text
    end
    if self.storedHeaderText ~= nil then

        local hasText = self.storedHeaderText ~= nil and self.storedHeaderText ~= ""
        if hasText then
            local text = self.storedHeaderText
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:copyAttributes(src)
	ADDebugSettingsPage:superClass().copyAttributes(self, src)
    self.storedHeaderText = src.storedHeaderText
end
