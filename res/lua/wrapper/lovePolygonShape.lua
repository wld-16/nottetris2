local lovePolygonShape = {
    id = 0,
    body = {},
    points = {},
    data = {},
    friction = 0
}

function lovePolygonShape:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.points = o.points or {}
    o.body = o.body or {}
    o.body:addShape(o)
    return o
end

function lovePolygonShape:setData(v)
    self.data = v
    Physics.setShapeData(self.id, v)
end

function lovePolygonShape:setFriction(friction)
    Physics.setFriction(self.id, friction)
    self.friction = friction
end

function lovePolygonShape:getPoints()
    local numbers = Physics.getPoints(self.id)
    local points = {}
    for i, v in ipairs(numbers) do
        if(i == 1) then
            points.x1 = v
        elseif (i == 2) then
            points.y1 = v
        elseif (i == 3) then
            points.x2 = v
        elseif (i == 4) then
            points.y2 = v
        elseif (i == 5) then
            points.x3 = v
        elseif (i == 6) then
            points.y3 = v
        elseif (i == 7) then
            points.x4 = v
        elseif (i == 8) then
            points.y4 = v
        elseif (i == 9) then
            points.x5 = v
        elseif (i == 10) then
            points.y5 = v
        elseif (i == 11) then
            points.x6 = v
        elseif (i == 12) then
            points.y6 = v
        elseif (i == 13) then
            points.x7 = v
        elseif (i == 14) then
            points.y7 = v
        elseif (i == 15) then
            points.x8 = v
        elseif (i == 16) then
            points.y8 = v
        end
    end
end

function lovePolygonShape:testSegment( x1, y1, x2, y2)
    return Physics.testSegment(self.id, x1, y1, x2, y2)
end

return lovePolygonShape