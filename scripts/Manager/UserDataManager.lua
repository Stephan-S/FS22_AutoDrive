ADUserDataManager = {}

ADUserDataManager.users = {}

function ADUserDataManager:getUserByConnection(connection)
    return g_currentMission.userManager:getUserByConnection(connection)
end

function ADUserDataManager:getUserIdByConnection(connection)
    local user = self:getUserByConnection(connection)
    if user ~= nil then
        return user.uniqueUserId
    else
        return nil
    end
end

function ADUserDataManager:getUserSettingNames()
    local settings = {}
    for settingName, setting in pairs(AutoDrive.settings) do
        if setting.isUserSpecific then
            table.insert(settings, settingName)
        end
    end
    return settings
end

function ADUserDataManager:load()
    self.userSettingNames = self:getUserSettingNames()
end

function ADUserDataManager:loadFromXml()
    local userCount = 0
    local file = tostring(g_currentMission.missionInfo.savegameDirectory) .. "/AutoDriveUsersData.xml"
    if fileExists(file) then
        local xmlFile = loadXMLFile("AutoDriveUsersData_XML_temp", file)
        if xmlFile ~= nil then
            local uIndex = 0
            while true do
                local uKey = string.format("AutoDriveUsersData.users.user(%d)", uIndex)
                if not hasXMLProperty(xmlFile, uKey) then
                    break
                end
                local uniqueId = getXMLString(xmlFile, uKey .. "#uniqueId")
                if uniqueId ~= nil and uniqueId ~= "" then
                    self.users[uniqueId] = {}
                    self.users[uniqueId].hudX = Utils.getNoNil(getXMLFloat(xmlFile, uKey .. "#hudX"), AutoDrive.HudX or 0.5)
                    self.users[uniqueId].hudY = Utils.getNoNil(getXMLFloat(xmlFile, uKey .. "#hudY"), AutoDrive.HudY or 0.5)
                    self.users[uniqueId].settings = {}
                    for _, sn in pairs(self.userSettingNames) do
                        self.users[uniqueId].settings[sn] = Utils.getNoNil(getXMLInt(xmlFile, uKey .. "#" .. sn), AutoDrive.getSettingState(sn))
                    end
                    userCount = userCount + 1
                end
                uIndex = uIndex + 1
            end
            Logging.info("[AD] ADUserDataManager: loaded data for %d users", userCount)
        end
        delete(xmlFile)
    end
end

function ADUserDataManager:userConnected(connection)
    local userId = self:getUserIdByConnection(connection)
    if userId ~= nil and self.users[userId] == nil then
        self.users[userId] = {}
        self.users[userId].hudX = AutoDrive.HudX or 0.5
        self.users[userId].hudY = AutoDrive.HudY or 0.5
        self.users[userId].settings = {}
        for _, sn in pairs(self.userSettingNames) do
            self.users[userId].settings[sn] = AutoDrive.getSettingState(sn)
        end
        Logging.info("[AD] ADUserDataManager: user ID %s connected", tostring(userId))
    end
end

function ADUserDataManager:saveToXml()
    local file = g_currentMission.missionInfo.savegameDirectory .. "/AutoDriveUsersData.xml"
    local xmlFile = createXMLFile("AutoDriveUsersData_XML_temp", file, "AutoDriveUsersData")
    local uIndex = 0
    for uniqueId, userData in pairs(self.users) do
        local uKey = string.format("AutoDriveUsersData.users.user(%d)", uIndex)
        setXMLString(xmlFile, uKey .. "#uniqueId", uniqueId)
        setXMLFloat(xmlFile, uKey .. "#hudX", userData.hudX)
        setXMLFloat(xmlFile, uKey .. "#hudY", userData.hudY)

        for sn, sv in pairs(userData.settings) do
            setXMLInt(xmlFile, uKey .. "#" .. sn, sv)
        end
        uIndex = uIndex + 1
    end
    Logging.info("[AD] ADUserDataManager: saved data for %d users", uIndex)
    saveXMLFile(xmlFile)
    delete(xmlFile)
end

function ADUserDataManager:sendToServer()
    local settings = {}
    for _, sn in pairs(self.userSettingNames) do
        settings[sn] = AutoDrive.getSettingState(sn)
    end
    AutoDriveUserDataEvent.sendToServer(AutoDrive.HudX, AutoDrive.HudY, settings)
end

function ADUserDataManager:updateUserSettings(connection, hudX, hudY, settings)
    local userId = self:getUserIdByConnection(connection)
    if userId ~= nil then
        self.users[userId] = {}
        self.users[userId].hudX = hudX
        self.users[userId].hudY = hudY
        self.users[userId].settings = settings
        Logging.info("[AD] ADUserDataManager: update user settings ID %s", tostring(userId))
    end
end

function ADUserDataManager:sendToClient(connection)
    local userId = self:getUserIdByConnection(connection)
    if userId ~= nil then
        Logging.info("[AD] ADUserDataManager: send user settings ID %s to client", tostring(userId))
        AutoDriveUserDataEvent.sendToClient(connection, self.users[userId].hudX, self.users[userId].hudY, self.users[userId].settings)
    end
end

function ADUserDataManager:applyUserSettings(hudX, hudY, settings)
    Logging.info("[AD] ADUserDataManager: apply user settings")
    AutoDrive.Hud:createHudAt(hudX, hudY)
    for sn, sv in pairs(settings) do
        AutoDrive.setSettingState(sn, sv)
    end
end
