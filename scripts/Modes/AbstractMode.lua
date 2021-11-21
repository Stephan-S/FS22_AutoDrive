AbstractMode = {}
AbstractMode_mt = {__index = AbstractMode}

function AbstractMode:start()
end

function AbstractMode:reset()
end

function AbstractMode:monitorTasks(dt)
end

function AbstractMode:handleFinishedTask()
end

function AbstractMode:stop()
end

function AbstractMode:continue()
end

function AbstractMode:shouldLoadOnTrigger()
    return false
end

function AbstractMode:shouldUnloadAtTrigger()
    return false
end

function AbstractMode:allowedToRefuel()
    return true
end
