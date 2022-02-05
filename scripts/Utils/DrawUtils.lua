--- Functions copied from the Specialization.lua and removed a few dependencies.
--- No idea how these functions are working. Just tweaked to make them working.
---@class ADDrawUtils
ADDrawUtils = {}

function ADDrawUtils.drawCloseDestinations(ad)
    local x1, y1, z1 = unpack(ad.position)
    --Draw close destinations
    for _, marker in pairs(ADGraphManager:getMapMarkers()) do
        local wp = ADGraphManager:getWayPointById(marker.id)
        if MathUtil.vector2Length(wp.x - x1, wp.z - z1) < AutoDrive.drawDistance then
            Utils.renderTextAtWorldPosition(wp.x, wp.y + 4, wp.z, marker.name, getCorrectTextSize(0.013), 0)
            ADDrawingManager:addMarkerTask(wp.x, wp.y + 0.45, wp.z)
        end
    end
end

function ADDrawUtils.drawWaypoints(ad)
    for _, point in pairs(AdWaypointUtils.getWayPointsInRange(ad,0, AutoDrive.drawDistance)) do
        ADDrawUtils.drawSingleWaypoint(ad, point)
        ADDrawUtils.drawWaypointConnections(ad, point )
    end
end

function ADDrawUtils.drawSingleWaypoint(ad, point)
    local x = point.x
    local y = point.y
    local z = point.z
    local isSubRouteWp = ADGraphManager:getIsPointSubPrio(point.id)

    local colors = AutoDrive.currentColors

    local color = colors.ad_color_default

    if AutoDrive.enableSphrere  then
        if AutoDrive.mouseIsAtPos(point, 0.01) then
            color = colors.ad_color_hoveredNode
        elseif point.id == ad.selectedNodeId then
            color = colors.ad_color_selectedNode
        elseif isSubRouteWp then 
            color = colors.ad_color_subPrioNode
        elseif point.colors ~= nil then 
            color = point.colors
        end
        --- Base waypoint sphere.
        ADDrawingManager:addSphereTask(x, y, z, 3, unpack(color))

        --- If the lines are drawn above the vehicle, we have to draw a line to the reference point on the ground 
        --- and a second cube there for moving the node position.
        if AutoDrive.getSettingState("lineHeight") > 1 then
            local gy = y - AutoDrive.drawHeight - AutoDrive.getSetting("lineHeight")
            ADDrawingManager:addLineTask(x, y, z, x, gy, z, unpack(AutoDrive.currentColors.ad_color_editorHeightLine))

            ADDrawingManager:addSphereTask(x, gy, z, 3, unpack(color))
        end

        -- draw previous and next points in different colors - note: sequence is important
        if point.out ~= nil then
            for _, neighbor in pairs(point.out) do
                local nWp = ADGraphManager:getWayPointById(neighbor)
                if nWp ~= nil then
                    if AutoDrive.mouseIsAtPos(nWp, 0.01) then
                        -- draw previous point in GOLDHOFER_PINK1
                        ADDrawingManager:addSphereTask(point.x, point.y, point.z, 3.4, unpack(AutoDrive.currentColors.ad_color_previousNode))
                    end
                    if AutoDrive.mouseIsAtPos(point, 0.01) then
                        -- draw next point
                        ADDrawingManager:addSphereTask(nWp.x, nWp.y, nWp.z, 3.2, unpack(AutoDrive.currentColors.ad_color_nextNode))
                    end
                end
            end
        end
    end
end

function ADDrawUtils.drawWaypointConnections(ad, point )
    
    local x = point.x
    local y = point.y
    local z = point.z
    local isSubRouteWp = ADGraphManager:getIsPointSubPrio(point.id)

    local colors = AutoDrive.currentColors

    local color = colors.ad_color_singleConnection
    local arrowPosition = ADDrawingManager.arrows.position.middle
    local pointsDrawn = {}

    -- draw connection lines
    if point.out ~= nil then
        for _, neighbor in pairs(point.out) do
            
            pointsDrawn[neighbor] = true
            local target = ADGraphManager:getWayPointById(neighbor)
            local targetIsSubRouteWp = ADGraphManager:getIsPointSubPrio(neighbor)
            if target ~= nil then
                --check if outgoing connection is a dual way connection
                local nWp = ADGraphManager:getWayPointById(neighbor)
                if point.incoming == nil or table.contains(point.incoming, neighbor) then
                    --draw dual way line
                    if point.id > nWp.id then
                        if isSubRouteWp or targetIsSubRouteWp then
                            color = colors.ad_color_subPrioDualConnection
                        else
                            color = colors.ad_color_dualConnection       
                        end
                        ADDrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(color))
                    end
                else
                    --draw line with direction markers (arrow)
                    if (nWp.incoming == nil or table.contains(nWp.incoming, point.id)) then
                        -- one way line
                        if isSubRouteWp or targetIsSubRouteWp then
                            color = colors.ad_color_subPrioSingleConnection
                        else
                            color = colors.ad_color_singleConnection
                        end
                    else
                        -- reverse way line
                        color = colors.ad_color_reverseConnection
                    end
                    ADDrawingManager:addLineTask(x, y, z, nWp.x, nWp.y, nWp.z, unpack(color))
                    ADDrawingManager:addArrowTask(x, y, z, nWp.x, nWp.y, nWp.z, arrowPosition, unpack(color))
                end
            end
        end
    end

    --just a quick way to highlight single (forgotten) points with no connections
    if (#point.out == 0) and (#point.incoming == 0) and not pointsDrawn[point.id] and point.colors == nil then
        y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z) + 0.5
        ADDrawingManager:addCrossTask(x, y, z)
    end
end


function ADDrawUtils.draw(ad)
   
    -- Draw close destinations
    ADDrawUtils.drawCloseDestinations(ad)
    
    -- Draw waypoint network.
    ADDrawUtils.drawWaypoints(ad)
end
