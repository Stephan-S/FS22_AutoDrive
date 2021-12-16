HudHarvesterInfo = ADInheritsFrom(ADGenericHudElement)

function HudHarvesterInfo:new(posX, posY, width, height)
    local o = HudHarvesterInfo:create()
    o:init(posX, posY, width, height)    

    o.layer = 5

    return o
end

function HudHarvesterInfo:onDraw(vehicle, uiScale)
    if (vehicle.ad.isCombine and (vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DELIVERTO or vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DRIVETO)) or vehicle.ad.stateModule:getMode() == AutoDrive.MODE_UNLOAD then
        if AutoDrive.pullDownListExpanded == 0 or AutoDrive.Hud.targetPullDownList.direction == ADPullDownList.EXPANDED_UP then

            local text = ""
            setTextColor(1, 1, 1, 1)

            if vehicle.ad.isCombine then
                if not ADHarvestManager:hasHarvesterPotentialUnloaders(vehicle) then
                    setTextColor(1, 0, 0, 1)
                    text = g_i18n:getText("gui_ad_noUnloaderAvailable")
                end
            else
                if not ADHarvestManager:hasVehiclePotentialHarvesters(vehicle) then
                    setTextColor(1, 0, 0, 1)
                    text = g_i18n:getText("gui_ad_noHarvesterAvailable")
                end
            end

            local adFontSize = AutoDrive.FONT_SCALE * uiScale
            setTextAlignment(RenderText.ALIGN_LEFT)
            
            local posX = self.position.x --+ (self.size.width / 2)
            local posY = self.position.y + (self.size.height / 2)
            renderText(posX, posY, adFontSize, text)
        end
    end
end

function HudHarvesterInfo:act(vehicle, posX, posY, isDown, isUp, button)
    return false
end
