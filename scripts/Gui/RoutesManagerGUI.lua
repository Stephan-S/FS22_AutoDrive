ADRoutesManagerGui = {}
ADRoutesManagerGui.CONTROLS = {"textInputElement", "listItemTemplate", "autoDriveRoutesManagerList"}

local ADRoutesManagerGui_mt = Class(ADRoutesManagerGui, ScreenElement)

function ADRoutesManagerGui:new(target)
    local element = ScreenElement.new(target, ADRoutesManagerGui_mt)
    element.returnScreenName = ""
    element.routes = {}
    element:registerControls(ADRoutesManagerGui.CONTROLS)
    return element
end

function ADRoutesManagerGui:onCreate()
    self.listItemTemplate:unlinkElement()
    self.listItemTemplate:setVisible(false)
end

function ADRoutesManagerGui:onOpen()
    if self.textInputElement.overlay and self.textInputElement.overlay.colorFocused then
        if AutoDrive.currentColors and AutoDrive.currentColors.ad_color_textInputBackground then
            self.textInputElement.overlay.colorFocused = AutoDrive.currentColors.ad_color_textInputBackground
        end
    end
    self:refreshItems()
    ADRoutesManagerGui:superClass().onOpen(self)
end

function ADRoutesManagerGui:refreshItems()
    self.routes = ADRoutesManager:getRoutes(AutoDrive.loadedMap)
    self.autoDriveRoutesManagerList:deleteListItems()
    for _, r in pairs(self.routes) do
        local new = self.listItemTemplate:clone(self.autoDriveRoutesManagerList)
        new:setVisible(true)
        new.elements[1]:setText(r.name)
        new.elements[2]:setText(r.date)
        new:updateAbsolutePosition()
    end
end

function ADRoutesManagerGui:onListSelectionChanged(rowIndex)
end

function ADRoutesManagerGui:onDoubleClick(rowIndex)
    self.textInputElement:setText(self.routes[rowIndex].name)
end

function ADRoutesManagerGui:onClickOk()
    ADRoutesManagerGui:superClass().onClickOk(self)
    local newName = self.textInputElement.text
    if
        table.f_contains(
            self.routes,
            function(v)
                return v.name == newName
            end
        )
     then
        g_gui:showYesNoDialog({text = g_i18n:getText("gui_ad_routeExportWarn_text"), title = g_i18n:getText("gui_ad_routeExportWarn_title"), callback = self.onExportDialogCallback, target = self})
    else
        self:onExportDialogCallback(true)
    end
end

function ADRoutesManagerGui:onExportDialogCallback(yes)
    if yes then
        ADRoutesManager:export(self.textInputElement.text)
        self:refreshItems()
    end
end

function ADRoutesManagerGui:onClickCancel()
    if #self.routes > 0 then
        ADRoutesManager:import(self.routes[self.autoDriveRoutesManagerList:getSelectedElementIndex()].name)
        self:onClickBack()
    end
    ADRoutesManagerGui:superClass().onClickCancel(self)
end

function ADRoutesManagerGui:onClickBack()
    ADRoutesManagerGui:superClass().onClickBack(self)
end

function ADRoutesManagerGui:onClickActivate()
    if #self.routes > 0 then
        g_gui:showYesNoDialog({text = g_i18n:getText("gui_ad_routeDeleteWarn_text"):format(self.routes[self.autoDriveRoutesManagerList:getSelectedElementIndex()].name), title = g_i18n:getText("gui_ad_routeDeleteWarn_title"), callback = self.onDeleteDialogCallback, target = self})
    end
    ADRoutesManagerGui:superClass().onClickActivate(self)
end

function ADRoutesManagerGui:onDeleteDialogCallback(yes)
    if yes then
        ADRoutesManager:remove(self.routes[self.autoDriveRoutesManagerList:getSelectedElementIndex()].name)
        self:refreshItems()
    end
end

function ADRoutesManagerGui:onEnterPressed(_, isClick)
    if not isClick then
    --self:onClickOk()
    end
end

function ADRoutesManagerGui:onEscPressed()
    self:onClickBack()
end

function ADRoutesManagerGui:onCreateAutoDriveText1(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText2(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText3(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText4(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText5(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText6(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText7(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText8(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText9(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText10(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText11(box)
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

function ADRoutesManagerGui:onCreateAutoDriveText12(box)
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

function ADRoutesManagerGui:copyAttributes(src)
	ADRoutesManagerGui:superClass().copyAttributes(self, src)
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
