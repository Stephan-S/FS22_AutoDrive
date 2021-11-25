--
-- AutoDrive GUI
-- V1.0.0.0
--
-- @author Stephan Schlosser
-- @date 08/04/2019

ADSettingsPage = {}

local ADSettingsPage_mt = Class(ADSettingsPage, TabbedMenuFrameElement)

ADSettingsPage.CONTROLS = {"settingsContainer", "ingameMenuHelpBox", "headerIcon"}

function ADSettingsPage:new(target)
    local element = TabbedMenuFrameElement.new(target, ADSettingsPage_mt)
    element.returnScreenName = ""
    element.settingElements = {}
    element:registerControls(ADSettingsPage.CONTROLS)
    return element
end

function ADSettingsPage:onFrameOpen()
    ADSettingsPage:superClass().onFrameOpen(self)
    FocusManager:unsetHighlight(FocusManager.currentFocusData.highlightElement)
    FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
    if not self:hasChanges() then
        self:loadGUISettings()
    end
end

function ADSettingsPage:onFrameClose()
    ADSettingsPage:superClass().onFrameClose(self)
end

function ADSettingsPage:onCreateAutoDriveSetting(element)
    self.settingElements[element.name] = element
    local setting = AutoDrive.settings[element.name]
    element.labelElement.text = g_i18n:getText(setting.text)
    element.toolTipText = g_i18n:getText(setting.tooltip)

    local labels = {}
    for i = 1, #setting.texts, 1 do
        if setting.translate == true then
            labels[i] = g_i18n:getText(setting.texts[i])
        else
            labels[i] = setting.texts[i]
        end
    end
    element:setTexts(labels)

    local iconElem = element.elements[6]
    if iconElem ~= nil then
        if setting.isUserSpecific then
            -- iconElem:setImageUVs(nil, unpack(getNormalizedUVs(ADSettings.ICON_UV.USER)))
            iconElem:setImageUVs(nil, unpack(GuiUtils.getUVs(ADSettings.ICON_UV.USER)))
        elseif setting.isVehicleSpecific then
            -- iconElem:setImageUVs(nil, unpack(getNormalizedUVs(ADSettings.ICON_UV.VEHICLE)))
            iconElem:setImageUVs(nil, unpack(GuiUtils.getUVs(ADSettings.ICON_UV.VEHICLE)))
        else
            -- iconElem:setImageUVs(nil, unpack(getNormalizedUVs(ADSettings.ICON_UV.GLOBAL)))
            iconElem:setImageUVs(nil, unpack(GuiUtils.getUVs(ADSettings.ICON_UV.GLOBAL)))
        end
    end
end

function ADSettingsPage:onOptionChange(state, element)
    local setting = AutoDrive.settings[element.name]
    if setting.isVehicleSpecific and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil and g_currentMission.controlledVehicle.ad.settings[element.name] ~= nil then
        setting = g_currentMission.controlledVehicle.ad.settings[element.name]
    end
    setting.new = state

    local iconElem = element.elements[6]
    if iconElem ~= nil then
        if setting.new ~= setting.current then
            iconElem:setImageColor(iconElem.overlayState, unpack(ADSettings.ICON_COLOR.CHANGED))
        else
            iconElem:setImageColor(iconElem.overlayState, unpack(ADSettings.ICON_COLOR.DEFAULT))
        end
    end
end

function ADSettingsPage:hasChanges()
    for settingName, _ in pairs(self.settingElements) do
        if AutoDrive.settings[settingName] ~= nil then
            local setting = AutoDrive.settings[settingName]
            if setting.isVehicleSpecific and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil and g_currentMission.controlledVehicle.ad.settings[settingName] ~= nil then
                setting = g_currentMission.controlledVehicle.ad.settings[settingName]
            end
            if setting.new ~= nil and setting.new ~= setting.current then
                return true
            end
        end
    end
    return false
end

----- Get the frame's main content element's screen size.
function ADSettingsPage:getMainElementSize()
    return self.settingsContainer.size
end

--- Get the frame's main content element's screen position.
function ADSettingsPage:getMainElementPosition()
    return self.settingsContainer.absPosition
end

function ADSettingsPage:onIngameMenuHelpTextChanged(box)
    local hasText = box.text ~= nil and box.text ~= ""
    self.ingameMenuHelpBox:setVisible(hasText)
end

function ADSettingsPage:loadGUISettings()
    for settingName, _ in pairs(self.settingElements) do
        if AutoDrive.settings[settingName] ~= nil then
            local setting = AutoDrive.settings[settingName]
            if setting.isVehicleSpecific and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.ad ~= nil and g_currentMission.controlledVehicle.ad.settings[settingName] ~= nil then
                setting = g_currentMission.controlledVehicle.ad.settings[settingName]
            end
            self:loadGUISetting(settingName, setting.current)
        end
    end
end

function ADSettingsPage:loadGUISetting(settingName, state)
    local element = self.settingElements[settingName]
    element:setState(state, false)
    self:onOptionChange(state, element)
end
