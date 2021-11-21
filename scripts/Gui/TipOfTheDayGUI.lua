ADTipOfTheDayGUI = {}
ADTipOfTheDayGUI.CONTROLS = {"tipOfTheDayTemplate"}

local ADTipOfTheDayGUI_mt = Class(ADTipOfTheDayGUI, ScreenElement)

function ADTipOfTheDayGUI:new(target)
    local o = ScreenElement:new(target, ADTipOfTheDayGUI_mt)
    o.returnScreenName = ""
    --o.history = {}
    o:registerControls(ADTipOfTheDayGUI.CONTROLS)
    return o
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
    self.tipOfTheDayTemplate.elements[2]:setImageUVs(nil, unpack(getNormalizedUVs(self.tipOfTheDayContent.imageUV)))
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
