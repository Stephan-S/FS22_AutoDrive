AbstractTask = {}
AbstractTask_mt = {__index = AbstractTask}

function AbstractTask:setUp()
end

function AbstractTask:update(dt)
end

function AbstractTask:abort()
end

function AbstractTask:finished()
end

function AbstractTask:getInfoText()
    return nil
end

function AbstractTask:getI18nInfo()
    return ""
end

function AbstractTask:getExcludedVehiclesForCollisionCheck()
    return {}
end
