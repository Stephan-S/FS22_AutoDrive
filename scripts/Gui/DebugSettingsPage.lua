--
-- AutoDrive GUI
-- V1.0.0.0
--
-- @author TyKonKet
-- @date 03/12/2019

ADDebugSettingsPage = {}

local ADDebugSettingsPage_mt = Class(ADDebugSettingsPage, TabbedMenuFrameElement)

-- ADDebugSettingsPage.CONTROLS = {"settingsContainer", "headerIcon", "headerText"}
ADDebugSettingsPage.CONTROLS = {"settingsContainer", "headerIcon", "boxLayout"}

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
    -- FocusManager:unsetHighlight(FocusManager.currentFocusData.highlightElement)
    -- FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
    self:updateDebugElements()
	FocusManager:setFocus(self.boxLayout)
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

function ADDebugSettingsPage:onCreateAutoDriveText1(box)
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

function ADDebugSettingsPage:onCreateAutoDriveText2(box)
    if self.storedKey2 == nil then
        self.storedKey2 = box.text
    end
    if self.storedKey2 ~= nil then

        local hasText = self.storedKey2 ~= nil and self.storedKey2 ~= ""
        if hasText then
            local text = self.storedKey2
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText3(box)
    if self.storedKey3 == nil then
        self.storedKey3 = box.text
    end
    if self.storedKey3 ~= nil then

        local hasText = self.storedKey3 ~= nil and self.storedKey3 ~= ""
        if hasText then
            local text = self.storedKey3
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText4(box)
    if self.storedKey4 == nil then
        self.storedKey4 = box.text
    end
    if self.storedKey4 ~= nil then

        local hasText = self.storedKey4 ~= nil and self.storedKey4 ~= ""
        if hasText then
            local text = self.storedKey4
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText5(box)
    if self.storedKey5 == nil then
        self.storedKey5 = box.text
    end
    if self.storedKey5 ~= nil then

        local hasText = self.storedKey5 ~= nil and self.storedKey5 ~= ""
        if hasText then
            local text = self.storedKey5
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText6(box)
    if self.storedKey6 == nil then
        self.storedKey6 = box.text
    end
    if self.storedKey6 ~= nil then

        local hasText = self.storedKey6 ~= nil and self.storedKey6 ~= ""
        if hasText then
            local text = self.storedKey6
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText7(box)
    if self.storedKey7 == nil then
        self.storedKey7 = box.text
    end
    if self.storedKey7 ~= nil then

        local hasText = self.storedKey7 ~= nil and self.storedKey7 ~= ""
        if hasText then
            local text = self.storedKey7
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText8(box)
    if self.storedKey8 == nil then
        self.storedKey8 = box.text
    end
    if self.storedKey8 ~= nil then

        local hasText = self.storedKey8 ~= nil and self.storedKey8 ~= ""
        if hasText then
            local text = self.storedKey8
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText9(box)
    if self.storedKey9 == nil then
        self.storedKey9 = box.text
    end
    if self.storedKey9 ~= nil then

        local hasText = self.storedKey9 ~= nil and self.storedKey9 ~= ""
        if hasText then
            local text = self.storedKey9
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText10(box)
    if self.storedKey10 == nil then
        self.storedKey10 = box.text
    end
    if self.storedKey10 ~= nil then

        local hasText = self.storedKey10 ~= nil and self.storedKey10 ~= ""
        if hasText then
            local text = self.storedKey10
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText11(box)
    if self.storedKey11 == nil then
        self.storedKey11 = box.text
    end
    if self.storedKey11 ~= nil then

        local hasText = self.storedKey11 ~= nil and self.storedKey11 ~= ""
        if hasText then
            local text = self.storedKey11
            if text:sub(1,6) == "$l10n_" then
                text = text:sub(7)
            end
            text = g_i18n:getText(text)
            box:setTextInternal(text, false, true)
        end
    end
end

function ADDebugSettingsPage:onCreateAutoDriveText12(box)
    if self.storedKey12 == nil then
        self.storedKey12 = box.text
    end
    if self.storedKey12 ~= nil then

        local hasText = self.storedKey12 ~= nil and self.storedKey12 ~= ""
        if hasText then
            local text = self.storedKey12
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
    self.storedHeaderKey = src.storedHeaderKey
    self.storedKey1 = src.storedKey1
    self.storedKey2 = src.storedKey2
    self.storedKey3 = src.storedKey3
    self.storedKey4 = src.storedKey4
    self.storedKey5 = src.storedKey5
    self.storedKey6 = src.storedKey6
    self.storedKey7 = src.storedKey7
    self.storedKey8 = src.storedKey8
    self.storedKey9 = src.storedKey9
    self.storedKey10 = src.storedKey10
    self.storedKey11 = src.storedKey11
    self.storedKey12 = src.storedKey12
end
