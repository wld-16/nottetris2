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

-- Fields go on the instance, not on `self`: assigning through `self` here writes
-- them onto the LoveImageData class itself, so every image would overwrite the
-- id, width and height seen by all the others.
function loveImageData:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.id = o.id or 0
    o.width = o.width or 0
    o.height = o.height or 0
    o.pixelScale = o.pixelScale or 1
    return o
end

function loveImageData:setFilter(filterWidth, filterHeight)
    self.filterWidth = filterWidth
    self.filterHeight = filterHeight
end

function loveImageData:getId()
    return self.id
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
    Graphics.drawPixel(x,y,Color.new(r, g, b),self.id)
end


-- TODO: There might occur bugs here
function loveImageData:paste(imageData, x, y)
    for index_y = y, imageData:getHeight(), 1
    do
       for index_x = x, imageData:getWidth(), 1
       do
            local color = Graphics.getPixel(index_x, index_y, imageData:getId())
            Graphics.drawPixel(index_x, index_y, color, self.id)
        end
    end
end

return loveImageData



