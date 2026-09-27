local loveRectangleShape = {
    id = 0,
    body = 0,
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    angle = 0,
    data = {}
}

function loveRectangleShape:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = o.id or 0
    self.body = o.body or {}
    o.body:addShape(self)
    self.x = o.x or 0
    self.y = o.y or 0
    self.width = o.width or 0
    self.height = o.height or 0
    self.angle = o.angle or 0
    return o
end

function loveRectangleShape:setData(v)
    self.data = v
end

function loveRectangleShape:getWidth()
    return self.width
end

function loveRectangleShape:getHeight()
    return self.height
end

return loveRectangleShape