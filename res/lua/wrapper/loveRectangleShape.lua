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
    o.id = o.id or 0
    o.body = o.body or {}
    o.body:addShape(o)
    o.x = o.x or 0
    o.y = o.y or 0
    o.width = o.width or 0
    o.height = o.height or 0
    o.angle = o.angle or 0
    return o
end

function loveRectangleShape:setData(v)
    self.data = v
    Physics.setShapeData(self.id, v)
end

function loveRectangleShape:getWidth()
    return self.width
end

function loveRectangleShape:getHeight()
    return self.height
end

function loveRectangleShape:getPoints()
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

return loveRectangleShape