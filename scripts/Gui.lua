function AutoDrive:loadGUI()
	GuiOverlay.loadOverlay = AutoDrive.overwrittenStaticFunction(GuiOverlay.loadOverlay, AutoDrive.GuiOverlay_loadOverlay)

	g_gui:loadProfiles(AutoDrive.directory .. "gui/guiProfiles.xml")
	AutoDrive.gui = {}
	AutoDrive.gui.ADEnterDriverNameGui = ADEnterDriverNameGui.new()
	AutoDrive.gui.ADEnterTargetNameGui = ADEnterTargetNameGui.new()
	AutoDrive.gui.ADEnterGroupNameGui = ADEnterGroupNameGui.new()
	AutoDrive.gui.ADEnterDestinationFilterGui = ADEnterDestinationFilterGui.new()
	AutoDrive.gui.ADRoutesManagerGui = ADRoutesManagerGui:new()
	AutoDrive.gui.ADNotificationsHistoryGui = ADNotificationsHistoryGui:new()
	AutoDrive.gui.ADColorSettingsGui = ADColorSettingsGui:new()
    local count = 1
    local result = nil
	result = g_gui:loadGui(AutoDrive.directory .. "gui/enterDriverNameGUI.xml", "ADEnterDriverNameGui", AutoDrive.gui.ADEnterDriverNameGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/enterTargetNameGUI.xml", "ADEnterTargetNameGui", AutoDrive.gui.ADEnterTargetNameGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/enterGroupNameGUI.xml", "ADEnterGroupNameGui", AutoDrive.gui.ADEnterGroupNameGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/enterDestinationFilterGUI.xml", "ADEnterDestinationFilterGui", AutoDrive.gui.ADEnterDestinationFilterGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/routesManagerGUI.xml", "ADRoutesManagerGui", AutoDrive.gui.ADRoutesManagerGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/notificationsHistoryGUI.xml", "ADNotificationsHistoryGui", AutoDrive.gui.ADNotificationsHistoryGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/colorSettingsGUI.xml", "ADColorSettingsGui", AutoDrive.gui.ADColorSettingsGui)

    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	AutoDrive.gui.ADSettingsPage = ADSettingsPage:new()
	AutoDrive.gui.ADUserSettingsPage = ADSettingsPage:new()
	AutoDrive.gui.ADVehicleSettingsPage = ADSettingsPage:new()
	AutoDrive.gui.ADCombineUnloadSettingsPage = ADSettingsPage:new()
	AutoDrive.gui.ADEnvironmentSettingsPage = ADSettingsPage:new()
	AutoDrive.gui.ADDebugSettingsPage = ADDebugSettingsPage:new()
	AutoDrive.gui.ADExperimentalFeaturesSettingsPage = ADExperimentalFeaturesSettingsPage:new()
	AutoDrive.gui.ADSettings = ADSettings:new()

	result = g_gui:loadGui(AutoDrive.directory .. "gui/settingsPage.xml", "ADSettingsFrame", AutoDrive.gui.ADSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/userSettingsPage.xml", "ADUserSettingsFrame", AutoDrive.gui.ADUserSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/vehicleSettingsPage.xml", "ADVehicleSettingsFrame", AutoDrive.gui.ADVehicleSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/combineUnloadSettingsPage.xml", "ADCombineUnloadSettingsFrame", AutoDrive.gui.ADCombineUnloadSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/environmentSettingsPage.xml", "ADEnvironmentSettingsFrame", AutoDrive.gui.ADEnvironmentSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/debugSettingsPage.xml", "ADDebugSettingsFrame", AutoDrive.gui.ADDebugSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/experimentalFeaturesSettingsPage.xml", "ADExperimentalFeaturesSettingsFrame", AutoDrive.gui.ADExperimentalFeaturesSettingsPage, true)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
	result = g_gui:loadGui(AutoDrive.directory .. "gui/settings.xml", "ADSettings", AutoDrive.gui.ADSettings)
    count = count + 1
    if result == nil then
        AutoDrive.debugMsg(nil, "AutoDrive:loadGUI failed count %d", count)
    end
end

function AutoDrive.GuiOverlay_loadOverlay(superFunc, ...)
	local overlay = superFunc(...)
	if overlay == nil then
		return nil
	end

	if overlay.filename == "g_autoDriveDebugUIFilename_BC7" then
		overlay.filename = g_autoDriveDebugUIFilename_BC7
	elseif overlay.filename == "g_autoDriveDebugUIFilename" then
		overlay.filename = g_autoDriveDebugUIFilename
	elseif overlay.filename == "g_autoDriveUIFilename" then
		overlay.filename = g_autoDriveUIFilename
	end

	return overlay
end

function AutoDrive.onOpenSettings()
	if AutoDrive.gui.ADSettings.isOpen then
		AutoDrive.gui.ADSettings:onClickBack()
	elseif g_gui.currentGui == nil then
		g_gui:showGui("ADSettings")
	end
end

function AutoDrive.onOpenEnterDriverName()
	if not AutoDrive.gui.ADEnterDriverNameGui.isOpen then
		g_gui:showGui("ADEnterDriverNameGui")
	end
end

function AutoDrive.onOpenEnterTargetName()
	if not AutoDrive.gui.ADEnterTargetNameGui.isOpen then
		g_gui:showGui("ADEnterTargetNameGui")
	end
end

function AutoDrive.onOpenEnterGroupName()
	if not AutoDrive.gui.ADEnterGroupNameGui.isOpen then
		g_gui:showGui("ADEnterGroupNameGui")
	end
end

function AutoDrive.onOpenEnterDestinationFilter()
	if not AutoDrive.gui.ADEnterDestinationFilterGui.isOpen then
		g_gui:showGui("ADEnterDestinationFilterGui")
	end
end

function AutoDrive.onOpenRoutesManager()
	if not AutoDrive.gui.ADRoutesManagerGui.isOpen then
		g_gui:showGui("ADRoutesManagerGui")
	end
end

function AutoDrive.onOpenNotificationsHistory()
	if not AutoDrive.gui.ADNotificationsHistoryGui.isOpen then
		g_gui:showGui("ADNotificationsHistoryGui")
	end
end

function AutoDrive.onOpenColorSettings()
	if not AutoDrive.gui.ADColorSettingsGui.isOpen then
		g_gui:showGui("ADColorSettingsGui")
	end
end
