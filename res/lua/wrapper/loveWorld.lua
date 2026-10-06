local loveWorld = {
    id = 0,
    bodies = 0,
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
    xg = 1,
    yg = 1,
    sleep = false,
    callback = {}
}

function loveWorld:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id
    o.x1 = o.x1
    o.y1 = o.y1
    o.x2 = o.x2
    o.y2 = o.y2
    o.xg = o.xg
    o.yg = o.yg
    o.sleep = o.sleep
    return o
end

function loveWorld:setCallbacks(callbacks)
    Physics.setCallbacks(self.id, callbacks)
end

function loveWorld:update(dt)
    Physics.update(self.id, dt)
end

return loveWorld