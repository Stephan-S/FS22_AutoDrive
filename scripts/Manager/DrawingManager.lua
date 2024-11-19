ADDrawingManager = {}
ADDrawingManager.enableDebug = false
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
ADDrawingManager.lines.lastTaskCount = 0
ADDrawingManager.lines.currentTask = 0
ADDrawingManager.lines.itemIDs = {}
ADDrawingManager.lines.lastDrawZero = true

ADDrawingManager.arrows = {}
ADDrawingManager.arrows.fileName = "arrow.i3d"
ADDrawingManager.arrows.buffer = Buffer:new()
ADDrawingManager.arrows.objects = FlaggedTable:new()
ADDrawingManager.arrows.tasks = {}
ADDrawingManager.arrows.lastTaskCount = 0
ADDrawingManager.arrows.currentTask = 0
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
ADDrawingManager.sSphere.lastTaskCount = 0
ADDrawingManager.sSphere.currentTask = 0
ADDrawingManager.sSphere.itemIDs = {}
ADDrawingManager.sSphere.lastDrawZero = true

ADDrawingManager.sphere = {}
ADDrawingManager.sphere.fileName = "sphere.i3d"
ADDrawingManager.sphere.buffer = Buffer:new()
ADDrawingManager.sphere.objects = FlaggedTable:new()
ADDrawingManager.sphere.tasks = {}
ADDrawingManager.sphere.lastTaskCount = 0
ADDrawingManager.sphere.currentTask = 0
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
ADDrawingManager.markers.lastTaskCount = 0
ADDrawingManager.markers.currentTask = 0
ADDrawingManager.markers.itemIDs = {}
ADDrawingManager.markers.lastDrawZero = true
ADDrawingManager.markers.lastDrawFileUsed = 1
ADDrawingManager.markers.usesSelection = true

ADDrawingManager.cross = {}
ADDrawingManager.cross.fileName = "cross.i3d"
ADDrawingManager.cross.buffer = Buffer:new()
ADDrawingManager.cross.objects = FlaggedTable:new()
ADDrawingManager.cross.tasks = {}
ADDrawingManager.cross.lastTaskCount = 0
ADDrawingManager.cross.currentTask = 0
ADDrawingManager.cross.itemIDs = {}
ADDrawingManager.cross.lastDrawZero = true

function ADDrawingManager:load()
    -- preloading and storing in chache I3D files
    self.i3DBaseDir = AutoDrive.directory .. self.i3DBaseDir
    g_i3DManager:loadSharedI3DFileAsync(self.i3DBaseDir .. self.lines.fileName, false, false, self.loadedi3d, self, nil)
    g_i3DManager:loadSharedI3DFileAsync(self.i3DBaseDir .. self.arrows.fileName, false, false, self.loadedi3d, self, nil)
    g_i3DManager:loadSharedI3DFileAsync(self.i3DBaseDir .. self.sSphere.fileName, false, false, self.loadedi3d, self, nil)
    g_i3DManager:loadSharedI3DFileAsync(self.i3DBaseDir .. self.sphere.fileName, false, false, self.loadedi3d, self, nil)
    for _, filename in ipairs(self.markers.fileNames) do
        g_i3DManager:loadSharedI3DFileAsync(self.i3DBaseDir .. filename, false, false, self.loadedi3d, self, nil)
    end
end

function ADDrawingManager:loadedi3d(rootNode, failedReason, arguments)
    return
end

function ADDrawingManager.initObject(id)
    local itemId = getChildAt(id, 0)
    link(getRootNode(), itemId)
    setRigidBodyType(itemId, RigidBodyType.NONE)
    setTranslation(itemId, 0, 0, 0)
    setVisibility(itemId, false)
    delete(id)
    return itemId
end

function ADDrawingManager:addLineTask(sx, sy, sz, ex, ey, ez, scale, r, g, b)
    -- storing task
    -- local hash = 0
    -- table.insert(self.lines.tasks, {sx = sx, sy = sy, sz = sz, ex = ex, ey = ey, ez = ez, scale = scale, r = r, g = g, b = b, hash = hash})
    scale = scale or 1
    self.lines.currentTask = self.lines.currentTask + 1
    if self.lines.tasks[self.lines.currentTask] == nil then
        -- add new task
        table.insert(self.lines.tasks, {sx = sx, sy = sy, sz = sz, ex = ex, ey = ey, ez = ez, scale = scale, r = r, g = g, b = b, taskChanged = true})
    elseif
        self.lines.tasks[self.lines.currentTask].sx ~= sx or
        self.lines.tasks[self.lines.currentTask].sy ~= sy or
        self.lines.tasks[self.lines.currentTask].sz ~= sz or
        self.lines.tasks[self.lines.currentTask].ex ~= ex or
        self.lines.tasks[self.lines.currentTask].ey ~= ey or
        self.lines.tasks[self.lines.currentTask].ez ~= ez or
        self.lines.tasks[self.lines.currentTask].scale ~= scale or
        self.lines.tasks[self.lines.currentTask].r ~= r or
        self.lines.tasks[self.lines.currentTask].g ~= g or
        self.lines.tasks[self.lines.currentTask].b ~= b
    then
        -- task changed
        self.lines.tasks[self.lines.currentTask].sx = sx
        self.lines.tasks[self.lines.currentTask].sy = sy
        self.lines.tasks[self.lines.currentTask].sz = sz
        self.lines.tasks[self.lines.currentTask].ex = ex
        self.lines.tasks[self.lines.currentTask].ey = ey
        self.lines.tasks[self.lines.currentTask].ez = ez
        self.lines.tasks[self.lines.currentTask].scale = scale
        self.lines.tasks[self.lines.currentTask].r = r
        self.lines.tasks[self.lines.currentTask].g = g
        self.lines.tasks[self.lines.currentTask].b = b
        self.lines.tasks[self.lines.currentTask].taskChanged = true
    else
        -- task unchanged -> false will be set after update with dFunc
        -- self.lines.tasks[self.lines.currentTask].taskChanged = false
    end
end

function ADDrawingManager:addArrowTask(sx, sy, sz, ex, ey, ez, scale, position, r, g, b)
    -- storing task
    scale = scale or 1
    -- local hash = 0
    -- table.insert(self.arrows.tasks, {sx = sx, sy = sy, sz = sz, ex = ex, ey = ey, ez = ez, scale = scale, r = r, g = g, b = b, position = position, hash = hash})
    self.arrows.currentTask = self.arrows.currentTask + 1
    if self.arrows.tasks[self.arrows.currentTask] == nil then
        -- add new task
        table.insert(self.arrows.tasks, {sx = sx, sy = sy, sz = sz, ex = ex, ey = ey, ez = ez, scale = scale, position = position, r = r, g = g, b = b, taskChanged = true})
    elseif
        self.arrows.tasks[self.arrows.currentTask].sx ~= sx or
        self.arrows.tasks[self.arrows.currentTask].sy ~= sy or
        self.arrows.tasks[self.arrows.currentTask].sz ~= sz or
        self.arrows.tasks[self.arrows.currentTask].ex ~= ex or
        self.arrows.tasks[self.arrows.currentTask].ey ~= ey or
        self.arrows.tasks[self.arrows.currentTask].ez ~= ez or
        self.arrows.tasks[self.arrows.currentTask].scale ~= scale or
        self.arrows.tasks[self.arrows.currentTask].position ~= position or
        self.arrows.tasks[self.arrows.currentTask].r ~= r or
        self.arrows.tasks[self.arrows.currentTask].g ~= g or
        self.arrows.tasks[self.arrows.currentTask].b ~= b
    then
        -- task changed
        self.arrows.tasks[self.arrows.currentTask].sx = sx
        self.arrows.tasks[self.arrows.currentTask].sy = sy
        self.arrows.tasks[self.arrows.currentTask].sz = sz
        self.arrows.tasks[self.arrows.currentTask].ex = ex
        self.arrows.tasks[self.arrows.currentTask].ey = ey
        self.arrows.tasks[self.arrows.currentTask].ez = ez
        self.arrows.tasks[self.arrows.currentTask].scale = scale
        self.arrows.tasks[self.arrows.currentTask].position = position
        self.arrows.tasks[self.arrows.currentTask].r = r
        self.arrows.tasks[self.arrows.currentTask].g = g
        self.arrows.tasks[self.arrows.currentTask].b = b
        self.arrows.tasks[self.arrows.currentTask].taskChanged = true
    else
        -- task unchanged -> false will be set after update with dFunc
        -- self.arrows.tasks[self.arrows.currentTask].taskChanged = false
    end
end

function ADDrawingManager:addSmallSphereTask(x, y, z, r, g, b)
    -- storing task
    -- local hash = 0
    -- table.insert(self.sSphere.tasks, {x = x, y = y, z = z, r = r, g = g, b = b, hash = hash})
    self.sSphere.currentTask = self.sSphere.currentTask + 1
    if self.sSphere.tasks[self.sSphere.currentTask] == nil then
        -- add new task
        table.insert(self.sSphere.tasks, {x = x, y = y, z = z, r = r, g = g, b = b, taskChanged = true})
    elseif
        self.sSphere.tasks[self.sSphere.currentTask].x ~= x or
        self.sSphere.tasks[self.sSphere.currentTask].y ~= y or
        self.sSphere.tasks[self.sSphere.currentTask].z ~= z or
        self.sSphere.tasks[self.sSphere.currentTask].r ~= r or
        self.sSphere.tasks[self.sSphere.currentTask].g ~= g or
        self.sSphere.tasks[self.sSphere.currentTask].b ~= b
    then
        -- task changed
        self.sSphere.tasks[self.sSphere.currentTask].x = x
        self.sSphere.tasks[self.sSphere.currentTask].y = y
        self.sSphere.tasks[self.sSphere.currentTask].z = z
        self.sSphere.tasks[self.sSphere.currentTask].r = r
        self.sSphere.tasks[self.sSphere.currentTask].g = g
        self.sSphere.tasks[self.sSphere.currentTask].b = b
        self.sSphere.tasks[self.sSphere.currentTask].taskChanged = true
    else
        -- task unchanged -> false will be set after update with dFunc
        -- self.sSphere.tasks[self.sSphere.currentTask].taskChanged = false
    end
end

function ADDrawingManager:addMarkerTask(x, y, z)
    -- storing task
    -- local hash = 0
    -- table.insert(self.markers.tasks, {x = x, y = y, z = z, hash = hash})
    self.markers.currentTask = self.markers.currentTask + 1
    if self.markers.tasks[self.markers.currentTask] == nil then
        -- add new task
        table.insert(self.markers.tasks, {x = x, y = y, z = z, taskChanged = true})
    elseif
        self.markers.tasks[self.markers.currentTask].x ~= x or
        self.markers.tasks[self.markers.currentTask].y ~= y or
        self.markers.tasks[self.markers.currentTask].z ~= z
    then
        -- task changed
        self.markers.tasks[self.markers.currentTask].x = x
        self.markers.tasks[self.markers.currentTask].y = y
        self.markers.tasks[self.markers.currentTask].z = z
        self.markers.tasks[self.markers.currentTask].taskChanged = true
    else
        -- task unchanged -> false will be set after update with dFunc
        -- self.markers.tasks[self.markers.currentTask].taskChanged = false
    end
end

function ADDrawingManager:addCrossTask(x, y, z, scale)
    -- storing task
    -- local hash = 0
    -- table.insert(self.cross.tasks, {x = x, y = y, z = z, scale = scale, hash = hash})
    scale = scale or 1
    self.cross.currentTask = self.cross.currentTask + 1
    if self.cross.tasks[self.cross.currentTask] == nil then
        -- add new task
        table.insert(self.cross.tasks, {x = x, y = y, z = z, scale = scale, taskChanged = true})
    elseif
        self.cross.tasks[self.cross.currentTask].x ~= x or
        self.cross.tasks[self.cross.currentTask].y ~= y or
        self.cross.tasks[self.cross.currentTask].z ~= z or
        self.cross.tasks[self.cross.currentTask].scale ~= scale
    then
        -- task changed
        self.cross.tasks[self.cross.currentTask].x = x
        self.cross.tasks[self.cross.currentTask].y = y
        self.cross.tasks[self.cross.currentTask].z = z
        self.cross.tasks[self.cross.currentTask].scale = scale
        self.cross.tasks[self.cross.currentTask].taskChanged = true
    else
        -- task unchanged -> false will be set after update with dFunc
        -- self.cross.tasks[self.cross.currentTask].taskChanged = false
    end
end

function ADDrawingManager:addSphereTask(x, y, z, scale, r, g, b, a)
    -- storing task
    -- local hash = 0
    -- table.insert(self.sphere.tasks, {x = x, y = y, z = z, r = r, g = g, b = b, a = a, scale = scale, hash = hash})
    scale = scale or 1
    a = a or 0
    self.sphere.currentTask = self.sphere.currentTask + 1
    if self.sphere.tasks[self.sphere.currentTask] == nil then
        -- add new task
        table.insert(self.sphere.tasks, {x = x, y = y, z = z, r = r, g = g, b = b, a = a, scale = scale, taskChanged = true})
    elseif
        self.sphere.tasks[self.sphere.currentTask].x ~= x or
        self.sphere.tasks[self.sphere.currentTask].y ~= y or
        self.sphere.tasks[self.sphere.currentTask].z ~= z or
        self.sphere.tasks[self.sphere.currentTask].r ~= r or
        self.sphere.tasks[self.sphere.currentTask].g ~= g or
        self.sphere.tasks[self.sphere.currentTask].b ~= b or
        self.sphere.tasks[self.sphere.currentTask].a ~= a or
        self.sphere.tasks[self.sphere.currentTask].scale ~= scale
    then
        -- task changed
        self.sphere.tasks[self.sphere.currentTask].x = x
        self.sphere.tasks[self.sphere.currentTask].y = y
        self.sphere.tasks[self.sphere.currentTask].z = z
        self.sphere.tasks[self.sphere.currentTask].r = r
        self.sphere.tasks[self.sphere.currentTask].g = g
        self.sphere.tasks[self.sphere.currentTask].b = b
        self.sphere.tasks[self.sphere.currentTask].a = a
        self.sphere.tasks[self.sphere.currentTask].scale = scale
        self.sphere.tasks[self.sphere.currentTask].taskChanged = true
    else
        -- task unchanged -> false will be set after update with dFunc
        -- self.sphere.tasks[self.sphere.currentTask].taskChanged = false
    end
end

function ADDrawingManager:draw()
    local time = netGetTime()
    local ad = AutoDrive
    self.yOffset = ad.drawHeight + ad.getSetting("lineHeight")

    -- update emittivity only once every 600 frames
    if self.emittivityNextUpdate <= 0 then
        local r, g, b = 1, 1, 1 --getLightColor(g_currentMission.environment.sunLightId)
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

function ADDrawingManager:drawObjects_alternative2(obj, dFunc, iFunc)
    -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 start...")
    local stats = {}
    stats["Tasks"] = {Total = obj.currentTask}
    stats["itemIDs"] = {Total = #obj.itemIDs}

    if (obj.currentTask == 0 and obj.lastTaskCount > 0) then -- disabled obj -> set all invisible
        -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 disabled objects %s", tostring(obj.fileName))
        -- set all invisible
        for _, itemID in ipairs (obj.itemIDs) do
            setVisibility(itemID, false)
        end
        obj.lastTaskCount = obj.currentTask
        return stats
    end

    if obj.currentTask == 0 then -- nothing to draw -> exit
        -- if (g_updateLoopIndex % 60 == 0) then
            -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 nothing to draw %s", tostring(obj.fileName))
        -- end
        obj.lastTaskCount = obj.currentTask
        return stats
    end

    local fileToUse
    if obj.usesSelection then        
        if obj.lastDrawFileUsed ~= AutoDrive.getSetting("iconSetToUse") then
            -- cleaning up not needed objects
            -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 iconSetToUse changed %s", tostring(obj.fileName))
            for _, id in pairs(obj.itemIDs) do
                -- make invisible unused items
                setVisibility(id, false)
            end
            obj.itemIDs = {}
        end
        fileToUse = obj.fileNames[AutoDrive.getSetting("iconSetToUse")]
        obj.lastDrawFileUsed = AutoDrive.getSetting("iconSetToUse")
    else
        fileToUse = obj.fileName
    end
-- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 fileToUse %s ", tostring(fileToUse))

    -- check if enougth objects are available - add missing amount
    if obj.currentTask > #obj.itemIDs then
        -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 obj.currentTask %s #obj.itemIDs %s %s", tostring(obj.currentTask), tostring(#obj.itemIDs), tostring(obj.fileName))
        for i = 1, obj.currentTask - #obj.itemIDs do
            -- loading new i3ds
            local itemID = g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. fileToUse, false, false)
            table.insert(obj.itemIDs,iFunc(itemID))
        end
    end
-- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 obj.currentTask %s #obj.itemIDs %s ", tostring(obj.currentTask), tostring(#obj.itemIDs))

    -- handle visibility
    if obj.currentTask > 0 then
        if obj.currentTask < obj.lastTaskCount then
            -- set not needed items invisible
            -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 obj.currentTask %d < lastTaskCount %d %s", obj.currentTask, obj.lastTaskCount, tostring(obj.fileName))
            for i = obj.currentTask + 1, obj.lastTaskCount do
                -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 setVisibility itemID %s ", tostring(itemID))
                if obj.itemIDs[i] ~= nil then
                    setVisibility(obj.itemIDs[i], false)
                end
            end
        elseif obj.currentTask > obj.lastTaskCount then
            -- set previous invisible items visible
            -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 obj.currentTask %d > lastTaskCount %d %s", obj.currentTask, obj.lastTaskCount, tostring(obj.fileName))
            for i = obj.lastTaskCount, obj.currentTask do
                -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 setVisibility itemID %s ", tostring(itemID))
                if obj.itemIDs[i] ~= nil then
                    setVisibility(obj.itemIDs[i], true)
                end
            end
        else
            -- number of visible items not changed
            -- if (g_updateLoopIndex % 60 == 0) then
                -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 obj.currentTask not changed %s", tostring(obj.fileName))
            -- end
        end
    end


-- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 drawing... ")
    -- drawing tasks
    local index = 1
    for _, task in pairs(obj.tasks) do
        local itemId = obj.itemIDs[index]
-- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 index %s itemId %s ", tostring(index), tostring(itemId))
        if task.taskChanged then
            -- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 dFunc %s", tostring(obj.fileName))
            dFunc(self, itemId, task)
            task.taskChanged = false
        end
        index = index + 1
    end
-- ADDrawingManager.debugMsg(nil, "ADDrawingManager:drawObjects_alternative2 end ")
    obj.lastTaskCount = obj.currentTask
    obj.currentTask = 0
    return stats
end

function ADDrawingManager:drawObjects_alternative(obj, dFunc, iFunc)
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative start...")
    local taskCount = #obj.tasks
    local stats = {}
    stats["Tasks"] = {Total = taskCount}
    stats["itemIDs"] = {Total = #obj.itemIDs}

    if taskCount > 0 or obj.lastDrawZero == false then
        -- set all invisible
        for _, itemID in ipairs (obj.itemIDs) do
    -- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative setVisibility itemID %s ", tostring(itemID))
            setVisibility(itemID, false)
        end
    end

    if taskCount == 0 then -- nothing to draw
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative nothing to draw ")
        obj.lastDrawZero = true
        return stats
    end

    local fileToUse
    if obj.usesSelection then        
        if obj.lastDrawFileUsed ~= AutoDrive.getSetting("iconSetToUse") then
            -- cleaning up not needed objects
            for _, id in pairs(obj.itemIDs) do
                -- make invisible unused items
                setVisibility(id, false)
            end
            obj.itemIDs = {}
        end
        fileToUse = obj.fileNames[AutoDrive.getSetting("iconSetToUse")]
        obj.lastDrawFileUsed = AutoDrive.getSetting("iconSetToUse")
    else
        fileToUse = obj.fileName
    end
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative fileToUse %s ", tostring(fileToUse))

-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative taskCount %s #obj.itemIDs %s ", tostring(taskCount), tostring(#obj.itemIDs))
    -- check if enougth objects are available - add missing amount
    if taskCount > #obj.itemIDs then
        for i = 1, taskCount - #obj.itemIDs do
            -- loading new i3ds
-- local node, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(self.i3dFilename, false, false)
            local itemID = g_i3DManager:loadSharedI3DFile(self.i3DBaseDir .. fileToUse, false, false)
            setVisibility(itemID, false)
            table.insert(obj.itemIDs,iFunc(itemID))
        end
    end
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative taskCount %s #obj.itemIDs %s ", tostring(taskCount), tostring(#obj.itemIDs))

-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative drawing... ")
    -- drawing tasks
    local index = 1
    for _, task in pairs(obj.tasks) do
        local itemId = obj.itemIDs[index]
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative index %s itemId %s ", tostring(index), tostring(itemId))
        dFunc(self, itemId, task)
        index = index + 1
    end
    obj.tasks = {}
-- AutoDrive.debugMsg(nil, "ADDrawingManager:drawObjects_alternative end ")
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
                local id = g_i3DManager:loadSharedI3DFile(baseDir .. fileToUse, false, false)
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
    return self:drawObjects_alternative2(obj, dFunc, iFunc)
    -- return self:drawObjects_alternative(obj, dFunc, iFunc)
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

    local scaleLines = (AutoDrive.getSetting("scaleLines") or 1) * (task.scale or 1)
    setScale(id, scaleLines, scaleLines, distToNextPoint)

    -- Set the direction of the line
    setRotation(id, rotX, rotY, 0)

    -- Update line color
    setShaderParameter(id, "lineColor", task.r, task.g, task.b, self.emittivity, false)
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

    local scaleLines = (AutoDrive.getSetting("scaleLines") or 1) * (task.scale or 1)
    setScale(id, scaleLines, scaleLines, scaleLines)

    -- Set the direction of the arrow
    setRotation(id, rotX, rotY, 0)

    -- Update arrow color
    setShaderParameter(id, "lineColor", task.r, task.g, task.b, self.emittivity, false)
end

function ADDrawingManager:drawSmallSphere(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    setShaderParameter(id, "lineColor", task.r, task.g, task.b, self.emittivity, false)
end

function ADDrawingManager:drawMarker(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
end

function ADDrawingManager:drawCross(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    local scaleLines = (AutoDrive.getSetting("scaleLines") or 1) * (task.scale or 1)
    setScale(id, scaleLines, scaleLines, scaleLines)
end

function ADDrawingManager:drawSphere(id, task)
    setTranslation(id, task.x, task.y + self.yOffset, task.z)
    setScale(id, task.scale, task.scale, task.scale)
    setShaderParameter(id, "lineColor", task.r, task.g, task.b, self.emittivity + task.a, false)
end

function ADDrawingManager.debugMsg(vehicle, debugText, ...)
    if ADDrawingManager.enableDebug == true then
        AutoDrive.debugMsg(vehicle, debugText, ...)
    end
end
