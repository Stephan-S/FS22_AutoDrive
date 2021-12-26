--
-- AutoDrive Enter Target Name GUI
-- V1.1.0.0
--
-- @author Stephan Schlosser
-- @date 08/08/2019

ADScanConfirmationGui = {}
ADScanConfirmationGui.CONTROLS = {"titleElement"}

local ADScanConfirmationGui_mt = Class(ADScanConfirmationGui, ScreenElement)

function ADScanConfirmationGui.new(target)
    local self = ScreenElement.new(target, ADScanConfirmationGui_mt)
    self.returnScreenName = ""
    self:registerControls(ADScanConfirmationGui.CONTROLS)
    return self
end

function ADScanConfirmationGui:onOpen()
    ADScanConfirmationGui:superClass().onOpen(self)
end

function ADScanConfirmationGui:onClickOk()
    ADScanConfirmationGui:superClass().onClickOk(self)
    AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_YES
    self:onClickBack()
end

function ADScanConfirmationGui:onClickActivate()
    ADScanConfirmationGui:superClass().onClickActivate(self)
    self:onClickBack()
end

function ADScanConfirmationGui:onClickCancel()
    ADScanConfirmationGui:superClass().onClickCancel(self)
    AutoDrive.scanDialogState = AutoDrive.SCAN_DIALOG_RESULT_NO
    self:onClickBack()
end

function ADScanConfirmationGui:onClickBack()
    ADScanConfirmationGui:superClass().onClickBack(self)
end

function ADScanConfirmationGui:onEnterPressed(_, isClick)
    if not isClick then
        self:onClickOk()
    end
end

function ADScanConfirmationGui:onEscPressed()
    self:onClickBack()
end

function ADScanConfirmationGui:onCreateAutoDriveText1(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText2(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText3(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText4(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText5(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText6(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText7(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText8(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText9(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText10(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText11(box)
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

function ADScanConfirmationGui:onCreateAutoDriveText12(box)
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

function ADScanConfirmationGui:copyAttributes(src)
	ADScanConfirmationGui:superClass().copyAttributes(self, src)
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
