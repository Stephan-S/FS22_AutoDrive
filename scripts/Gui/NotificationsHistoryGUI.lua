ADNotificationsHistoryGui = {}
ADNotificationsHistoryGui.CONTROLS = {"listItemTemplate", "autoDriveNotificationsList"}

ADNotificationsHistoryGui.ICON_UVS = {
    {0, 768, 256, 256},
    {256, 768, 256, 256},
    {512, 768, 256, 256}
}

local ADNotificationsHistoryGui_mt = Class(ADNotificationsHistoryGui, ScreenElement)

function ADNotificationsHistoryGui:new(target)
    local element = ScreenElement.new(target, ADNotificationsHistoryGui_mt)
    element.returnScreenName = ""
    element.history = {}
    element:registerControls(ADNotificationsHistoryGui.CONTROLS)
    return element
end

function ADNotificationsHistoryGui:onCreate()
    self.listItemTemplate:unlinkElement()
    self.listItemTemplate:setVisible(false)
end

function ADNotificationsHistoryGui:onOpen()
    self:refreshItems()
    ADNotificationsHistoryGui:superClass().onOpen(self)
end

function ADNotificationsHistoryGui:refreshItems()
    self.history = ADMessagesManager:getHistory()
    self.autoDriveNotificationsList:deleteListItems()
    for _, n in pairs(self.history) do
        local new = self.listItemTemplate:clone(self.autoDriveNotificationsList)
        new:setVisible(true)
        -- new.elements[1]:setImageUVs(nil, unpack(getNormalizedUVs(self.ICON_UVS[n.messageType])))
        local normalizedIconUVs = GuiUtils.getUVs(self.ICON_UVS[n.messageType])
        new.elements[1]:setImageUVs(nil, unpack(normalizedIconUVs))
        new.elements[2]:setText(n.text)
        new:updateAbsolutePosition()
    end
end

function ADNotificationsHistoryGui:onListSelectionChanged(rowIndex)
end

function ADNotificationsHistoryGui:onDoubleClick(rowIndex)
    if rowIndex > 0 and rowIndex <= #self.history then
        -- goto vehicle
        local v = self.history[rowIndex].vehicle
        if v ~= nil then
            self:onClickBack()
            g_currentMission:requestToEnterVehicle(v)
        end
    end
end

function ADNotificationsHistoryGui:onClickBack()
    ADNotificationsHistoryGui:superClass().onClickBack(self)
end

function ADNotificationsHistoryGui:onClickCancel()
    -- delete selected
    ADMessagesManager:removeFromHistory(self.autoDriveNotificationsList:getSelectedElementIndex())
    ADNotificationsHistoryGui:superClass().onClickCancel(self)
end

function ADNotificationsHistoryGui:onClickActivate()
    -- delete all
    ADMessagesManager:clearHistory()
    ADNotificationsHistoryGui:superClass().onClickActivate(self)
end

function ADNotificationsHistoryGui:onEnterPressed(_, isClick)
    if not isClick then
        self:onDoubleClick(self.autoDriveNotificationsList:getSelectedElementIndex())
    end
end

function ADNotificationsHistoryGui:onEscPressed()
    self:onClickBack()
end

function ADNotificationsHistoryGui:onCreateAutoDriveHeaderText(box)
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

function ADNotificationsHistoryGui:onCreateAutoDriveText1(box)
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

function ADNotificationsHistoryGui:copyAttributes(src)
	ADNotificationsHistoryGui:superClass().copyAttributes(self, src)
    self.storedHeaderKey = src.storedHeaderKey
    self.storedKey1 = src.storedKey1
end
