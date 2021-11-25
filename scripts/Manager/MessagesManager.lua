ADMessagesManager = {}
ADMessagesManager.messageTypes = {}
ADMessagesManager.messageTypes.INFO = 1
ADMessagesManager.messageTypes.WARN = 2
ADMessagesManager.messageTypes.ERROR = 3

ADMessagesManager.messages = {}
ADMessagesManager.currentMessage = nil
ADMessagesManager.currentMessageTimer = 0

ADMessagesManager.notifications = {}
ADMessagesManager.currentNotification = nil
ADMessagesManager.currentNotificationTimer = 0

ADMessagesManager.history = {}

ADMessagesManager.lastNotificationVehicle = nil

ADMessagesManager.huds = {}
ADMessagesManager.huds.message = {}
ADMessagesManager.huds.message.text = ""
ADMessagesManager.huds.message.textSize = 0.0135
ADMessagesManager.huds.message.posX = 0.5
ADMessagesManager.huds.message.posY = 0.09
ADMessagesManager.huds.message.headerOverlay = 0
ADMessagesManager.huds.message.headerOverlayHeight = 0.01
ADMessagesManager.huds.message.backgroundOverlay = 0
ADMessagesManager.huds.message.backgroundOverlayHeight = 0.05
ADMessagesManager.huds.message.dismissOverlay = 0
ADMessagesManager.huds.message.infoIconOverlay = 0
ADMessagesManager.huds.message.errorIconOverlay = 0
ADMessagesManager.huds.message.warnIconOverlay = 0

ADMessagesManager.huds.notification = {}
ADMessagesManager.huds.notification.text = ""
ADMessagesManager.huds.notification.textSize = 0.0135
ADMessagesManager.huds.notification.posX = 0.5
ADMessagesManager.huds.notification.posY = 0.92
ADMessagesManager.huds.notification.headerOverlay = 0
ADMessagesManager.huds.notification.headerOverlayHeight = 0.01
ADMessagesManager.huds.notification.backgroundOverlay = 0
ADMessagesManager.huds.notification.backgroundOverlayHeight = 0.05
ADMessagesManager.huds.notification.dismissOverlay = 0
ADMessagesManager.huds.notification.goToOverlay = 0
ADMessagesManager.huds.message.infoIconOverlay = 0
ADMessagesManager.huds.message.errorIconOverlay = 0
ADMessagesManager.huds.message.warnIconOverlay = 0

ADMessagesManager.huds.cpYOffset = 0			-- pay special attention when to use the offset for CP HUD or not !

function ADMessagesManager:load()
    self.messages = Queue:new()
    self.notifications = Queue:new()
    self:loadHud(self.huds.message)
    self:loadHud(self.huds.notification)
end

function ADMessagesManager:loadHud(hud)
    local textSize = getCorrectTextSize(hud.textSize)
    hud.headerOverlay = Overlay.new(AutoDrive.directory .. "textures/Header.dds", hud.posX, hud.posY + (textSize * 1.6), 0, hud.headerOverlayHeight)
    hud.headerOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_CENTER)
    hud.backgroundOverlay = Overlay.new(AutoDrive.directory .. "textures/messageBackground.dds", hud.posX, hud.posY + (textSize / 2.5), 0, hud.backgroundOverlayHeight)
    hud.backgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_CENTER)
    hud.dismissOverlay = Overlay.new(AutoDrive.directory .. "textures/input_toggleHud_1.dds", 0, hud.posY + (textSize * 1.5), hud.headerOverlayHeight * 1.2 / g_screenAspectRatio, hud.headerOverlayHeight * 1.2)
    hud.dismissOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_RIGHT)
    if hud.goToOverlay ~= nil then
        hud.goToOverlay = Overlay.new(AutoDrive.directory .. "textures/input_goTo_1.dds", 0, hud.posY + (textSize * 1.5), hud.headerOverlayHeight * 1.2 / g_screenAspectRatio, hud.headerOverlayHeight * 1.2)
        hud.goToOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_RIGHT)
    end
    hud.infoIconOverlay = Overlay.new(AutoDrive.directory .. "textures/info_icon.dds", 0, hud.posY + (textSize * 1.5), hud.headerOverlayHeight * 1.2 / g_screenAspectRatio, hud.headerOverlayHeight * 1.2)
    hud.infoIconOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_LEFT)
    hud.errorIconOverlay = Overlay.new(AutoDrive.directory .. "textures/error_icon.dds", 0, hud.posY + (textSize * 1.5), hud.headerOverlayHeight * 1.2 / g_screenAspectRatio, hud.headerOverlayHeight * 1.2)
    hud.errorIconOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_LEFT)
    hud.warnIconOverlay = Overlay.new(AutoDrive.directory .. "textures/warn_icon.dds", 0, hud.posY + (textSize * 1.5), hud.headerOverlayHeight * 1.2 / g_screenAspectRatio, hud.headerOverlayHeight * 1.2)
    hud.warnIconOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_LEFT)
end

function ADMessagesManager:addInfoMessage(text, duration)
    self:addMessage(self.messageTypes.INFO, text, duration)
end

function ADMessagesManager:addWarnMessage(text, duration)
    self:addMessage(self.messageTypes.WARN, text, duration)
end

function ADMessagesManager:addErrorMessage(text, duration)
    self:addMessage(self.messageTypes.ERROR, text, duration)
end

function ADMessagesManager:addMessage(messageType, text, duration)
    local exists = false
    if self.currentMessage ~= nil and self.currentMessage.messageType == messageType and self.currentMessage.text == text then
        exists = true
    end
    exists =
        exists or
        table.f_contains(
            self.messages:GetItems(),
            function(i)
                return i.messageType == messageType and i.text == text
            end
        )
    if not exists then
        self.messages:Enqueue({vehicle = g_currentMission.controlledVehicle, messageType = messageType, text = text, duration = duration})
    end
end

function ADMessagesManager:addNotification(vehicle, messageType, text, duration)
    if g_currentMission.controlledVehicle == vehicle then
        self:addMessage(messageType, text, duration)
    else
        local exists = false
        if self.currentNotification ~= nil and self.currentNotification.messageType == messageType and self.currentNotification.text == text and self.currentNotification.vehicle == vehicle then
            exists = true
        end
        exists =
            exists or
            table.f_contains(
                self.notifications:GetItems(),
                function(i)
                    return i.messageType == messageType and i.text == text and i.vehicle == vehicle
                end
            )
        if not exists then
            self.notifications:Enqueue({vehicle = vehicle, messageType = messageType, text = text, duration = duration})
        end
    end
end

function ADMessagesManager:removeCurrentMessage()
    self:addToHistory(self.currentMessage)
    self.currentMessage = nil
    self.currentMessageTimer = 0
end

function ADMessagesManager:removeCurrentNotification()
    self:addToHistory(self.currentNotification)
    self.currentNotification = nil
    self.currentNotificationTimer = 0
end

function ADMessagesManager:addToHistory(item)
    table.insert(self.history, 1, item)
    if AutoDrive.gui.ADNotificationsHistoryGui.isOpen then
        AutoDrive.gui.ADNotificationsHistoryGui:refreshItems()
    end
end

function ADMessagesManager:removeFromHistory(index)
    table.remove(self.history, index)
    if AutoDrive.gui.ADNotificationsHistoryGui.isOpen then
        AutoDrive.gui.ADNotificationsHistoryGui:refreshItems()
    end
end

function ADMessagesManager:clearHistory()
    self.history = {}
    if AutoDrive.gui.ADNotificationsHistoryGui.isOpen then
        AutoDrive.gui.ADNotificationsHistoryGui:refreshItems()
    end
end

function ADMessagesManager:getHistory()
    return self.history
end

function ADMessagesManager:update(dt)
    -- update cp offset
    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.cp ~= nil and g_currentMission.controlledVehicle.cp.hud ~= nil and g_currentMission.controlledVehicle.cp.hud.show then
        self.huds.cpYOffset = g_courseplay.courseplay.hud.baseHeight * 0.9
    else
        self.huds.cpYOffset = 0
    end

    -- messages handling
    if self.currentMessage == nil then
        self.currentMessage = self.messages:Dequeue()
        if self.currentMessage ~= nil then
            local nd = AutoDrive.getSetting("notifications")
            if nd ~= 0 then
                self.currentMessage.duration = self.currentMessage.duration * nd
                self:updateHud(self.huds.message, self.currentMessage.text, self.currentMessage.messageType)
            else
                self:removeCurrentMessage()
            end
        end
    else
        self.currentMessageTimer = self.currentMessageTimer + dt
        -- if we have more messages in queue we decrease their lifespan
        local lifeSpan = self.currentMessage.duration
        if self.messages:Count() > 0 then
            lifeSpan = lifeSpan / 2
        end
        if self.currentMessageTimer >= lifeSpan then
            self:removeCurrentMessage()
        end
    end

    -- notifications handling
    if self.currentNotification == nil then
        self.currentNotification = self.notifications:Dequeue()
        if self.currentNotification ~= nil then
            self.lastNotificationVehicle = self.currentNotification.vehicle
            local nd = AutoDrive.getSetting("notifications")
            if nd ~= 0 then
                self.currentNotification.duration = self.currentNotification.duration * nd
                self:updateHud(self.huds.notification, self.currentNotification.text, self.currentNotification.messageType)
            else
                self:removeCurrentNotification()
            end
        end
    else
        self.currentNotificationTimer = self.currentNotificationTimer + dt
        if self.currentNotificationTimer >= self.currentNotification.duration then
            self:removeCurrentNotification()
        end
    end
end

function ADMessagesManager:mouseEvent(posX, posY, isDown, isUp, button)
    if isUp and button == 1 then
        if self.currentMessage ~= nil then
            local ov = self.huds.message.dismissOverlay
            local x, y = ov:getPosition()
			y = y + self.huds.cpYOffset
            if posX >= x - ov.width and posY >= y and posX <= x and posY <= y + ov.height then
                self:removeCurrentMessage()
            end
        end
        if self.currentNotification ~= nil then
            local ov = self.huds.notification.dismissOverlay
            local x, y = ov:getPosition()
            if posX >= x - ov.width and posY >= y and posX <= x and posY <= y + ov.height then
                self:removeCurrentNotification()
            end
            ov = self.huds.notification.goToOverlay
            x, y = ov:getPosition()
            if posX >= x - ov.width and posY >= y and posX <= x and posY <= y + ov.height then
                self:goToVehicle()
                self:removeCurrentNotification()
            end
        end
    end
end

function ADMessagesManager:draw()
    if self.currentMessage ~= nil then
        self:drawHud(self.huds.message)
    end

    if self.currentNotification ~= nil then
        self:drawHud(self.huds.notification)
    end
end

function ADMessagesManager:drawHud(hud)
	local cpYOffset = 0
    if self.currentMessage ~= nil then
		cpYOffset = self.huds.cpYOffset
    end
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    renderText(hud.posX, hud.posY + cpYOffset, getCorrectTextSize(hud.textSize), hud.text)
    hud.backgroundOverlay.y = hud.backgroundOverlay.y + cpYOffset
    hud.backgroundOverlay:render()
    hud.backgroundOverlay.y = hud.backgroundOverlay.y - cpYOffset
    hud.headerOverlay.y = hud.headerOverlay.y + cpYOffset
    hud.headerOverlay:render()
    hud.headerOverlay.y = hud.headerOverlay.y - cpYOffset
    hud.dismissOverlay.y = hud.dismissOverlay.y + cpYOffset
    hud.dismissOverlay:render()
    hud.dismissOverlay.y = hud.dismissOverlay.y - cpYOffset
    if hud.goToOverlay ~= nil then
        hud.goToOverlay.y = hud.goToOverlay.y + cpYOffset
        hud.goToOverlay:render()
        hud.goToOverlay.y = hud.goToOverlay.y - cpYOffset
    end
    hud.infoIconOverlay.y = hud.infoIconOverlay.y + cpYOffset
    hud.infoIconOverlay:render()
    hud.infoIconOverlay.y = hud.infoIconOverlay.y - cpYOffset
    hud.warnIconOverlay.y = hud.warnIconOverlay.y + cpYOffset
    hud.warnIconOverlay:render()
    hud.warnIconOverlay.y = hud.warnIconOverlay.y - cpYOffset
    hud.errorIconOverlay.y = hud.errorIconOverlay.y + cpYOffset
    hud.errorIconOverlay:render()
    hud.errorIconOverlay.y = hud.errorIconOverlay.y - cpYOffset
end

function ADMessagesManager:updateHud(hud, text, mType)
    hud.text = text
    setTextBold(false)
    local textWidth = getTextWidth(getCorrectTextSize(hud.textSize), hud.text)
    hud.backgroundOverlay:setDimension(textWidth + 0.03, nil)
    hud.headerOverlay:setDimension(textWidth + 0.03, nil)
    hud.dismissOverlay:setPosition(hud.posX + ((textWidth + 0.03) / 2), nil)
    if hud.goToOverlay ~= nil then
        hud.goToOverlay:setPosition(hud.posX + ((textWidth + 0.01) / 2), nil)
    end
    hud.infoIconOverlay:setPosition(hud.posX - ((textWidth + 0.03) / 2), nil)
    hud.infoIconOverlay:setIsVisible(mType == self.messageTypes.INFO)
    hud.warnIconOverlay:setPosition(hud.posX - ((textWidth + 0.03) / 2), nil)
    hud.warnIconOverlay:setIsVisible(mType == self.messageTypes.WARN)
    hud.errorIconOverlay:setPosition(hud.posX - ((textWidth + 0.03) / 2), nil)
    hud.errorIconOverlay:setIsVisible(mType == self.messageTypes.ERROR)
end

function ADMessagesManager:goToVehicle()
    if self.lastNotificationVehicle ~= nil then
        g_currentMission:requestToEnterVehicle(self.lastNotificationVehicle)
    end
end
