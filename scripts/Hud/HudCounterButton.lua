ADHudCounterButton = ADInheritsFrom(ADGenericHudElement)

ADHudCounterButton.STATE_INFINITE = 1
ADHudCounterButton.STATE_ACTIVE = 2
ADHudCounterButton.STATE_INACTIVE = 3

function ADHudCounterButton:new(posX, posY, width, height, mode)
    local o = ADHudCounterButton:create()
    o:init(posX, posY, width, height)
    o.state = 1
    o.counter = 1
    o.mode = mode

    o.images = {
        [ADHudCounterButton.STATE_INFINITE] = AutoDrive.directory .. "textures/" .. mode .. "_inf.dds",
        [ADHudCounterButton.STATE_ACTIVE] = AutoDrive.directory .. "textures/" .. mode .. "_active.dds",
        [ADHudCounterButton.STATE_INACTIVE] = AutoDrive.directory .. "textures/" .. mode .. "_inactive.dds",
    }

    o.layer = 5
    o.ov = Overlay.new(o.images[o.state], o.position.x, o.position.y, o.size.width, o.size.height)
    return o
end

function ADHudCounterButton:updateState(vehicle)
    local newState, newCounter = self:getNewState(vehicle)
    self.ov:setImage(self.images[newState])
    self.state = newState
    self.counter = newCounter
end

function ADHudCounterButton:getNewState(vehicle)
    local newState = self.state
    local newCounter = self.counter
    if self.mode == "loop_counter" then
        if vehicle.ad.stateModule:getLoopCounter() == 0 then
            newState = ADHudCounterButton.STATE_INFINITE
            newCounter = -1
        else
            newCounter = math.max(0, vehicle.ad.stateModule:getLoopCounter() - vehicle.ad.stateModule:getLoopsDone())
            if vehicle.ad.stateModule:isActive() and vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER then
                newState = ADHudCounterButton.STATE_ACTIVE
            else
                newState = ADHudCounterButton.STATE_INACTIVE
            end
        end
    end
    return newState, newCounter

end

function ADHudCounterButton:onDraw(vehicle, uiScale)
    self:updateState(vehicle)
    self.ov:render()

    if self.state ~= ADHudCounterButton.STATE_INFINITE then
        local adFontSize = AutoDrive.FONT_SCALE * uiScale
        if self.state == ADHudCounterButton.STATE_ACTIVE then
            setTextColor(0.16, 0.76, 0.93, 1)
        else
            setTextColor(1, 1, 1, 1)
        end
        setTextAlignment(RenderText.ALIGN_CENTER)
        local text = string.format("%d", self.counter)
        local posX = self.position.x + (self.size.width / 2)
        local posY = self.position.y + AutoDrive.Hud.gapHeight
        renderText(posX, posY, adFontSize, text)
    end
end


-- Helper functions to wrap the 3 boolean flags into an int and back.
ADHudCounterButton.FLAG_INCREMENT = 1
ADHudCounterButton.FLAG_FAST = 2
ADHudCounterButton.FLAG_WHEEL = 4


function ADHudCounterButton.flags_to_int(increment, fast, wheel)
    return (increment and ADHudCounterButton.FLAG_INCREMENT or 0) +
           (fast and ADHudCounterButton.FLAG_FAST or 0) +
           (wheel and ADHudCounterButton.FLAG_WHEEL or 0)
end

function ADHudCounterButton.int_to_flags(value)
    return bitAND(value, ADHudCounterButton.FLAG_INCREMENT) > 0, bitAND(value, ADHudCounterButton.FLAG_FAST) > 0, bitAND(value, ADHudCounterButton.FLAG_WHEEL) > 0
end


function ADHudCounterButton:act(vehicle, posX, posY, isDown, isUp, button)
    if not isUp or button < 1 or button > 5 then
        return false
    end

    local increment = (button == 1) or (button == 4)
    local wheel = (button == 4) or (button == 5)
    local fast = AutoDrive.leftLSHIFTmodifierKeyPressed

    if wheel then
        AutoDrive.mouseWheelActive = true
    end

    if self.mode == "loop_counter" then
        AutoDriveHudInputEventEvent:sendChangeLoopCounterEvent(vehicle, increment, fast, wheel)
        return true
    end

    return false
end
