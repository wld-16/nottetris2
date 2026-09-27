local loveBody = {
    id = 0,
    world = {},
    x = 0,
    y = 0,
    m = 0,
    i = 0,
    ld = 0,
    lvx = 0,
    lvy = 0,
    shapes = {},
    isBullet = false
}

function loveBody:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = o.id or 0
    self.world = o.world
    self.x = o.x or 0
    self.y = o.y or 0
    self.m = o.m or 0
    self.i = o.i or 0
    return o
end

function loveBody:getX()
    return self.x
end

function loveBody:getY()
    return self.y
end

function loveBody:getAngle()
    return 0
end

function loveBody:setLinearDamping(ld)
    self.ld = ld
end

function loveBody:setMassFromShapes()
    for i = 1, #self.shapes do
        self.m = self.m + self.shapes[i]:getWidth() * self.shapes[i]:getHeight()
    end
end

function loveBody:addShape(shape)
    table.insert(self.shapes, shape)
end

function loveBody:setBullet(status)
    self.isBullet = status
end

function loveBody:setLinearVelocity(lvx, lvy)
    self.lvx = lvx
    self.lvy = lvy
end

return loveBody