AutoDrive.tipOfTheDay = {}
AutoDrive.tipOfTheDay.Entries = {}
AutoDrive.tipOfTheDay.Entries[1] = {}
AutoDrive.tipOfTheDay.Entries[1].imageFile = g_autoDriveTipOfTheDayUIFilename
AutoDrive.tipOfTheDay.Entries[1].imageUV = {0, 0, 128, 128}
AutoDrive.tipOfTheDay.Entries[1].imageSize = {128, 128}
AutoDrive.tipOfTheDay.Entries[1].text = "ad_totd_01_text"
AutoDrive.tipOfTheDay.Entries[1].titletext = "ad_totd_01_title"

AutoDrive.tipOfTheDay.Entries[2] = {}
AutoDrive.tipOfTheDay.Entries[2].imageFile = g_autoDriveTipOfTheDayUIFilename
AutoDrive.tipOfTheDay.Entries[2].imageUV = {0, 0, 128, 512}
AutoDrive.tipOfTheDay.Entries[2].imageSize = {128, 512}
AutoDrive.tipOfTheDay.Entries[2].text = "ad_totd_02_text"
AutoDrive.tipOfTheDay.Entries[2].titletext = "ad_totd_02_title"

AutoDrive.tipOfTheDay.Entries[3] = {}
AutoDrive.tipOfTheDay.Entries[3].imageFile = g_autoDriveTipOfTheDayUIFilename
AutoDrive.tipOfTheDay.Entries[3].imageUV = {128, 0, 128, 128}
AutoDrive.tipOfTheDay.Entries[3].imageSize = {128, 128}
AutoDrive.tipOfTheDay.Entries[3].text = "ad_totd_03_text"
AutoDrive.tipOfTheDay.Entries[3].titletext = "ad_totd_03_title"

AutoDrive.tipOfTheDay.Entries[4] = {}
AutoDrive.tipOfTheDay.Entries[4].imageFile = g_autoDriveTipOfTheDayUIFilename
AutoDrive.tipOfTheDay.Entries[4].imageUV = {128, 128, 128, 128}
AutoDrive.tipOfTheDay.Entries[4].imageSize = {128, 128}
AutoDrive.tipOfTheDay.Entries[4].text = "ad_totd_04_text"
AutoDrive.tipOfTheDay.Entries[4].titletext = "ad_totd_04_title"

AutoDrive.tipOfTheDay.currentTipId = 1
AutoDrive.tipOfTheDay.highestTipId = 1
AutoDrive.tipOfTheDay.displayedYet = true

AutoDrive.tipOfTheDay.delayTime = 500

function AutoDrive.initTipOfTheDay()
	
end

function AutoDrive.handleTipOfTheDay(dt)
	if not (g_server ~= nil and g_client ~= nil) then
		return
	end

	if AutoDrive.tipOfTheDay.delayTime > 0 then
		AutoDrive.tipOfTheDay.delayTime = AutoDrive.tipOfTheDay.delayTime - dt
		return
	end
	
	if (AutoDrive.getSetting("showTipOfTheDay") or AutoDrive.tipOfTheDay.Entries[AutoDrive.tipOfTheDay.highestTipId + 1] ~= nil) and not AutoDrive.tipOfTheDay.displayedYet then
		-- The idea is to still diplay new tips that arrived with a new AutoDrive version
		if not AutoDrive.getSetting("showTipOfTheDay") then
			AutoDrive.tipOfTheDay.currentTipId = AutoDrive.tipOfTheDay.highestTipId + 1
		end

		if not AutoDrive.gui.ADTipOfTheDayGUI.isOpen then
			g_gui:showGui("ADTipOfTheDayGui")
			AutoDrive.tipOfTheDay.displayedYet = true
		end
	end
end

function AutoDrive.showNextTipOfTheDay()
	AutoDrive.tipOfTheDay.currentTipId = AutoDrive.tipOfTheDay.currentTipId + 1
	if AutoDrive.tipOfTheDay.Entries[AutoDrive.tipOfTheDay.currentTipId] == nil then
		AutoDrive.tipOfTheDay.currentTipId = 1
	end

	AutoDrive.tipOfTheDay.highestTipId = math.max(AutoDrive.tipOfTheDay.highestTipId, AutoDrive.tipOfTheDay.currentTipId)
	AutoDrive.tipOfTheDay.currentTipOfTheDay = AutoDrive.tipOfTheDay.Entries[AutoDrive.tipOfTheDay.currentTipId]
end

function AutoDrive.toggleTipOfTheDay()
	if AutoDrive.getSetting("showTipOfTheDay") then
		AutoDrive.setSettingState("showTipOfTheDay", 1)
	else
		AutoDrive.setSettingState("showTipOfTheDay", 2)
	end
end