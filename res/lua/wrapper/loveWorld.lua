local loveWorld = {
    id = 0,
    bodies = 0,
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
    xg = 1,
    yg = 1,
    sleep = true,
    callback = {}
}

function loveWorld:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = o.id
    self.x1 = o.x1
    self.y1 = o.y1
    self.x2 = o.x2
    self.y2 = o.y2
    self.xg = o.xg
    self.yg = o.yg
    self.sleep = o.sleep
    return o
end

function loveWorld:setCallbacks(callbacks)
    self.callbacks = callbacks
end

function loveWorld:update(dt)
    
end

return loveWorld