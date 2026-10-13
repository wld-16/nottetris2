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
    local color = Color.new(r, g, b, a or 255)
    Graphics.drawPixel(x,y,color,self.id)
end

function loveImageData:paste(source, dx, dy, sx, sy, sw, sh)
    -- getWidth/getHeight report scaled dimensions, but the underlying vita2d
    -- texture is only the original size. Clamp to the real texture dimensions
    -- so getPixel/drawPixel never read or write out of bounds.
    local src_ps = source.pixelScale or 1
    local src_rw = source:getWidth() / src_ps
    local src_rh = source:getHeight() / src_ps

    if(sx == nil and sy == nil and sw == nil and sh == nil) then
        for index_y = dy, src_rh - 1, 1
        do
            for index_x = dx, src_rw - 1, 1
            do
                local color = Graphics.getPixel(index_x, index_y, source:getId())
                Graphics.drawPixel(index_x, index_y, color, self.id)
            end
        end
    else
        local eff_sw = math.min(sw, src_rw)
        local eff_sh = math.min(sh, src_rh)
        for index_y = sy, eff_sh - 1, 1
        do
            for index_x = sx, eff_sw - 1, 1
            do
                local color = Graphics.getPixel(index_x, index_y, source:getId())
                Graphics.drawPixel(dx + index_x, dy + index_y, color, self.id)
            end
        end
    end
end

return loveImageData



