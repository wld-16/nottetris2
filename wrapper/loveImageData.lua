--
-- Created by IntelliJ IDEA.
-- User: spacewave
-- Date: 08.03.2021
-- Time: 18:46
-- To change this template use File | Settings | File Templates.
--


local loveImageData = {
    id = 0,
    height = 0,
    width = 0
}

function loveImageData:new(o) 
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.id = o.id or 0
    self.width = o.width or 0
    self.height = o.height or 0
    return o
end

function loveImageData:setFilter (filterWidth, filterHeigth)
    self.filterWidth = filterWidth
    self.filterHeigth = filterHeigth
end


function loveImageData:getHeight()
    return self.height
end

function loveImageData:getWidth()
    return self.width
end

function loveImageData:getPixel(x, y)
    return Graphics.getPixel(x, y, self.id)
end

function loveImageData:setPixel(x, y, r, g, b, a)
    Graphics.drawPixel(x,y,Color.new(r, g, b))
end


-- TODO: There might occur bugs here
function loveImageData:paste(imageData, x, y)
    for index_y = y,imageData.height,1
    do
        for index_x = x,imageData.width,1
        do
            Graphics.drawPixel(index_x,index_y, Graphics.getPixel(x,y,imageData.id),loveImageData.id)
        end
    end
end

function loveImageData:toString() 
    return "id: " .. loveImageData.id .. "\nheigth: " .. loveImageData.height .. "\nwidth: " .. loveImageData.width
end

return loveImageData