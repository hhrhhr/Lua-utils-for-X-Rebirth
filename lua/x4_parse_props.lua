local conf = require("x4_config")

local header = {
    ["shieldgenerator"] = {0,
        {"name", "race", "mk", "recharge", "rate", "delay", "time", "hull",
            "tresh.", "int.", "macro"}
    },
    ["engine"] = {0,
        {"name", "race", "mk", "b_duration", "b_thrust", "tr_duration",
            "tr_thrust", "tr_attack", "tr_release", "thr_forward", "thr_reverse",
            "macro"}
    },
    ["thruster"] = {0,
        {"name", "mk", "strafe", "pitch", "yaw", "roll", "ang_pitch",
            "ang_roll", "macro"}
    },
    ["ship"] = {0,
        {"name", "missile", "hull", "secrecy", "purpose", "people", "i_pitch",
            "i_yaw", "i_roll", "d_fwd", "d_rev", "d_hor", "d_ver", "d_pitch",
            "d_yaw", "d_roll", "thruster", "tags", "macro"}
    },
}


--[[ lang stuff ]]-------------------------------------------------------------

local L = require(conf.lang)

function L:get(p, t)
    local function Lget(a, b, c)
        if b == "" then b = p end
        return self[tonumber(b)][tonumber(c)]
    end
    local s = (p and t) and L[p][t] or p
    local c
    while 0 ~= c do
        s, c = s:gsub("({(%d*),[ ]-(%d+)})", Lget)  -- перенаправление вида '{page,id}' или '{,id}'
        s = s:gsub("\\%(", "<<")  -- убиваем скобки
        s = s:gsub("\\%)", ">>")  -- убиваем скобки
    end
    s = s:gsub("(%([^%)]+%))", "")  -- убиваем скобки
    s = s:gsub("<<", "(")  -- убиваем скобки
    s = s:gsub(">>", ")")  -- убиваем скобки

    return s
end

--[[ xml stuff ]]--------------------------------------------------------------

local xml2lua = require("xml2lua")
local xml_tree = require("xmlhandler.tree")

local function exist(filename)
    local r = io.open(filename, "rb")
    return r ~= nil and r:close() or false
end

local function load_xml(filename)
    local xml_to_load = conf.res_dir .. conf.sep .. filename
    local xml, handler
    local f, e = io.open(xml_to_load, "rb")
    if f then
        xml = f:read("a")
        f:close()
    else
        --        io.stderr:write(e, "\n")
        xml = ""
    end
    handler = xml_tree:new()
    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    return handler
end


--[[ parse all macros ]]-------------------------------------------------------

local function parse_shield(m)
    print(m._attr.name)
    local t = {}
    local prop = m.properties

    local p = prop.identification._attr
    table.insert(t, L:get(p.name or "--"))
    --    io.write(L:get(p.basename or "--"), "\t") -- 'Shield Generator'
    --    io.write(L:get(p.shortname or "--"), "\t") -- 'Shield Mk?'
    table.insert(t, p.makerrace)
    --    io.write(L:get(p.description or "--"), "\t") -- 'No information available'
    table.insert(t, p.mk)

    p = prop.recharge._attr
    table.insert(t, p.max)
    table.insert(t, p.rate)
    table.insert(t, p.delay)

    table.insert(t, (p.max / p.rate / 86400))

    p = prop.hull._attr
    table.insert(t, (p.max or "0"))
    table.insert(t, (p.threshold or "0"))
    table.insert(t, (p.integrated or "0"))

    table.insert(t, m._attr.name)

    header["shieldgenerator"][1]:write(table.concat(t, "\t"), "\n")
end

local function parse_engine(m)
    print(m._attr.name)
    local t = {}
    local prop = m.properties

    local p = prop.identification and prop.identification._attr or {}
    table.insert(t, L:get(p.name or "--"))
    --    table.insert(t, L:get(p.basename or "--"))
    --    table.insert(t, L:get(p.shortname or "--"))
    table.insert(t, (p.makerrace or "--"))
    --    table.insert(t, L:get(p.description or "--"))
    table.insert(t, (p.mk or "--"))

    p = prop.boost and prop.boost._attr or {}
    table.insert(t, (p.duration or "--"))
    table.insert(t, (p.thrust or "--"))
    --    table.insert(t, (p.attack or "--")) -- 0.25
    --    table.insert(t, (p.release or "--")) -- 1

    p = prop.travel and prop.travel._attr or {}
    table.insert(t, p.charge or "--")
    table.insert(t, p.thrust or "--")
    table.insert(t, p.attack or "--")
    table.insert(t, p.release or "--")

    p = prop.thrust and prop.thrust._attr or {}
    table.insert(t, p.forward or "--")
    table.insert(t, p.reverse or "--")

    table.insert(t, m._attr.name)

    header["engine"][1]:write(table.concat(t, "\t"), "\n")
end

local function parse_thruster(m)
    print(m._attr.name)
    local t = {}
    local prop = m.properties

    local p = prop.identification and prop.identification._attr or {}
    table.insert(t, L:get(p.name or "--"))
    --    table.insert(t, L:get(p.basename or "--"))
    --    table.insert(t, L:get(p.shortname or "--"))
    --    table.insert(t, (p.unique or "--")) -- 0
    --    table.insert(t, L:get(p.description or "--"))
    table.insert(t, (p.mk or "--"))

    p = prop.thrust and prop.thrust._attr or {}
    table.insert(t, (p.strafe or "--"))
    table.insert(t, (p.pitch or "--"))
    table.insert(t, (p.yaw or "--"))
    table.insert(t, (p.roll or "--"))

    p = prop.angular and prop.angular._attr or {}
    table.insert(t, (p.pitch or "--"))
    table.insert(t, (p.roll or "--"))

    --    p = prop.hull and prop.hull._attr or {}
    --    table.insert(t, (p.integrated or "0")) -- 1

    table.insert(t, m._attr.name)

    header["thruster"][1]:write(table.concat(t, "\t"), "\n")
end

local function parse_ship(m)
    print(m._attr.name, m._attr.class)
    local t = {}
    local prop = m.properties

    local p = prop.identification and prop.identification._attr or {}
    table.insert(t, L:get(p.name or "--"))
    --    table.insert(t, L:get(p.basename or "--"))
    --    table.insert(t, L:get(p.description or "--"))
    --    table.insert(t, L:get(p.variation or "--"))
    --    table.insert(t, L:get(p.shortvariation or "--"))
    --    table.insert(t, L:get(p.icon or "--"))

    p = prop.storage and prop.storage._attr or {}
    table.insert(t, p.missile or "--")

    p = prop.hull and prop.hull._attr or {}
    table.insert(t, p.max or "--")

    p = prop.secrecy and prop.secrecy._attr or {}
    table.insert(t, p.level or "--")

    p = prop.purpose and prop.purpose._attr or {}
    table.insert(t, p.primary or "--")

    p = prop.people and prop.people._attr or {}
    table.insert(t, p.capacity or "--")

    p = (prop.physics and prop.physics.inertia and prop.physics.inertia._attr) or {}
    table.insert(t, p.pitch or "--")
    table.insert(t, p.yaw or "--")
    table.insert(t, p.roll or "--")

    p = (prop.physics and prop.physics.drag and prop.physics.drag._attr) or {}
    table.insert(t, p.forward or "--")
    table.insert(t, p.reverse or "--")
    table.insert(t, p.horizontal or "--")
    table.insert(t, p.vertical or "--")
    table.insert(t, p.pitch or "--")
    table.insert(t, p.yaw or "--")
    table.insert(t, p.roll or "--")

    p = prop.thruster and prop.thruster._attr or {}
    table.insert(t, p.tags or "--")

    p = prop.ship and prop.ship._attr or {}
    table.insert(t, p.type or "--")


    table.insert(t, m._attr.name)

    header["ship"][1]:write(table.concat(t, "\t"), "\n")
end


local function parse_macro(macro)
    local m = macro._attr
    if m then
        local class = m.class
        if "shieldgenerator" == class then
            if m.name:find("test") ~= 1 then
                parse_shield(macro)
            end
        elseif "engine" == class then
            if m.name:find("eng") == 1 then
                parse_engine(macro)
            elseif m.name:find("thr") == 1 then
                parse_thruster(macro)
            end
        elseif class and "ship_" == class:sub(1, 5) then
            if m.name:find("dummy") ~= 1 then
                parse_ship(macro)
            end
        end
    end
end

local function start_parse()
    local h = load_xml("index/macros.xml")
    local entry = h and h.root.index.entry
    for i = 1, #entry do
        local e = entry[i]._attr
        local fn = e.value:gsub("\\\\", "/")
        fn = fn:gsub("\\", "/")
        local h = load_xml(fn .. ".xml")

        local macro = h and h.root.macros and h.root.macros.macro
        if macro then
            local count = #macro
            if 0 == count then
                parse_macro(macro)
            else
                for j = 1, count do
                    parse_macro(macro[j])
                end
            end
        end
    end
end


--[[ main ]]-------------------------------------------------------------------

for k, v in pairs(header) do
    v[1] = io.open(k .. ".csv", "w+b")
    v[1]:write(table.concat(v[2], "\t"), "\n")
end

start_parse()

for k, v in pairs(header) do
    v[1]:close()
end
