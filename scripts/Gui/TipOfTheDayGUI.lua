ADTipOfTheDayGUI = {}
ADTipOfTheDayGUI.CONTROLS = {"tipOfTheDayTemplate"}

local ADTipOfTheDayGUI_mt = Class(ADTipOfTheDayGUI, ScreenElement)

function ADTipOfTheDayGUI:new(target)
    local element = ScreenElement.new(target, ADTipOfTheDayGUI_mt)
    element.returnScreenName = ""
    --o.history = {}
    element:registerControls(ADTipOfTheDayGUI.CONTROLS)
    return element
end

function ADTipOfTheDayGUI:onCreate()
    --self.tipOfTheDayTemplate:unlinkElement()
    --self.tipOfTheDayTemplate:setVisible(false)
end

function ADTipOfTheDayGUI:onOpen()
    self:refreshItems()
    ADTipOfTheDayGUI:superClass().onOpen(self)    
    g_depthOfFieldManager:setBlurState(false)

    if self.activeCheckbox ~= nil then
        self.activeCheckbox:setIsChecked(AutoDrive.getSetting("showTipOfTheDay"))
    end
end

function ADTipOfTheDayGUI:refreshItems()
    AutoDrive.showNextTipOfTheDay()
    self.tipOfTheDayContent = AutoDrive.tipOfTheDay.currentTipOfTheDay

    self.tipOfTheDayTemplate.elements[1]:setText(g_i18n:getText(self.tipOfTheDayContent.titletext))
    -- self.tipOfTheDayTemplate.elements[2]:setImageUVs(nil, unpack(getNormalizedUVs(self.tipOfTheDayContent.imageUV)))
    local normalizedIconUVs = GuiUtils.getUVs(self.tipOfTheDayContent.imageUV)
    self.tipOfTheDayTemplate.elements[2]:setImageUVs(nil, unpack(normalizedIconUVs))
    self.tipOfTheDayTemplate.elements[3]:setText(g_i18n:getText(self.tipOfTheDayContent.text))

    self.imageWidth, self.imageHeight = getNormalizedScreenValues(self.tipOfTheDayContent.imageSize[1], self.tipOfTheDayContent.imageSize[2])
    self.tipOfTheDayTemplate.elements[2]:setSize(self.imageWidth, self.imageHeight)
    
end

function ADTipOfTheDayGUI:onListSelectionChanged(rowIndex)
end

function ADTipOfTheDayGUI:onDoubleClick(rowIndex)
end

function ADTipOfTheDayGUI:onClickBack()
    ADTipOfTheDayGUI:superClass().onClickBack(self)
end

function ADTipOfTheDayGUI:onClickCancel()
    ADTipOfTheDayGUI:superClass().onClickCancel(self)
end

function ADTipOfTheDayGUI:onClickActivate()
    --ADTipOfTheDayGUI:superClass().onClickActivate(self)
    --AutoDrive.showNextTipOfTheDay()
    self:refreshItems()
end

function ADTipOfTheDayGUI:onEnterPressed(_, isClick)
end

function ADTipOfTheDayGUI:onEscPressed()
    self:onClickBack()
end

function ADTipOfTheDayGUI:onCreateCheckbox(element)
    self.activeCheckbox = element.elements[1]
end

function ADTipOfTheDayGUI:onClickToggle(element)
    AutoDrive.toggleTipOfTheDay()

    self.activeCheckbox:setIsChecked(AutoDrive.getSetting("showTipOfTheDay"))
end

function ADTipOfTheDayGUI:onCreateAutoDriveHeaderText(box)
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

function ADTipOfTheDayGUI:onCreateAutoDriveText1(box)
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

function ADTipOfTheDayGUI:copyAttributes(src)
	ADTipOfTheDayGUI:superClass().copyAttributes(self, src)
    self.storedHeaderKey = src.storedHeaderKey
    self.storedKey1 = src.storedKey1
end
