ADDrawingManager = {}
ADDrawingManager.i3DBaseDir = "drawing/"
ADDrawingManager.yOffset = 0
ADDrawingManager.emittivity = 0
ADDrawingManager.emittivityNextUpdate = 0
ADDrawingManager.debug = {}

ADDrawingManager.lines = {}
ADDrawingManager.lines.fileName = "line.i3d"
ADDrawingManager.lines.buffer = Buffer:new()
ADDrawingManager.lines.objects = FlaggedTable:new()
ADDrawingManager.lines.tasks = {}
ADDrawingManager.lines.itemIDs = {}
ADDrawingManager.lines.lastDrawZero = true

ADDrawingManager.arrows = {}
ADDrawingManager.arrows.fileName = "arrow.i3d"
ADDrawingManager.arrows.buffer = Buffer:new()
ADDrawingManager.arrows.objects = FlaggedTable:new()
ADDrawingManager.arrows.tasks = {}
ADDrawingManager.arrows.itemIDs = {}
ADDrawingManager.arrows.lastDrawZero = true
ADDrawingManager.arrows.position = {}
ADDrawingManager.arrows.position.start = 1
ADDrawingManager.arrows.position.middle = 2

ADDrawingManager.sSphere = {}
ADDrawingManager.sSphere.fileName = "sphere_small.i3d"
ADDrawingManager.sSphere.buffer = Buffer:new()
ADDrawingManager.sSphere.objects = FlaggedTable:new()
ADDrawingManager.sSphere.tasks = {}
ADDrawingManager.sSphere.itemIDs = {}
ADDrawingManager.sSphere.lastDrawZero = true

ADDrawingManager.sphere = {}
ADDrawingManager.sphere.fileName = "sphere.i3d"
ADDrawingManager.sphere.buffer = Buffer:new()
ADDrawingManager.sphere.objects = FlaggedTable:new()
ADDrawingManager.sphere.tasks = {}
ADDrawingManager.sphere.itemIDs = {}
ADDrawingManager.sphere.lastDrawZero = true

ADDrawingManager.markers = {}
ADDrawingManager.markers.fileNames = {}
ADDrawingManager.markers.fileNames[1] = "marker.i3d"
ADDrawingManager.markers.fileNames[2] = "marker_2.i3d"
ADDrawingManager.markers.fileNames[3] = "marker_3.i3d"
ADDrawingManager.markers.buffer = Buffer:new()
ADDrawingManager.markers.objects = FlaggedTable:new()
ADDrawingManager.markers.tasks = {}
ADDrawingManager.markers.itemIDs = {}
ADDrawingManager.markers.lastDrawZero = true
ADDrawingManager.markers.lastDrawFileUsed = 1
ADDrawingManager.markers.usesSelection = true

ADDrawingManager.cross = {}
ADDrawingManager.cross.fileName = "cross.i3d"
ADDrawingManager.cross.buffer = Buffer:new()
ADDrawingManager.cross.objects = FlaggedTable:new()
ADDrawingManager.cross.tasks = {}
ADDrawingManager.cross.itemIDs = {}
ADDrawingManager.cross.lastDrawZero = true

function ADDrawingManager:load()
    -- preloading and storing in chache I3D files
    self.i3DBaseDir = AutoDrive.directory .. self.i3DBaseDir
-- local node, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(self.i3dFilename, false, false)
    g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. self.lines.fileName, false, false)
    g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. self.arrows.fileName, false, false)
    g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. self.sSphere.fileName, false, false)
    g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. self.sphere.fileName, false, false)
    for _, filename in ipairs(self.markers.fileNames) do
        g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. filename, false, false)
    end
end

function ADDrawingManager.initObject(id)
    local itemId = getChildAt(id, 0)
    link(getRootNode(), itemId)
    setRigidBodyType(itemId, "NoRigidBody")
    setTranslation(itemId, 0, 0, 0)
    setVisibility(itemId, false)
    delete(id)
    return itemId
end

function ADDrawingManager:addLineTask(sx, sy, sz, ex, ey, ez, r, g, b)
    -- storing task
    local hash = 0
    -- local hash = string.format("l%.2f%.2f%.2f%.2f%.2f%.2f%.2f%.2f%.2f%.1f", sx, sy, sz, ex, ey, ez, r, g, b, self.yOffset)
    table.insert(self.lines.tasks, {sx = sx, sy = sy, sz = sz, ex = ex, ey = ey, ez = ez, r = r, g = g, b = b, hash = hash})
end

function ADDrawingManager:addArrowTask(sx, sy, sz, ex, ey, ez, position, r, g, b)
    -- storing task
    local hash = 0
    -- local hash = string.format("a%.2f%.2f%.2f%.2f%.2f%.2f%d%.2f%.2f%.2f%.1f", sx, sy, sz, ex, ey, ez, position, r, g, b, self.yOffset)
    table.insert(self.arrows.tasks, {sx = sx, sy = sy, sz = sz, ex = ex, ey = ey, ez = ez, r = r, g = g, b = b, position = position, hash = hash})
end

function ADDrawingManager:addSmallSphereTask(x, y, z, r, g, b)
    -- storing task
    local hash = 0
    -- local hash = string.format("ss%.2f%.2f%.2f%.2f%.2f%.2f%.1f", x, y, z, r, g, b, self.yOffset)
    table.insert(self.sSphere.tasks, {x = x, y = y, z = z, r = r, g = g, b = b, hash = hash})
end

function ADDrawingManager:addMarkerTask(x, y, z)
    -- storing task
    local hash = 0
    -- local hash = string.format("m%.2f%.2f%.2f%.1f", x, y, z, self.yOffset)
    table.insert(self.markers.tasks, {x = x, y = y, z = z, hash = hash})
end

function ADDrawingManager:addCrossTask(x, y, z)
    -- storing task
    local hash = 0
    -- local hash = string.format("c%.2f%.2f%.2f%.1f", x, y, z, self.yOffset)
    table.insert(self.cross.tasks, {x = x, y = y, z = z, hash = hash})
end

function ADDrawingManager:addSphereTask(x, y, z, scale, r, g, b, a)
    scale = scale or 1
    a = a or 0
    -- storing task
    local hash = 0
    -- local hash = string.format("s%.2f%.2f%.2f%.3f%.2f%.2f%.2f%.2f%.1f", x, y, z, scale, r, g, b, a, self.yOffset)
    table.insert(self.sphere.tasks, {x = x, y = y, z = z, r = r, g = g, b = b, a = a, scale = scale, hash = hash})
end

function ADDrawingManager:draw()
    local time = netGetTime()
    local ad = AutoDrive
    self.yOffset = ad.drawHeight + ad.getSetting("lineHeight")

    -- update emittivity only once every 600 frames
    if self.emittivityNextUpdate <= 0 then
        local r, g, b = getLightColor(g_currentMission.environment.sunLightId)
        local light = (r + g + b) / 3
        self.emittivity = 1 - light
        if self.emittivity > 0.9 then
            -- enable glow
            self.emittivity = self.emittivity * 0.5
        end
        self.emittivityNextUpdate = 600
    else
        self.emittivityNextUpdate = self.emittivityNextUpdate - 1
    end
    self.debug["Emittivity"] = self.emittivity

    local tTime = netGetTime()
    self.debug["Lines"] = self:drawObjects(self.lines, self.drawLine, self.initObject)
    self.debug["Lines"].Time = netGetTime() - tTime

    tTime = netGetTime()
    self.debug["Arrows"] = self:drawObjects(self.arrows, self.drawArrow, self.initObject)
    self.debug["Arrows"].Time = netGetTime() - tTime

    tTime = netGetTime()
    self.debug["sSphere"] = self:drawObjects(self.sSphere, self.drawSmallSphere, self.initObject)
    self.debug["sSphere"].Time = netGetTime() - tTime

    tTime = netGetTime()
    self.debug["Sphere"] = self:drawObjects(self.sphere, self.drawSphere, self.initObject)
    self.debug["Sphere"].Time = netGetTime() - tTime

    tTime = netGetTime()
    self.debug["Markers"] = self:drawObjects(self.markers, self.drawMarker, self.initObject)
    self.debug["Markers"].Time = netGetTime() - tTime

    tTime = netGetTime()
    self.debug["Cross"] = self:drawObjects(self.cross, self.drawCross, self.initObject)
    self.debug["Cross"].Time = netGetTime() - tTime

    self.debug["TotalTime"] = netGetTime() - time
    if AutoDrive.getDebugChannelIsSet(AutoDrive.DC_RENDERINFO) then
        AutoDrive.renderTable(0.6, 0.7, 0.012, self.debug, 5)
    end
end

function ADDrawingManager:drawObjects_alternative(obj, dFunc, iFunc)
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects start...")
    local taskCount = #obj.tasks
    local stats = {}
    stats["Tasks"] = {Total = taskCount}
    stats["itemIDs"] = {Total = #obj.itemIDs}

    if taskCount > 0 or obj.lastDrawZero == false then
        -- set all invisible
        for _, itemID in ipairs (obj.itemIDs) do
    -- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects setVisibility itemID %s ", tostring(itemID))
            setVisibility(itemID, false)
        end
    end

    if taskCount == 0 then -- nothing to draw
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects nothing to draw ")
        obj.lastDrawZero = true
        return stats
    end

    local fileToUse
    if obj.usesSelection then
        local iconSetToUse = AutoDrive.getSetting("iconSetToUse")
        fileToUse = obj.fileNames[iconSetToUse]
    else
        fileToUse = obj.fileName
    end
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects fileToUse %s ", tostring(fileToUse))

-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects taskCount %s #obj.itemIDs %s ", tostring(taskCount), tostring(#obj.itemIDs))
    -- check if enougth objects are available - add missing amount
    if taskCount > #obj.itemIDs then
        for i = 1, taskCount - #obj.itemIDs do
            -- loading new i3ds
-- local node, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(self.i3dFilename, false, false)
            local _, itemID = g_i3DManager:loadSharedI3DFile(fileToUse, self.i3DBaseDir)
            setVisibility(itemID, false)
            table.insert(obj.itemIDs,iFunc(itemID))
        end
    end
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects taskCount %s #obj.itemIDs %s ", tostring(taskCount), tostring(#obj.itemIDs))

-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects drawing... ")
    -- drawing tasks
    local index = 1
    for _, task in pairs(obj.tasks) do
        local itemId = obj.itemIDs[index]
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects index %s itemId %s ", tostring(index), tostring(itemId))
        dFunc(self, itemId, task)
        index = index + 1
    end
    obj.tasks = {}
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects end ")
    obj.lastDrawZero = taskCount == 0
    return stats
end

function ADDrawingManager:drawObjects_original(obj, dFunc, iFunc)
    local taskCount = #obj.tasks

    local fileToUse
    if obj.usesSelection then
        if obj.lastDrawFileUsed ~= AutoDrive.getSetting("iconSetToUse") then
            -- cleaning up not needed objects and send them back to the buffer
            obj.objects:ResetFlags()
            local unusedObjects = obj.objects:RemoveUnflagged()
            for _, id in pairs(unusedObjects) do
                -- make invisible unused items
                setVisibility(id, false)
                obj.buffer:Insert(id)
            end
            obj.buffer = Buffer:new()
        end
        fileToUse = obj.fileNames[AutoDrive.getSetting("iconSetToUse")]
        obj.lastDrawFileUsed = AutoDrive.getSetting("iconSetToUse")
    else
        fileToUse = obj.fileName
    end

    local stats = {}
    stats["Tasks"] = {Total = taskCount, Performed = 0, Skipped = 0}
    stats["Objects"] = obj.objects:Count()
    stats["Buffer"] = obj.buffer:Count()

    -- this will prevent to run when there is nothing to draw but it also ensure to run one last time to set objects visibility to false
    if taskCount > 0 or obj.lastDrawZero == false then
        -- skipping already drawn objects (the goal is to find out the objects that have already been drawn and don't redraw them again but at the same time hide the objects that have not to be draw again and also draw the new ones) :D

        local taskSkippedCount = 0
        obj.objects:ResetFlags()
        for i, t in pairs(obj.tasks) do
            if obj.objects:Contains(t.hash) then
                -- removing the task if this object is aready drawn
                obj.tasks[i] = nil
                obj.objects:Flag(t.hash)
                taskSkippedCount = taskSkippedCount + 1
            end
        end
        local remainingTaskCount = taskCount - taskSkippedCount
        stats.Tasks.Performed = remainingTaskCount
        stats.Tasks.Skipped = taskSkippedCount

        -- cleaning up not needed objects and send them back to the buffer
        local unusedObjects = obj.objects:RemoveUnflagged()

        for _, id in pairs(unusedObjects) do
            -- make invisible unused items
            setVisibility(id, false)
            obj.buffer:Insert(id)
        end

        -- adding missing objects to buffer
        local bufferCount = obj.buffer:Count()
        if remainingTaskCount > bufferCount then
            local baseDir = self.i3DBaseDir
            for i = 1, remainingTaskCount - bufferCount do
                -- loading new i3ds
-- local node, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(self.i3dFilename, false, false)
                local _, id = g_i3DManager:loadSharedI3DFile(fileToUse, baseDir)
                obj.buffer:Insert(iFunc(id))
            end
        end

        -- drawing tasks
        for _, task in pairs(obj.tasks) do
            -- moving object from the buffer to the hashes table
            if obj.objects:Contains(task.hash) == false then
                local oId = obj.buffer:Get()
                obj.objects:Add(task.hash, oId)
                dFunc(self, oId, task)
            end
        end
        obj.tasks = {}
    end
    obj.lastDrawZero = taskCount <= 0
    return stats
end

function ADDrawingManager:drawObjects(obj, dFunc, iFunc)
    return self:drawObjects_alternative(obj, dFunc, iFunc)
    -- return self:drawObjects_original(obj, dFunc, iFunc)
end

function ADDrawingManager:drawLine(id, task)
    local atan2 = math.atan2

    -- Get the direction to the end point
    local dirX, _, dirZ, distToNextPoint = AutoDrive.getWorldDirection(task.sx, task.sy, task.sz, task.ex, task.ey, task.ez)

    -- Get Y rotation
    local rotY = atan2(dirX, dirZ)

    -- Get X rotation
    local dy = task.ey - task.sy
    local dist2D = MathUtil.vector2Length(task.ex - task.sx, task.ez - task.sz)
    local rotX = -atan2(dy, dist2D)

    setTranslation(id, task.sx, task.sy + self.yOffset, task.sz)

    setScale(id, 1, 1, distToNextPoint)

    -- Set the direction of the line
    setRotation(id, rotX, rotY, 0)

    -- Update line color
    setShaderParameter(id, "color", task.r, task.g, task.b, self.emittivity, false)

    -- Update line visibility
    setVisibility(id, true)
end

function ADDrawingManager:drawArrow(id, task)
    local atan2 = math.atan2

    local x = task.ex
    local y = task.ey
    local z = task.ez

    if task.position == self.arrows.position.middle then
        x = (x + task.sx) / 2
        y = (y + task.sy) / 2
        z = (z + task.sz) / 2
    end

    -- Get the direction to the end point
    local dirX, _, dirZ, _ = AutoDrive.getWorldDirection(task.sx, task.sy, task.sz, task.ex, task.ey, task.ez)

    -- Get Y rotation
    local rotY = atan2(dirX, dirZ)

    -- Get X rotation
    local dy = task.ey - task.sy
    local dist2D = MathUtil.vector2Length(task.ex - task.sx, task.ez - task.sz)
    local rotX = -atan2(dy, dist2D)

    setTranslation(id, x, y + self.yOffset, z)

    -- Set the direction of the arrow
    setRotation(id, rotX, rotY, 0)

    -- Update arrow color
    setShaderParameter(id, "color", task.r, task.g, task.b, self.emittivity, false)

    -- Update arrow visibility
    setVisibility(id, true)
end

function ADDrawingManager:drawSmallSphere(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    setShaderParameter(id, "color", task.r, task.g, task.b, self.emittivity, false)
    setVisibility(id, true)
end

function ADDrawingManager:drawMarker(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    setVisibility(id, true)
end

function ADDrawingManager:drawCross(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    setVisibility(id, true)
end

function ADDrawingManager:drawSphere(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    setScale(id, task.scale, task.scale, task.scale)
    setShaderParameter(id, "color", task.r, task.g, task.b, self.emittivity + task.a, false)
    setVisibility(id, true)
end
