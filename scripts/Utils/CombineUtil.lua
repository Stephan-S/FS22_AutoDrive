AutoDrive.CHASEPOS_LEFT = 1
AutoDrive.CHASEPOS_RIGHT = -1
AutoDrive.CHASEPOS_REAR = 3
AutoDrive.CHASEPOS_FRONT = 4
AutoDrive.CHASEPOS_UNKNOWN = 0

function AutoDrive.getIsBufferCombine(vehicle)
    return vehicle ~= nil
        and vehicle.spec_combine ~= nil
        and vehicle.spec_combine.isBufferCombine == true
end

function AutoDrive.getIsAutoAimingChopper(vehicle)
    return vehicle ~= nil
        and vehicle.spec_combine ~= nil
        and vehicle.spec_combine.isBufferCombine == true
        and vehicle.spec_pipe ~= nil
        and vehicle.spec_pipe.numAutoAimingStates > 0
end

function AutoDrive.getDischargeNode(combine)
    local dischargeNode = nil
    if combine.spec_dischargeable ~= nil then
        for _, dischargeNodeIter in pairs(combine.spec_dischargeable.dischargeNodes) do
            dischargeNode = dischargeNodeIter
        end
        if combine.getPipeDischargeNodeIndex ~= nil then
            dischargeNode = combine.spec_dischargeable.dischargeNodes[combine:getPipeDischargeNodeIndex()]
        end
        return dischargeNode.node
    else
        return nil
    end
end

function AutoDrive.getPipeRoot_old(combine)
    if combine.ad ~= nil and combine.ad.pipeRoot ~= nil then
        return combine.ad.pipeRoot
    end
    local pipeRoot = AutoDrive.getDischargeNode(combine)
    local parentStack = Buffer:new()
    local combineNode = combine.components[1].node

    repeat
        parentStack:Insert(pipeRoot)
        pipeRoot = getParent(pipeRoot)
    until ((pipeRoot == combineNode) or (pipeRoot == 0) or (pipeRoot == nil) or parentStack:Count() == 100)

    local translationMagnitude = 0
    local pipeRootX, pipeRootY, pipeRootZ
    -- local pipeRootWorldX, pipeRootWorldY, pipeRootWorldZ
    -- local heightUnderRoot, pipeRootAgl
    -- local lastPipeRoot = pipeRoot

    repeat
        pipeRoot = parentStack:Get()
        if pipeRoot ~= nil and pipeRoot ~= 0 then
            pipeRootX, pipeRootY, pipeRootZ = getTranslation(pipeRoot)
            -- pipeRootWorldX, pipeRootWorldY, pipeRootWorldZ = getWorldTranslation(pipeRoot)
            -- heightUnderRoot = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, pipeRootWorldX, pipeRootWorldY, pipeRootWorldZ)
            -- pipeRootAgl = pipeRootWorldY - heightUnderRoot
            translationMagnitude = MathUtil.vector3Length(pipeRootX, pipeRootY, pipeRootZ)
        end
    until ((translationMagnitude > 0.01 and translationMagnitude < 100) and
           (AutoDrive.getIsBufferCombine(combine) or AutoDrive.sign(pipeRootX) == AutoDrive.getPipeSide(combine)) and
           (pipeRootY > 0) or
           parentStack:Count() == 0
          )
          
    if pipeRoot == nil or pipeRoot == 0 then
        pipeRoot = combine.components[1].node
    end

    if combine.ad ~= nil then
        combine.ad.pipeRoot = pipeRoot
    end

    return pipeRoot
end


function AutoDrive.getPipeRoot(combine)
    if combine.ad ~= nil and combine.ad.pipeRoot ~= nil then
        return combine.ad.pipeRoot
    end
    local dischargeNode = AutoDrive.getDischargeNode(combine)
    local pipeRoot = nil

    if dischargeNode then
        for _, component in ipairs(combine.components) do

            local node = dischargeNode
            local count = 0
            repeat
                node = getParent(node)
                count = count + 1
            until ((node == component.node) or (node == 0) or (node == nil) or count >= 100)

            if node and node ~= 0 then
                -- found
                pipeRoot = node
                break
            end
        end
    end
    if pipeRoot == nil or pipeRoot == 0 then
        -- fallback
        pipeRoot = combine.components[1].node
    end

    if combine.ad ~= nil then
        combine.ad.pipeRoot = pipeRoot
    end
    return pipeRoot
end

-- ret: -1 right, 1 left, 0 behind
-- not for sugarcane harvesters, choppers!!!
function AutoDrive.getPipeSide(combine)
    if combine.ad ~= nil and combine.ad.storedPipeSide ~= nil then
        return combine.ad.storedPipeSide
    end
    local combineNode = AutoDrive.getPipeRoot(combine)
    local dischargeNode = AutoDrive.getDischargeNode(combine)
    local dischargeX, dichargeY, dischargeZ = getWorldTranslation(dischargeNode)
    local diffX, _, _ = worldToLocal(combineNode, dischargeX, dichargeY, dischargeZ)
    if combine.ad ~= nil and AutoDrive.isPipeOut(combine) and not AutoDrive.getIsAutoAimingChopper(combine) then
        combine.ad.storedPipeSide = AutoDrive.sign(diffX)
    end
    return AutoDrive.sign(diffX)
end

function AutoDrive.getPipeLength(combine)
    if combine.ad ~= nil and combine.ad.storedPipeLength ~= nil then
        return combine.ad.storedPipeLength
    end

    local pipeRootX, _ , pipeRootZ = getWorldTranslation(AutoDrive.getPipeRoot(combine))
    local dischargeX, dischargeY, dischargeZ = getWorldTranslation(AutoDrive.getDischargeNode(combine))
    local length = MathUtil.vector3Length(pipeRootX - dischargeX,
                                        0, 
                                        pipeRootZ - dischargeZ)
    --AutoDrive.debugPrint(combine, AutoDrive.DC_COMBINEINFO, "AutoDrive.getPipeLength - " .. length)
    if AutoDrive.isPipeOut(combine) and not AutoDrive.getIsAutoAimingChopper(combine) then
        local combineNode = AutoDrive.getPipeRoot(combine)
        local dischargeX, dichargeY, dischargeZ = getWorldTranslation(AutoDrive.getDischargeNode(combine))
        diffX, _, _ = worldToLocal(combineNode, dischargeX, dichargeY, dischargeZ)
        length = math.abs(diffX)

        -- Store pipe length for 'normal' harvesters
        if combine.ad ~= nil then
            combine.ad.storedPipeLength = length
        end
    end

    return length
end

function AutoDrive.isPipeOut(combine)

    local function isPipeOut(combine)
        if (combine.spec_combine ~= nil and combine.spec_pipe ~= nil and combine.spec_dischargeable ~= nil) then
            if combine.getIsDischargeNodeActive ~= nil and combine.getPipeDischargeNodeIndex ~= nil then
                local pipeDischargeNodeIndex = combine:getPipeDischargeNodeIndex()
                if pipeDischargeNodeIndex and pipeDischargeNodeIndex > 0 then
                    local spec_dischargeable = combine.spec_dischargeable
                    if spec_dischargeable and spec_dischargeable.dischargeNodes and #spec_dischargeable.dischargeNodes > 0 then
                        local dischargeNode = spec_dischargeable.dischargeNodes[pipeDischargeNodeIndex]
                        if dischargeNode and combine:getIsDischargeNodeActive(dischargeNode) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    if combine.spec_combine ~= nil then
        return isPipeOut(combine)
    else        
        for _, implement in pairs(AutoDrive.getAllImplements(combine)) do
            if implement and isPipeOut(implement) then
                return true
            end
        end
    end
    return false
end

function AutoDrive.isSugarcaneHarvester(combine)
    -- see Specialisation
    return combine and combine.ad and combine.ad.isSugarcaneHarvester
end

function AutoDrive.isSugarcaneHarvester_old(combine)
    local isSugarCaneHarvester = combine.typeName == "combineCutterFruitPreparer"
    for _, implement in pairs(AutoDrive.getAllImplements(combine)) do
        if implement ~= combine then
            isSugarCaneHarvester = false
        end
    end
    return isSugarCaneHarvester
end

function AutoDrive.getAIMarkerWidth(object)
    local retWidth = 0
    if object ~= nil and object.getAIMarkers ~= nil then
        local aiLeftMarker, aiRightMarker = object:getAIMarkers()
        if aiLeftMarker ~= nil and aiRightMarker ~= nil then
            local left, _, _ = localToLocal(aiLeftMarker, object.rootNode, 0, 0, 0)
            local right, _, _ = localToLocal(aiRightMarker, object.rootNode, 0, 0, 0)
            if left < right then
                left, right = right, left
            end
            retWidth = left - right
        end
    end
    return retWidth
end

function AutoDrive.getAISizeMarkerWidth(object)
    local retWidth = 0
    if object ~= nil and object.getAISizeMarkers ~= nil then
        local aiLeftMarker, aiRightMarker = object:getAISizeMarkers()
        if aiLeftMarker ~= nil and aiRightMarker ~= nil then
            local left, _, _ = localToLocal(aiLeftMarker, object.rootNode, 0, 0, 0)
            local right, _, _ = localToLocal(aiRightMarker, object.rootNode, 0, 0, 0)
            if left < right then
                left, right = right, left
            end
            retWidth = left - right
        end
    end
    return retWidth
end

function AutoDrive.getFrontToolWidth(vehicle, forced)
    if vehicle.ad ~= nil and vehicle.ad.frontToolWidth ~= nil and not (forced == true) then
        return vehicle.ad.frontToolWidth
    end
    local widthOfFrontTool = 0

    -- check for AIMarkers
    local implements = AutoDrive.getAllImplements(vehicle, false)
    for _, implement in pairs(implements) do
        --Check if tool is in front of vehicle
        local toolX, toolY, toolZ = getWorldTranslation(implement.components[1].node)
        local _, _, offsetZ =  worldToLocal(vehicle.components[1].node, toolX, toolY, toolZ)
        if offsetZ > 0 then
            widthOfFrontTool = math.max(widthOfFrontTool, AutoDrive.getAIMarkerWidth(implement))
        end
    end

    if widthOfFrontTool == 0 then
        -- check for AISizeMarkers
        for _, implement in pairs(implements) do
            --Check if tool is in front of vehicle
            local toolX, toolY, toolZ = getWorldTranslation(implement.components[1].node)
            local _, _, offsetZ =  worldToLocal(vehicle.components[1].node, toolX, toolY, toolZ)
            if offsetZ > 0 then
                widthOfFrontTool = math.max(widthOfFrontTool, AutoDrive.getAISizeMarkerWidth(implement))
            end
        end
    end

    if widthOfFrontTool == 0 then
        -- if AIMarkers not available or returned 0, get tool size as defined in vehicle XML - the worst case, see rsmDS900.xml
        for _, implement in pairs(implements) do
            if implement.size.width ~= nil then
                --Check if tool is in front of vehicle
                local toolX, toolY, toolZ = getWorldTranslation(implement.components[1].node)
                local _, _, offsetZ =  worldToLocal(vehicle.components[1].node, toolX, toolY, toolZ)
                if offsetZ > 0 then
                    widthOfFrontTool = math.abs(implement.size.width)
                end
            end
        end
    end

    if vehicle.ad ~= nil then
        vehicle.ad.frontToolWidth = widthOfFrontTool
    end

    return widthOfFrontTool
end

function AutoDrive.getFrontToolLength(vehicle)
    if vehicle.ad ~= nil and vehicle.ad.frontToolLength ~= nil then
        return vehicle.ad.frontToolLength
    end
    local lengthOfFrontTool = 0

    local implements = AutoDrive.getAllImplements(vehicle, false)
    for _, implement in pairs(implements) do
        if implement.size.width ~= nil then
            --Check if tool is in front of vehicle
            local toolX, toolY, toolZ = getWorldTranslation(implement.components[1].node)
            local _, _, offsetZ =  worldToLocal(vehicle.components[1].node, toolX, toolY, toolZ)
            if offsetZ > 0 then
                lengthOfFrontTool = math.abs(implement.size.length)
            end
        end
    end

    if vehicle.ad ~= nil then
        vehicle.ad.frontToolLength = lengthOfFrontTool
    end

    return lengthOfFrontTool
end

function AutoDrive.getLengthOfFieldInFront(vehicle, onlyWithFruit, maxRange, stepLength)
    local maxSearchRange = maxRange or 50
    local acceptOnlyWithFruit = onlyWithFruit or false
    local stepLength = stepLength or 5
    
    local length = 10
    local foundField = true
    local fruitType = nil
    while foundField do
        local worldPosX, _, worldPosZ = localToWorld(vehicle.components[1].node, 0, 0, length + stepLength)
        foundField = AutoDrive.checkIsOnField(worldPosX, 0, worldPosZ)

        if acceptOnlyWithFruit then
            local foundFruit = false
            local corners = AutoDrive.getCornersForAreaRelativeToVehicle(vehicle, 0, length, 3, stepLength)
            if fruitType == nil then
                foundFruit, fruitType = AutoDrive.checkForUnknownFruitInArea(corners)
            else
                foundFruit = AutoDrive.checkForFruitTypeInArea(corners, fruitType)
            end
            foundField = foundField and foundFruit        
        end

        length = length + stepLength
        if math.abs(length) >= maxSearchRange then
            foundField = false
        end
    end

    return length
end

-- 3
-- |
-- |
-- 1 ---- 2
--
--
--    v
function AutoDrive.getCornersForAreaRelativeToVehicle(vehicle, xOffset, zOffset, width, length)
    local corners = {}
    local worldPosX, _, worldPosZ = localToWorld(vehicle.components[1].node, xOffset - width/2, 0, zOffset)
    corners[1] = { x = worldPosX, z = worldPosZ}
    worldPosX, _, worldPosZ = localToWorld(vehicle.components[1].node, xOffset + width/2, 0, zOffset)
    corners[2] = { x = worldPosX, z = worldPosZ}
    worldPosX, _, worldPosZ = localToWorld(vehicle.components[1].node, xOffset - width/2, 0, zOffset + length)
    corners[3] = { x = worldPosX, z = worldPosZ}

    return corners
end
