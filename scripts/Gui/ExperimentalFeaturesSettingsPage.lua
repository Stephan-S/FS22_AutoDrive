--
-- AutoDrive GUI
-- V1.0.0.0
--
-- @author TyKonKet
-- @date 04/12/2019

ADExperimentalFeaturesSettingsPage = {}

local ADExperimentalFeaturesSettingsPage_mt = Class(ADExperimentalFeaturesSettingsPage, TabbedMenuFrameElement)

ADExperimentalFeaturesSettingsPage.CONTROLS = {"settingsContainer", "headerIcon", "cloneElement", "headerText", "boxLayout"}

function ADExperimentalFeaturesSettingsPage:new(target)
    local element = TabbedMenuFrameElement.new(target, ADExperimentalFeaturesSettingsPage_mt)
    element.returnScreenName = ""
    element.experimentalFeaturesElements = {}
    element:registerControls(ADExperimentalFeaturesSettingsPage.CONTROLS)
    return element
end

function ADExperimentalFeaturesSettingsPage:setupMenuButtonInfo(parent)
    local menuButtonInfo = {{inputAction = InputAction.MENU_BACK, text = g_i18n:getText("button_back"), callback = parent:makeSelfCallback(parent.onButtonBack), showWhenPaused = true}}
    self:setMenuButtonInfo(menuButtonInfo)
end

function ADExperimentalFeaturesSettingsPage:onCreate()
    if self.cloneElement ~= nil then
        local no = g_i18n:getText("gui_ad_no")
        local yes = g_i18n:getText("gui_ad_yes")
        local options = {no, yes}
        for featureName, state in pairs(AutoDrive.experimentalFeatures) do
            local cloned = self.cloneElement:clone(self.cloneElement.parent, false, true)
            cloned.id = "clonedElement_" .. featureName
            cloned.name = featureName
            cloned:setLabel(featureName:gsub("([A-Z])", " %1"):gsub("^%l", string.upper))
            cloned:setTexts(options)
            local stateNumber = 1
            if state then
                stateNumber = 2
            end
            cloned:setState(stateNumber)
            -- focusId has to be unique, but is copied by clone element, so generate and assign a new unique focusId
            cloned.focusId = "adFocus_" .. featureName
            table.insert(self.experimentalFeaturesElements, cloned)
        end
        self.cloneElement:delete()
    end
end

function ADExperimentalFeaturesSettingsPage:onCreateElement(element)
    -- table.insert(self.experimentalFeaturesElements, element)
end

function ADExperimentalFeaturesSettingsPage:onFrameOpen()
    ADExperimentalFeaturesSettingsPage:superClass().onFrameOpen(self)
    -- FocusManager:unsetHighlight(FocusManager.currentFocusData.highlightElement)
    -- FocusManager:unsetFocus(FocusManager.currentFocusData.focusElement)
    self:updateElementsState()
	for _, child in pairs(self.boxLayout.elements) do
		FocusManager:loadElementFromCustomValues(child, child.focusId, child.focusChangeData, child.focusActive, child.isAlwaysFocusedOnOpen)
    end
    FocusManager:setFocus(self.boxLayout)
end

function ADExperimentalFeaturesSettingsPage:onFrameClose()
    ADExperimentalFeaturesSettingsPage:superClass().onFrameClose(self)
end

----- Get the frame's main content element's screen size.
function ADExperimentalFeaturesSettingsPage:getMainElementSize()
    return self.settingsContainer.size
end

--- Get the frame's main content element's screen position.
function ADExperimentalFeaturesSettingsPage:getMainElementPosition()
    return self.settingsContainer.absPosition
end

function ADExperimentalFeaturesSettingsPage:updateElementsState()
    for _, element in pairs(self.experimentalFeaturesElements) do
        local stateNumber = 1
        if AutoDrive.experimentalFeatures[element.name] then
            stateNumber = 2
        end
        element:setState(stateNumber)
    end
end

function ADExperimentalFeaturesSettingsPage:onOptionChange(state, element)
    state = state == 2
    AutoDriveExperimentalFeaturesEvent.sendEvent(element.name, state)
end

function ADExperimentalFeaturesSettingsPage:onCreateAutoDriveHeaderText(box)
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

function ADExperimentalFeaturesSettingsPage:copyAttributes(src)
	ADExperimentalFeaturesSettingsPage:superClass().copyAttributes(self, src)
    self.storedHeaderText = src.storedHeaderText
end
