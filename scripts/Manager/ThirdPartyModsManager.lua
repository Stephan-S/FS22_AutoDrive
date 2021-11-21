ADThirdPartyModsManager = {}
ADThirdPartyModsManager.mods = {}
ADThirdPartyModsManager.defaultRoutes = {}

function ADThirdPartyModsManager:load()
    local mods = g_modManager:getActiveMods()
    for _, mod in ipairs(mods) do
        local xmlFile = loadXMLFile("modDesc", mod.modFile)

        if xmlFile and hasXMLProperty(xmlFile, "modDesc.autoDrive") then
            self:loadMod(mod, xmlFile)
            delete(xmlFile)
        end
    end
end

---Load a third party mod
function ADThirdPartyModsManager:loadMod(mod, xmlFile)
    local modInfo = {}
    modInfo.mod = mod
    modInfo.modType = "DefaultRoutes"

    local routesFolder = getXMLString(xmlFile, "modDesc.autoDrive#routesFolder")
    if routesFolder ~= nil then
        local modDir = mod.modDir:sub(1, -2)
        if not StringUtil.startsWith(routesFolder, "/") then
            routesFolder = "/" .. routesFolder
        end
        if not StringUtil.endsWith(routesFolder, "/") then
            routesFolder = routesFolder .. "/"
        end
        modInfo.routesFolder = modDir .. routesFolder
        self:loadDefaultRoutesMod(mod, xmlFile, modInfo.routesFolder)
    end

    table.insert(self.mods, modInfo)
end

function ADThirdPartyModsManager:loadDefaultRoutesMod(mod, xmlFile, routesFolder)
    local i = 0
    while true do
        local xmlKey = string.format("modDesc.autoDrive.routes.route(%d)", i)
        if not hasXMLProperty(xmlFile, xmlKey) then
            break
        end
        local mapName = getXMLString(xmlFile, xmlKey .. "#mapName")
        local fileName = getXMLString(xmlFile, xmlKey .. "#fileName")
        if mapName ~= nil and fileName ~= nil then
            self.defaultRoutes[mapName] = routesFolder .. fileName
        end
        i = i + 1
    end
end

function ADThirdPartyModsManager:getHasDefaultRoutesForMap(mapName)
    return self.defaultRoutes[mapName] ~= nil
end

function ADThirdPartyModsManager:getDefaultRoutesForMap(mapName)
    return self.defaultRoutes[mapName]
end
