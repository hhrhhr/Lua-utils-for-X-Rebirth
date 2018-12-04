local lg = love.graphics
local scale = 1.0
local dds

for k, v in pairs(arg) do print(k, v) end

FNT  = arg[2] -- or [[fonts/rufont_32]]

local char = require("x4_abc2t")


function love.load()
    lg.setDefaultFilter("linear", "nearest")
    dds = lg.newImage(FNT..".png")

    lg.setDefaultFilter("linear", "linear")
    lg.setLineWidth(1)
end

function love.draw()
    lg.setColor(1.0, 1.0, 1.0)
    lg.setBackgroundColor(0.5, 0.5, 0.5, 0.5)
    lg.scale(scale, scale)
    lg.translate(10, 10)
    
    lg.draw(dds, 0, 0, 0, scaleDDS, scaleDDS)
--    love.graphics.scale(scale, scale)
    for i = 1, #char do
        local c = char[i]
        lg.setLineWidth(1.0)

        -- 1=x, 2=y, 3=w, 4=h, 5=off, 6=adv

        lg.setColor(0.3, 1.0, 0.3, 0.6)
        lg.rectangle("line", c[1], c[2], c[3], c[4])

--        lg.setLineWidth(1.5)

        lg.setColor(0.1, 0.1, 1.0, 0.3)
--        lg.polygon("fill", c[1]-c[5], c[2]+c[4], c[1], c[2], c[1], c[2]+c[4])
        lg.rectangle("fill", c[1]-c[5], c[2], c[5], c[4])

        lg.setColor(1.0, 0.1, 0.5, 0.3)
--        lg.polygon("fill", c[1]+c[3], c[2], c[1]+c[6], c[2], c[1]+c[3], c[2]+c[4])
        lg.rectangle("fill", c[1]+c[3], c[2], c[6]-c[3], c[4])

--        lg.setColor(1.0, 0.3, 1.0)
--        lg.line(c[1]-c[5], c[2], c[1]+c[6], c[2]+c[4])
    end
end

function love.keyreleased(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "1" then scale = 0.5
    elseif key == "2" then scale = 1.0
    elseif key == "3" then scale = 2.0
    elseif key == "4" then scale = 4.0
    end
end
