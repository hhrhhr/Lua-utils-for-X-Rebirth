local conf = require("x4_config")

local header = {
    ["shield"] = {
        f_handle = 0,
        str = {"name", "race", "mk", "recharge", "rate", "delay", "time", "hull", "tresh", "int", "macro"}
    },
    ["engine"] = {
        f_handle = 0,
        str = {"name", "race", "mk", "bst_duration", "bst_thrust", "trv_duration", "trv_thrust", "trv_attack", "trv_release", "thr_forward", "thr_reverse", "macro"}
    },
    ["thruster"] = {
        f_handle = 0,
        str = {"name", "mk", "strafe", "pitch", "yaw", "roll", "ang_pitch", "ang_roll", "macro"}
    },
    ["ship"] = {
        f_handle = 0, 
        str ={"basename", "variation", "exp_dmg", "missile", "hull", "secrecy", "purpose", "people", "mass", "thruster", "tags", "engines", "weapons", "turrets", "shields", "cargo", "type", "i_pitch", "i_yaw", "i_roll", "d_fwd", "d_rev", "d_hor", "d_ver", "d_pitch", "d_yaw", "d_roll", "macro"}
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
        -- '{page,id}', '{,id}', '{page, id}', '{, id}'
        s, c = s:gsub("({(%d*),[ ]-(%d+)})", Lget)
        s = s:gsub("\\%(", "<<")
        s = s:gsub("\\%)", ">>")
    end
    s = s:gsub("(%([^%)]+%))", "")  -- убиваем скобки
    s = s:gsub("<<", "(")
    s = s:gsub(">>", ")")

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
        -- io.stderr:write(e, "\n")
        xml = ""
    end
    handler = xml_tree:new()
    local parser = xml2lua.parser(handler)
    parser:parse(xml)

    return handler
end


--[[ index stuff ]]--------------------------------------------------------

local index = { macro = {}, component = {} }

local function parse_index()
    local h = load_xml("index/components.xml")
    local entry = h and h.root.index.entry
    for i = 1, #entry do
        local e = entry[i]._attr
        local fn = e.value:gsub("\\\\", "/")
        fn = fn:gsub("\\", "/")
        index.component[e.name] = e.value
    end

    h = load_xml("index/macros.xml")
    entry = h and h.root.index.entry
    for i = 1, #entry do
        local e = entry[i]._attr
        local fn = e.value:gsub("\\\\", "/")
        fn = fn:gsub("\\", "/")
        index.macro[e.name] = e.value
    end
end


local function count_tags(model)
    local fn = index.component[model]
    local h = load_xml(fn .. ".xml")
    local c = h.root.components.component
    local a = c._attr
    --    assert(model == a.name)
    local e, w, t, s = 0, 0, 0, 0
    local con = c.connections.connection
    for i = 1, #con do
        local c = con[i]
        local tags = c._attr.tags
        for tag in string.gmatch(tags, "[^ ]+") do
            if "engine" == tag then e = e + 1
            elseif "weapon" == tag then w = w + 1
            elseif "turret" == tag then t = t + 1
            elseif "shield" == tag then s = s + 1
            end
        end
    end
    return e, w, t, s
end

local function parse_storage(s)
    local fn = index.macro[s]
    local h = load_xml(fn .. ".xml")
    local p = h.root.macros.macro.properties
    local c = p.cargo._attr
    return c.max, c.tags
end


--[[ parse all macros ]]-------------------------------------------------------

local function parse_shield(m)
    print(m._attr.name, m._attr.class)
    local t = {}
    local prop = m.properties

    local p = prop.identification._attr
    table.insert(t, L:get(p.name or "--"))
    --table.insert(t, L:get(p.basename or "--")) -- 'Shield Generator'
    --table.insert(t, L:get(p.shortname or "--")) -- 'Shield Mk?'
    table.insert(t, p.makerrace)
    --table.insert(t, L:get(p.description or "--")) -- 'No information available'
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

    header["shield"].f_handle:write(table.concat(t, "\t"), "\n")
end

local function parse_engine(m)
    print(m._attr.name, m._attr.class)
    local t = {}
    local prop = m.properties

    local p = prop.identification and prop.identification._attr or {}
    table.insert(t, L:get(p.name or "--"))
    --table.insert(t, L:get(p.basename or "--"))
    --table.insert(t, L:get(p.shortname or "--"))
    table.insert(t, (p.makerrace or "--"))
    --table.insert(t, L:get(p.description or "--"))
    table.insert(t, (p.mk or "--"))

    p = prop.boost and prop.boost._attr or {}
    table.insert(t, (p.duration or "--"))
    table.insert(t, (p.thrust or "--"))
    --table.insert(t, (p.attack or "--")) -- 0.25
    --table.insert(t, (p.release or "--")) -- 1

    p = prop.travel and prop.travel._attr or {}
    table.insert(t, p.charge or "--")
    table.insert(t, p.thrust or "--")
    table.insert(t, p.attack or "--")
    table.insert(t, p.release or "--")

    p = prop.thrust and prop.thrust._attr or {}
    table.insert(t, p.forward or "--")
    table.insert(t, p.reverse or "--")

    table.insert(t, m._attr.name)

    header["engine"].f_handle:write(table.concat(t, "\t"), "\n")
end

local function parse_thruster(m)
    print(m._attr.name, m._attr.class)
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

    header["thruster"].f_handle:write(table.concat(t, "\t"), "\n")
end

local function parse_ship(m)
    print(m._attr.name, m._attr.class)
    local t = {}

    local prop = m.properties

    local p = prop.identification and prop.identification._attr or {}
    local b, s = p.basename, p.shortvariation
    if b and s then
        table.insert(t, L:get(b))
        table.insert(t, L:get(s))
    else
        table.insert(t, L:get(p.name))
        table.insert(t, "--")
    end
    --    table.insert(t, L:get(p.name or "--"))
    --    table.insert(t, L:get(p.basename or "--"))
    --    table.insert(t, L:get(p.description or "--"))
    --    table.insert(t, L:get(p.variation or "--"))
    --    table.insert(t, L:get(p.shortvariation or "--"))
    --    table.insert(t, L:get(p.icon or "--"))

    p = prop.explosiondamage and prop.explosiondamage._attr or {}
    table.insert(t, p.value or "--")

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

    p = (prop.physics and prop.physics._attr) or {}
    table.insert(t, p.mass or "--")

    p = prop.thruster and prop.thruster._attr or {}
    table.insert(t, p.tags or "--")

    p = prop.ship and prop.ship._attr or {}
    table.insert(t, p.type or "--")

    local model = m.component._attr.ref
    local engines, weapons, turrets, shields = count_tags(model)
    table.insert(t, engines)
    table.insert(t, weapons)
    table.insert(t, turrets)
    table.insert(t, shields)

    local max, tags
    local con = m.connections.connection
    for i = 1, #con do
        local c = con[i]
        if 1 == c._attr.ref:find("con_storage") then
            max, tags = parse_storage(c.macro._attr.ref)
            break
        end
    end
    table.insert(t, max or "--")
    table.insert(t, tags or "--")

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

    table.insert(t, m._attr.name)

    header["ship"].f_handle:write(table.concat(t, "\t"), "\n")
end


local function parse_macro(macro)
    local m = macro._attr
    if m then
        local class = m.class
        if "shieldgenerator" == class then
            if 1 ~= m.name:find("test") then
                parse_shield(macro)
            end
        elseif "engine" == class then
            if 1 == m.name:find("eng") then
                parse_engine(macro)
            elseif 1 == m.name:find("thr") then
                parse_thruster(macro)
            end
        elseif class and "ship_" == class:sub(1, 5) then
            if 1 ~= m.name:find("dummy") then
                parse_ship(macro)
            end
        end
    end
end


local function parse_start()
    for name, value in pairs(index.macro) do
        local h = load_xml(value .. ".xml")
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
    v.f_handle = io.open(k .. ".csv", "w+b")
    v.f_handle:write(table.concat(v.str, "\t"), "\n")
end

parse_index()
parse_start()

for _, v in pairs(header) do
    v.f_handle:close()
end
