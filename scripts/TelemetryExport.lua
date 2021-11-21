AutoDrive.TelemetryOutputCycle = 500
AutoDrive.InputReadCycle = 100
AutoDrive.xmlFile_telemetry = ""
AutoDrive.xmlFile_inputs = ""
AutoDrive.lastReadChangeID = 0
AutoDrive.shouldOutputStaticTelemetry = true

function AutoDrive.initTelemetry()
	if g_server == nil then
		return
	end

	AutoDrive.timeSinceLastTelemetryOutput = 0;
	AutoDrive.timeSinceLastInputRead = 0;
	AutoDrive.xmlFileName_telemetry = getUserProfileAppPath() .. "autoDrive\\AD_telemetry_out.txt"
	AutoDrive.xmlFileName_telemetry_static = getUserProfileAppPath() .. "autoDrive\\AD_telemetry_static_out.txt"
	AutoDrive.xmlFileName_inputs = getUserProfileAppPath() .. "autoDrive\\AD_input"

	g_logManager:info("[AD] AutoDrive.xmlFileName_telemetry " .. AutoDrive.xmlFileName_telemetry)

	
	--AutoDrive:registerDestinationListener(AutoDrive, AutoDrive.triggerStaticOutput)
end

function AutoDrive.triggerStaticOutput()
	AutoDrive.shouldOutputStaticTelemetry = true
end

function AutoDrive.handleTelemetry(dt)
	if not AutoDrive.experimentalFeatures.telemetryOutput then
		return
	end

	AutoDrive.timeSinceLastTelemetryOutput = AutoDrive.timeSinceLastTelemetryOutput + dt
	AutoDrive.timeSinceLastInputRead = AutoDrive.timeSinceLastInputRead + dt

	if AutoDrive.timeSinceLastTelemetryOutput >= AutoDrive.TelemetryOutputCycle then
		AutoDrive.outputTelemetry()
		if AutoDrive.shouldOutputStaticTelemetry then
			AutoDrive.outputStaticInfo()
			AutoDrive.shouldOutputStaticTelemetry = false
		end
	end
	if AutoDrive.timeSinceLastInputRead >= AutoDrive.InputReadCycle then
		AutoDrive.readNewInputs()
	end
end

function AutoDrive.readNewInputs()
	local fileID = AutoDrive.xmlFileName_inputs .. "_" .. (AutoDrive.lastReadChangeID+1) .. ".xml"
	local fileIDTest = AutoDrive.xmlFileName_inputs .. "_" .. (AutoDrive.lastReadChangeID+1) .. ".touch"
	if not fileExists(fileIDTest) then
		return
	end
	AutoDrive.xmlFile_inputs = loadXMLFile("AutoDrive_XML_inputs", fileID)

	local changeId = getXMLInt(AutoDrive.xmlFile_inputs, "AutoDrive.ChangeId")

	if changeId <= AutoDrive.lastReadChangeID then
		delete(AutoDrive.xmlFile_inputs) 
		return
	end

	AutoDrive.lastReadChangeID = changeId

	local selectedVehicle = getXMLInt(AutoDrive.xmlFile_inputs, "AutoDrive.currentVehicle")
	--g_logManager:info("[AD] selectedVehicle " .. selectedVehicle)
	local vehicle = g_currentMission.vehicles[selectedVehicle]

	local showingHud = getXMLBool(AutoDrive.xmlFile_inputs, "AutoDrive.HudShow")
	local selectedTarget = getXMLInt(AutoDrive.xmlFile_inputs, "AutoDrive.selectedTarget")
	local selectedSecondTarget = getXMLInt(AutoDrive.xmlFile_inputs, "AutoDrive.selectedSecondTarget")
	local selectedFruit = getXMLInt(AutoDrive.xmlFile_inputs, "AutoDrive.selectedFruit")
	local adActive = getXMLBool(AutoDrive.xmlFile_inputs, "AutoDrive.adActive")
	local mode = getXMLInt(AutoDrive.xmlFile_inputs, "AutoDrive.mode")
	local enterVehicle = getXMLBool(AutoDrive.xmlFile_inputs, "AutoDrive.enterVehicle")
	local continue = getXMLBool(AutoDrive.xmlFile_inputs, "AutoDrive.continue")
	local park = getXMLBool(AutoDrive.xmlFile_inputs, "AutoDrive.park")

	if vehicle ~= nil and vehicle.ad ~= nil then
		
		--g_logManager:info("[AD] found selectedVehicle " .. selectedVehicle)
		--local vehicle = g_currentMission.controlledVehicle

		if showingHud ~= nil and showingHud ~= AutoDrive.Hud.showHud then
			AutoDrive.Hud:toggleHud(vehicle)
		end

		if selectedTarget ~= nil and selectedTarget ~= -1 and (vehicle.ad.stateModule:getFirstMarker().markerIndex ~= selectedTarget) then
			AutoDriveHudInputEventEvent:sendFirstMarkerEvent(vehicle, selectedTarget)
		end

		if selectedSecondTarget ~= nil and selectedSecondTarget ~= -1 and (vehicle.ad.stateModule:getSecondMarker().markerIndex ~= selectedSecondTarget) then
			AutoDriveHudInputEventEvent:sendSecondMarkerEvent(vehicle, selectedSecondTarget)
		end

		if selectedFruit ~= nil and selectedFruit ~= -1 and (vehicle.ad.stateModule:getFillType() ~= selectedFruit) then
			AutoDriveHudInputEventEvent:sendFillTypeEvent(vehicle, selectedFruit)
		end

		if adActive ~= nil and adActive ~= vehicle.ad.stateModule:isActive() then
			AutoDrive.EnterVehicle(vehicle)
			ADInputManager:onInputCall(vehicle, "input_start_stop")
			AutoDrive.GoBackToCurrentVehicle()
		end

		if mode ~= nil and mode ~= vehicle.ad.stateModule:getMode() then
			vehicle.ad.stateModule:setMode(mode)
		end

		if enterVehicle ~= nil and enterVehicle == true and vehicle ~= g_currentMission.controlledVehicle then
			g_currentMission:requestToEnterVehicle(enterVehicle)
		end		

		if continue ~= nil and continue == true then
			vehicle.ad.stateModule:getCurrentMode():continue()
		end

		if park ~= nil and park == true then
			AutoDrive.EnterVehicle(vehicle)
			ADInputManager:onInputCall(vehicle, "input_parkVehicle")
			AutoDrive.GoBackToCurrentVehicle()
		end
	end

	AutoDrive.timeSinceLastInputRead = 0
	delete(AutoDrive.xmlFile_inputs) 
end

function AutoDrive.EnterVehicle(vehicle)	
	AutoDrive.RestoreVehicle = g_currentMission.controlledVehicle;
	g_currentMission:requestToEnterVehicle(vehicle)
end

function AutoDrive.GoBackToCurrentVehicle()
	g_currentMission:requestToEnterVehicle(AutoDrive.RestoreVehicle)
end

function AutoDrive.outputTelemetry()
	local outputTable = {}

	table.insert(outputTable, "lastReadChangeId:" .. AutoDrive.lastReadChangeID)
	table.insert(outputTable, "MapName:" .. AutoDrive.loadedMap)
	table.insert(outputTable, "HudShow:" .. AutoDrive.boolToString(AutoDrive.Hud.showHud))

	local vehiclesTable = {}
	for vehicleID, vehicle in pairs(g_currentMission.vehicles) do
		if vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
			AutoDrive.CreateOutputForVehicle(vehicle, vehicleID, vehiclesTable)
		end
		if vehicle == g_currentMission.controlledVehicle then
			table.insert(outputTable, "currentVehicleId:" .. vehicleID)
		end
	end
	table.insert(outputTable, "Vehicles:" .. table.concat(vehiclesTable, "|"))

	local file = io.open(AutoDrive.xmlFileName_telemetry, 'w')
	if file ~= nil then
		file:write(table.concat(outputTable, ";"))
		file:close()
	end

	AutoDrive.timeSinceLastTelemetryOutput = 0
end

function AutoDrive.CreateOutputForVehicle(vehicle, vehicleID, vehiclesTable)
	local vehicleTable = {}
	table.insert(vehicleTable, "adActive+" .. AutoDrive.boolToString(vehicle.ad.stateModule:isActive()))
	table.insert(vehicleTable, "firstMarker+" .. vehicle.ad.stateModule:getFirstMarkerId())
	table.insert(vehicleTable, "secondMarker+" .. vehicle.ad.stateModule:getSecondMarkerId())
	table.insert(vehicleTable, "mode+" .. vehicle.ad.stateModule:getMode())
	table.insert(vehicleTable, "name+" .. vehicle.ad.stateModule:getName())
	table.insert(vehicleTable, "fillType+" .. vehicle.ad.stateModule:getFillType())
	table.insert(vehicleTable, "fillTypeName+" .. g_fillTypeManager:getFillTypeByIndex(vehicle.ad.stateModule:getFillType()).title)
	
	table.insert(vehiclesTable, vehicleID .. "~" .. table.concat(vehicleTable, "*"))
end

function AutoDrive.outputStaticInfo()
	local outputTable = {}

	table.insert(outputTable, "lastReadChangeId:" .. AutoDrive.lastReadChangeID)
	
	local markerTable = {}
	for i in pairs(ADGraphManager:getMapMarkers()) do
		if not ADGraphManager:getMapMarkerById(i).isADDebug then		-- do not send debug map marker
			markerTable[i] = "" .. i .. "#" .. ADGraphManager:getMapMarkerById(i).name
		end
	end
	local markerString = table.concat(markerTable, "*")
	table.insert(outputTable, "Destinations:" .. markerString)

	AutoDrive.CreateFillTypeOutput(outputTable)

	local file = io.open(AutoDrive.xmlFileName_telemetry_static, 'w')
	file:write(table.concat(outputTable, ";"))
	file:close()
end

function AutoDrive.CreateFillTypeOutput(outputTable)
	
	local fillTypes = {}
    local fillTypeIndex = 1
    local lastIndexReached = false
    while not lastIndexReached do
        if g_fillTypeManager:getFillTypeByIndex(fillTypeIndex) ~= nil then
			if (not AutoDriveHud:has_value(AutoDrive.ItemFilterList, fillTypeIndex)) then
				table.insert(fillTypes, "" .. g_fillTypeManager:getFillTypeByIndex(fillTypeIndex).title .. "#" .. fillTypeIndex)
            end
        else
            lastIndexReached = true
        end
        fillTypeIndex = fillTypeIndex + 1
	end	
	
	table.insert(outputTable, "FillTypes:" .. table.concat(fillTypes, "*"))
end
