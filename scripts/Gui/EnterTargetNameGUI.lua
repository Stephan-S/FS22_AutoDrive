--
-- AutoDrive Enter Target Name GUI
-- V1.1.0.0
--
-- @author Stephan Schlosser
-- @date 08/08/2019

ADEnterTargetNameGui = {}
ADEnterTargetNameGui.CONTROLS = {"titleElement", "textInputElement", "buttonsCreateElement", "buttonsEditElement"}

local ADEnterTargetNameGui_mt = Class(ADEnterTargetNameGui, ScreenElement)

function ADEnterTargetNameGui:new(target)
    local o = ScreenElement:new(target, ADEnterTargetNameGui_mt)
    o.returnScreenName = ""
    o.editName = nil
    o.editId = nil
    o.edit = false
    o:registerControls(ADEnterTargetNameGui.CONTROLS)
    return o
end

function ADEnterTargetNameGui:onOpen()
    ADEnterTargetNameGui:superClass().onOpen(self)
    self.textInputElement.blockTime = 0
    self.textInputElement:onFocusActivate()
    self.editName = nil
    self.editId = nil
    self.edit = false

    -- If editSelectedMapMarker is true, we have to edit the map marker selected on the pull down list otherwise we can go for closest waypoint
    if AutoDrive.editSelectedMapMarker ~= nil and AutoDrive.editSelectedMapMarker == true then
        self.editId = g_currentMission.controlledVehicle.ad.stateModule:getFirstMarkerId()
        self.editName = ADGraphManager:getMapMarkerById(self.editId).name
    else
        local closest, _ = g_currentMission.controlledVehicle:getClosestWayPoint()
        if closest ~= nil and closest ~= -1 and ADGraphManager:getWayPointById(closest) ~= nil then
            local cId = closest
            for i, mapMarker in pairs(ADGraphManager:getMapMarkers()) do
                -- If we have already a map marker on this waypoint, we edit it otherwise we create a new one
                if mapMarker.id == cId then
                    self.editId = i
                    self.editName = mapMarker.name
                    break
                end
            end
        end
    end

    if self.editId ~= nil and self.editName ~= nil then
        self.edit = true
    end

    if self.edit then
        self.titleElement:setText(g_i18n:getText("gui_ad_enterTargetNameTitle_edit"))
        self.textInputElement:setText(self.editName)
    else
        self.titleElement:setText(g_i18n:getText("gui_ad_enterTargetNameTitle_add"))
        self.textInputElement:setText("")
    end

    self.buttonsCreateElement:setVisible(not self.edit)
    self.buttonsEditElement:setVisible(self.edit)
end

function ADEnterTargetNameGui:onClickOk()
    ADEnterTargetNameGui:superClass().onClickOk(self)
    if self.edit then
        ADGraphManager:renameMapMarker(self.textInputElement.text, self.editId)
    else
        ADGraphManager:createMapMarkerOnClosest(g_currentMission.controlledVehicle, self.textInputElement.text)
    end
    self:onClickBack()
end

function ADEnterTargetNameGui:onClickActivate()
    ADEnterTargetNameGui:superClass().onClickActivate(self)
    ADGraphManager:removeMapMarker(self.editId)
    self:onClickBack()
end

function ADEnterTargetNameGui:onClickCancel()
    ADEnterTargetNameGui:superClass().onClickCancel(self)
    self.textInputElement:setText(self.editName)
end

function ADEnterTargetNameGui:onClickBack()
    ADEnterTargetNameGui:superClass().onClickBack(self)
end

function ADEnterTargetNameGui:onEnterPressed(_, isClick)
    if not isClick then
        self:onClickOk()
    end
end

function ADEnterTargetNameGui:onEscPressed()
    self:onClickBack()
end
