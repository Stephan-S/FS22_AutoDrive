ADGenericHudElement = {}
ADGenericHudElement_mt = {__index = ADGenericHudElement}

function ADGenericHudElement:init(posX, posY, width, height)
    --local newInst = {}
    --setmetatable(newInst, ADGenericHudElement_mt)
    self.position = {x = posX, y = posY}
    self.size = {width = width, height = height}
    self.layer = 10
    --return newInst;
end

function ADGenericHudElement:hit(posX, posY, layer)
    return layer <= self.layer and posX >= self.position.x and posX <= (self.position.x + self.size.width) and posY >= self.position.y and posY <= (self.position.y + self.size.height)
end

function ADGenericHudElement:mouseEvent(vehicle, posX, posY, isDown, isUp, button, layer)
    if self:hit(posX, posY, layer) then
        return self:act(vehicle, posX, posY, isDown, isUp, button)
    end
    return false
end

function ADGenericHudElement:onDraw(vehicle, uiScale)
end

function ADGenericHudElement:update(dt)
end

function ADGenericHudElement:moveTo(dx, dy)
    
end

function ADInheritsFrom(baseClass)
    local new_class = {}
    local class_mt = {__index = new_class}

    function new_class:create()
        local newinst = {}
        setmetatable(newinst, class_mt)
        return newinst
    end

    if nil ~= baseClass then
        setmetatable(new_class, {__index = baseClass})
    end

    -- Implementation of additional OO properties starts here --

    -- Return the class object of the instance
    function new_class:class()
        return new_class
    end

    -- Return the super class object of the instance
    function new_class:superClass()
        return baseClass
    end

    -- Return true if the caller is an instance of theClass
    function new_class:isa(theClass)
        local b_isa = false

        local cur_class = new_class

        while (nil ~= cur_class) and (false == b_isa) do
            if cur_class == theClass then
                b_isa = true
            else
                cur_class = cur_class:superClass()
            end
        end

        return b_isa
    end

    return new_class
end
