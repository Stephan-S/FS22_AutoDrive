ADRoutesManager = {}

ADRoutesManager.routes = {}
ADRoutesManager.rootFolder = ""
ADRoutesManager.managerFolder = ""
ADRoutesManager.routesFolder = ""
ADRoutesManager.xmlFile = ""
ADRoutesManager.xml = nil

ADRoutesManager.cfnTimer = 0
ADRoutesManager.cfnInterval = 1000
ADRoutesManager.cfnFile = ""

function ADRoutesManager:load()
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end

    addConsoleCommand("adExportRoutesAsExternalMod", "Gives you the basic files to create an 'AutoDrive routes mod'", "exportRoutesAsExternalMod", self)

    -- defining and creating needed folders
    self.settingsFolder = getUserProfileAppPath() .. "modSettings/"
    createFolder(self.settingsFolder)
    self.rootFolder = self.settingsFolder .. "FS22_AutoDrive/"
    createFolder(self.rootFolder)
    self.managerFolder = self.rootFolder .. "routesManager/"
    createFolder(self.managerFolder)
    self.routesFolder = self.managerFolder .. "routes/"
    createFolder(self.routesFolder)

    self.cfnFile = self.managerFolder .. "reload.cfn"

    self:loadRoutesFromXML()
end

function ADRoutesManager:loadRoutesFromXML()
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end
    self:delete()
    self.routes = {}
    self.xmlFile = self.managerFolder .. "routes.xml"
    if fileExists(self.xmlFile) then
        self.xml = loadXMLFile("RoutesManager_xml", self.xmlFile)
        -- loading routes
        local i = 0
        while true do
            local key = string.format("autoDriveRoutesManager.routes.route(%d)", i)
            if not hasXMLProperty(self.xml, key) then
                break
            end
            local name = getXMLString(self.xml, key .. "#name")
            local fileName = getXMLString(self.xml, key .. "#fileName")
            local map = getXMLString(self.xml, key .. "#map")
            local revision = getXMLInt(self.xml, key .. "#revision")
            local date = getXMLString(self.xml, key .. "#date")
            local serverId = getXMLString(self.xml, key .. ".serverId") or ""
            i = i + 1
            self.routes[i] = {name = name, fileName = fileName, map = map, revision = revision, date = date, serverId = serverId}
        end
    else
        self.xml = createXMLFile("RoutesManager_xml", self.xmlFile, "autoDriveRoutesManager")
        saveXMLFile(self.xml)
    end
end

function ADRoutesManager:update(dt)
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end
    self.cfnTimer = self.cfnTimer + dt
    if self.cfnTimer >= self.cfnInterval then
        if fileExists(self.cfnFile) then
            getfenv(0).deleteFile(self.cfnFile)
            self:loadRoutesFromXML()
            if g_gui.currentGuiName == AutoDrive.gui.ADRoutesManagerGui.name then
                AutoDrive.gui.ADRoutesManagerGui:refreshItems()
            end
        end
        self.cfnTimer = 0
    end
end

function ADRoutesManager:import(name)
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end
    local route =
        table.f_find(
        self.routes,
        function(v)
            return v.name == name
        end
    )
    if route ~= nil then
        if fileExists(self.routesFolder .. route.fileName) then
            local loadXml = loadXMLFile("routeImport_xml", self.routesFolder .. route.fileName)
            local wayPoints, mapMarkers, groups = AutoDrive.readGraphFromXml(loadXml, "routeExport")
            delete(loadXml)
            AutoDriveRoutesUploadEvent.sendEvent(wayPoints, mapMarkers, groups)
        end
    end
end

function ADRoutesManager:export(name)
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end
    local fileName = self:getFileName()
    if name == nil or name == "" then
        name = fileName
    end
    fileName = fileName .. ".xml"

    local route = nil
    local saveXml = -1
    local mapName = AutoDrive.loadedMap
    local routeIndex =
        table.f_indexOf(
        self.routes,
        function(v)
            return v.name == name and v.map == mapName
        end
    )

    -- saving route to xml, if a route with the same name and map already exists, overwrite it
    if routeIndex ~= nil then
        route = self.routes[routeIndex]
        route.revision = route.revision + 1
        route.date = getDate("%Y/%m/%d %H:%M:%S")
        saveXml = loadXMLFile("routeExport_xml", self.routesFolder .. route.fileName)
    else
        route = {name = name, fileName = fileName, map = mapName, revision = 1, date = getDate("%Y/%m/%d %H:%M:%S"), serverId = ""}
        table.insert(self.routes, route)
        saveXml = createXMLFile("routeExport_xml", self.routesFolder .. fileName, "routeExport")
    end

    AutoDrive.writeGraphToXml(saveXml, "routeExport", ADGraphManager:getWayPoints(), ADGraphManager:getMapMarkers(), ADGraphManager:getGroups())

    saveXMLFile(saveXml)
    delete(saveXml)

    self:saveRoutes()
end

function ADRoutesManager:remove(name)
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end
    local mapName = AutoDrive.loadedMap
    local routeIndex =
        table.f_indexOf(
        self.routes,
        function(v)
            return v.name == name and v.map == mapName
        end
    )

    if routeIndex ~= nil then
        local route = table.remove(self.routes, routeIndex)
        getfenv(0).deleteFile(self.routesFolder .. route.fileName)
        self:saveRoutes()
    end
end

function ADRoutesManager:getFileName()
    local fileName = string.random(16)
    -- finding a not used file name
    while fileExists(self.routesFolder .. fileName .. ".xml") do
        fileName = string.random(16)
    end
    return fileName
end

function ADRoutesManager:saveRoutes()
    if g_currentMission:getIsClient() and not g_currentMission:getIsServer() and not g_currentMission.isMasterUser then
        return
    end
    -- updating routes.xml
    removeXMLProperty(self.xml, "autoDriveRoutesManager.routes")
    for i, route in pairs(self.routes) do
        local key = string.format("autoDriveRoutesManager.routes.route(%d)", i - 1)
        removeXMLProperty(self.xml, key)
        setXMLString(self.xml, key .. "#name", route.name)
        setXMLString(self.xml, key .. "#fileName", route.fileName)
        setXMLString(self.xml, key .. "#map", route.map)
        setXMLInt(self.xml, key .. "#revision", route.revision)
        setXMLString(self.xml, key .. "#date", route.date)
        setXMLString(self.xml, key .. ".serverId", route.serverId)
    end
    saveXMLFile(self.xml)
end

function ADRoutesManager:getRoutes(map)
    return table.f_filter(
        self.routes,
        function(v)
            return v.map == map
        end
    )
end

function ADRoutesManager:delete()
    if self.xml ~= nil then
        delete(self.xml)
    end
end

function ADRoutesManager:exportRoutesAsExternalMod()
    local mapName = AutoDrive.loadedMap
    local exportRootFolder = string.format("%sFS22_AutoDrive_Routes_%s/", self.rootFolder, mapName)
    createFolder(exportRootFolder)
    local exportRoutesFolder = string.format("%sroutes/", exportRootFolder)
    createFolder(exportRoutesFolder)

    local mdXml = createXMLFile("modDesc_xml", exportRootFolder .. "modDesc.xml", "modDesc")
    setXMLString(mdXml, "modDesc.autoDrive#routesFolder", "routes/")
    setXMLString(mdXml, "modDesc.autoDrive#routesFolder", "routes/")
    setXMLString(mdXml, "modDesc.autoDrive.routes.route(0)#mapName", mapName)
    setXMLString(mdXml, "modDesc.autoDrive.routes.route(0)#fileName", mapName .. ".xml")
    saveXMLFile(mdXml)
    delete(mdXml)

    local rXml = createXMLFile("modDesc_xml", exportRoutesFolder .. mapName .. ".xml", "defaultRoutes")
    AutoDrive.writeGraphToXml(rXml, "defaultRoutes", ADGraphManager:getWayPoints(), ADGraphManager:getMapMarkers(), ADGraphManager:getGroups())
    saveXMLFile(rXml)
    delete(rXml)

    print(string.format("[AD] Files exported to '%s'", exportRootFolder))
end
