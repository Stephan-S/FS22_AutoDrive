ADNotificationsHistoryGui = {}
ADNotificationsHistoryGui.CONTROLS = {"listItemTemplate", "autoDriveNotificationsList"}

ADNotificationsHistoryGui.ICON_UVS = {
    {0, 768, 256, 256},
    {256, 768, 256, 256},
    {512, 768, 256, 256}
}

local ADNotificationsHistoryGui_mt = Class(ADNotificationsHistoryGui, ScreenElement)

function ADNotificationsHistoryGui:new(target)
    local o = ScreenElement:new(target, ADNotificationsHistoryGui_mt)
    o.returnScreenName = ""
    o.history = {}
    o:registerControls(ADNotificationsHistoryGui.CONTROLS)
    return o
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
        new.elements[1]:setImageUVs(nil, unpack(getNormalizedUVs(self.ICON_UVS[n.messageType])))
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
