--
-- Mod: AutoDrive
--
-- Author: Stephan
-- Email: Stephan910@web.de
-- Date: 02.02.2019
-- Version: 1.0.0.0

-- #############################################################################

source(Utils.getFilename("scripts/AutoDrive.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/AutoDriveVehicleData.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Specialization.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Sync.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/XML.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Settings.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Hud.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/DijkstraLive.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/DijkstraLiveBlue.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/ExternalInterface.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/PathCalculation.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/TelemetryExport.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Hud/GenericHudElement.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Hud/HudButton.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Hud/HudSettingsButton.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Hud/HudIcon.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Hud/HudSpeedmeter.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Hud/PullDownList.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Events/GroupsEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/UserDataEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/UpdateSettingsEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/RenameDriverEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/UserConnectedEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/ExperimentalFeaturesEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/MessageEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/InputEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/HudInputEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/DebugSettingsEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/StartStopEvent.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Events/Graph/CreateMapMarkerEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/DeleteMapMarkerEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/RenameMapMarkerEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/ChangeMapMarkerGroupEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/ToggleConnectionEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/DeleteWayPointEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/CreateWayPointEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/RecordWayPointEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/MoveWayPointEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/RoutesUploadEvent.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Events/Graph/SetConnectionEvent.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Utils/AutoDriveTON.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/TrailerUtil.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/CombineUtil.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/UtilFuncs.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/Queue.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/RingQueue.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/Buffer.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/FlaggedTable.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/CollisionDetectionUtils.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/PathFinderUtils.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/AutoDriveUtilFuncs.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/SortedQueue.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Utils/DevFuncs.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Manager/RoutesManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/DrawingManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/MessagesManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/GraphManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/TriggerManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/HarvestManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/InputManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/UserDataManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/MultipleTargetsManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/ThirdPartyModsManager.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Manager/Scheduler.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Tasks/AbstractTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/DriveToDestinationTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/StopAndDisableADTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/UnloadAtDestinationTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/LoadAtDestinationTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/RestartADTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/UnloadBGATask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/DriveToVehicleTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/EmptyHarvesterTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/WaitForCallTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/ClearCropTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/CatchCombinePipeTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/FollowCombineTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/RefuelTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/ExitFieldTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/FollowVehicleTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/ReverseFromBadLocationTask.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Tasks/ParkTask.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Modules/DrivePathModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/CollisionDetectionModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/SpecialDrivingModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/TaskModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/TrailerModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/PathFinderModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/StateModule.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modules/RecordingModule.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Modes/AbstractMode.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modes/DriveToMode.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modes/UnloadAtMode.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modes/PickupAndDeliverMode.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modes/LoadMode.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modes/BGAMode.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Modes/CombineUnloaderMode.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Sensors/VirtualSensors.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Sensors/CollSensor.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Sensors/FruitSensor.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Sensors/FieldSensor.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Gui/RoutesManagerGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/NotificationsHistoryGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/ColorSettingsGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/EnterDriverNameGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/EnterGroupNameGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/EnterTargetNameGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/ScanConfirmationGUI.lua", g_currentModDirectory))

source(Utils.getFilename("scripts/Gui/EnterDestinationFilterGUI.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/SettingsPage.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/DebugSettingsPage.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/ExperimentalFeaturesSettingsPage.lua", g_currentModDirectory))
source(Utils.getFilename("scripts/Gui/Settings.lua", g_currentModDirectory))

AutoDriveRegister = {}
AutoDriveRegister.version = g_modManager:getModByName(g_currentModName).version

if AutoDrive.ADSpecName == nil then
    AutoDrive.ADSpecName = g_currentModName .. ".AutoDrive"
end

if g_specializationManager:getSpecializationByName("AutoDrive") == nil then
    g_specializationManager:addSpecialization("AutoDrive", "AutoDrive", Utils.getFilename("scripts/AutoDrive.lua", g_currentModDirectory), nil)
end

function AutoDrive.dumpTable_temp(inputTable, name, maxDepth)
    maxDepth = maxDepth or 5
    print(name .. " = {}")
    local function dumpTableRecursively(inputTable, name, depth, maxDepth)
        if depth >= maxDepth then
            return
        end
        for k, v in pairs(inputTable) do
            local newName = string.format("%s.%s", name, k)
            if type(k) == "number" then
                newName = string.format("%s[%s]", name, k)
            end
            if type(v) ~= "table" and type(v) ~= "function" then
                print(string.format("%s = %s", newName, v))
            end
            if type(v) == "table" then
                print(newName .. " = {}")
                dumpTableRecursively(v, newName, depth + 1, maxDepth)
            end
        end
    end
    for k, v in pairs(inputTable) do
        local newName = string.format("%s.%s", name, k)
        if type(k) == "number" then
            newName = string.format("%s[%s]", name, k)
        end
        if type(v) ~= "table" and type(v) ~= "function" then
            print(string.format("%s = %s", newName, v))
        end
        if type(v) == "table" then
            print(newName .. " = {}")
            dumpTableRecursively(v, newName, 1, maxDepth)
        end
    end
end

--AutoDrive.dumpTable_temp(TypeManager, "TypeManager", 2)

function AutoDriveRegister.register()

    if AutoDrive == nil then
        Logging.error("[AD] Unable to add specialization 'AutoDrive'")
        return
    end

    for vehicleType, typeDef in pairs(g_vehicleTypeManager.types) do
        if typeDef ~= nil and vehicleType ~= "locomotive" and vehicleType ~= "horse" and (not typeDef.hasADSpec == true) then
            if AutoDrive.prerequisitesPresent(typeDef.specializations) then
                Logging.info('[AD] Attached to vehicleType "%s"', vehicleType)
                if typeDef.specializationsByName[AutoDrive.ADSpecName] == nil then
                    g_vehicleTypeManager:addSpecialization(vehicleType, AutoDrive.ADSpecName)
                    typeDef.hasADSpec = true
                end
            end
        end
    end
end

if AutoDrive.ADVDSpecName == nil then
    AutoDrive.ADVDSpecName = g_currentModName .. ".AutoDriveVehicleData"
end

if g_specializationManager:getSpecializationByName("AutoDriveVehicleData") == nil then
	g_specializationManager:addSpecialization("AutoDriveVehicleData", "AutoDriveVehicleData", Utils.getFilename("scripts/Utils/AutoDriveVehicleData.lua", g_currentModDirectory), nil)
end

function AutoDriveRegister.registerVehicleData()

	if AutoDriveVehicleData == nil then
		Logging.error("[AutoDriveVehicleData] Unable to add specialization 'AutoDriveVehicleData'")
		return
	end

	for vehicleType, typeDef in pairs(g_vehicleTypeManager.types) do
		if typeDef ~= nil and vehicleType ~= "locomotive" and vehicleType ~= "horse" and (not typeDef.hasADVDSpec == true) then
			if AutoDriveVehicleData.prerequisitesPresent(typeDef.specializations) then
				if typeDef.specializationsByName[AutoDrive.ADVDSpecName] == nil then
					g_vehicleTypeManager:addSpecialization(vehicleType, AutoDrive.ADVDSpecName)
					typeDef.hasADVDSpec = true
				end
			end
		end
	end
end

-- We need this for network debug functions
EventIds.eventIdToName = {}

for eName, eId in pairs(EventIds) do
	if string.sub(eName, 1, 6) == "EVENT_" then
		EventIds.eventIdToName[eId] = eName
	end
end

function AutoDriveRegister:loadMap(name)
	Logging.info("[AutoDrive] Loaded mod version %s (by Stephan). Full version number: %s", self.version, AutoDrive.version)
end

function AutoDriveRegister:deleteMap()
end

function AutoDriveRegister:keyEvent(unicode, sym, modifier, isDown)
end

function AutoDriveRegister:mouseEvent(posX, posY, isDown, isUp, button)
end

function AutoDriveRegister:update(dt)
end

function AutoDriveRegister:draw()
end

--Knowledge to register translations in l10n space and to use the helpLineManager taken from the Seasons mod (Thank you!)
function AutoDriveRegister.onMissionWillLoad(i18n)
	AutoDriveRegister.addModTranslations(i18n)
end

function AutoDriveValidateVehicleTypes(TypeManager)
	AutoDriveRegister.onMissionWillLoad(g_i18n)
	AutoDrive:onAllModsLoaded()
end

---Copy our translations to global space.
function AutoDriveRegister.addModTranslations(i18n)
	-- We can copy all our translations to the global table because we prefix everything with ad_ or have unique names with 'AD' in it.
	-- The mod-based l10n lookup only really works for vehicles, not UI and script mods.
	local global = getfenv(0).g_i18n.texts

	for key, text in pairs(i18n.texts) do
		global[key] = text
	end
end

function AutoDriveLoadedMission(mission, superFunc, node)
	superFunc(mission, node)

	if mission.cancelLoading then
		return
	end
end

Mission00.loadMission00Finished = Utils.overwrittenFunction(Mission00.loadMission00Finished, AutoDriveLoadedMission)
TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, AutoDriveValidateVehicleTypes)

addModEventListener(AutoDriveRegister)

-- first iteration to register AD to vehicle types
AutoDriveRegister.register()
AutoDriveRegister.registerVehicleData()
