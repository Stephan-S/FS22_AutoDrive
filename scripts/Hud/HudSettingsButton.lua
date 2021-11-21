ADHudSettingsButton = ADInheritsFrom(ADGenericHudElement)

function ADHudSettingsButton:new(posX, posY, width, height, setting, toolTip, state, visible)
    local o = ADHudSettingsButton:create()
    o:init(posX, posY, width, height)
    o.setting = setting
    o.toolTip = toolTip
    o.state = state
    o.isVisible = visible

    o.layer = 5

    o.images = o:readImages()

AutoDrive.debugMsg(nil, "[AD] ADHudSettingsButton:new o.state %s type o.images[o.state] %s", tostring(o.state), type(o.images[o.state]))
    -- o.ov = Overlay:new(o.images[o.state], o.position.x, o.position.y, o.size.width, o.size.height)

    return o
end

function ADHudSettingsButton:readImages()
    local images = {}
    local counter = 1
    while counter <= 4 do
        images[counter] = AutoDrive.directory .. "textures/" .. self.setting .. "_" .. counter .. ".dds"
        counter = counter + 1
    end
    return images
end

function ADHudSettingsButton:onDraw(vehicle, uiScale)
    self:updateState(vehicle)
    if self.isVisible and self.ov ~= nil then
        self.ov:render()
    end
end

function ADHudSettingsButton:updateState(vehicle)
    local newState = AutoDrive.getSettingState(self.setting, vehicle)
    self.isVisible = not AutoDrive.isEditorModeEnabled() or AutoDrive.getSetting("wideHUD")
    if self.ov ~= nil then
        self.ov:setImage(self.images[newState])
    end
    self.state = newState
end

function ADHudSettingsButton:act(vehicle, posX, posY, isDown, isUp, button)
    if self.isVisible then
        vehicle.ad.sToolTip = self.toolTip
        vehicle.ad.nToolTipWait = 5
        vehicle.ad.sToolTipInfo = nil
        vehicle.ad.toolTipIsSetting = true

        if button == 1 and isUp then
            local currentState = AutoDrive.getSettingState(self.setting, vehicle)
            currentState = (currentState + 1)
            if currentState > table.count(AutoDrive.settings[self.setting].values) then
                currentState = 1
            end
            AutoDrive.setSettingState(self.setting, currentState, vehicle)
            AutoDriveUpdateSettingsEvent.sendEvent(vehicle)
        end
    end

    return false
end
