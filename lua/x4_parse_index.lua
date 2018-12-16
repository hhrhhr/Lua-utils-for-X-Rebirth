local conf = require("x4_config")

local err = io.stderr

--[[ xml stuff ]]--------------------------------------------------------------

local xml2lua = require("xml2lua")
local xml_tree = require("xmlhandler.tree")

local function load_xml(filename)
    local xml_to_load = conf.res_dir .. conf.sep .. filename
    local xml, handler
    local f = io.open(xml_to_load, "rb")
    if f then
        xml = f:read("a")
        f:close()
        handler = xml_tree:new()
        local parser = xml2lua.parser(handler)
        parser:parse(xml)
    end
    return handler
end

--[[ ]]------------------------------------------------------------------------

local index = { macro = {}, component = {} }
local cache = {} -- [filename] = bool

local function read_xml(filename, tag, tbl)
    io.write(filename)
    
    local h = load_xml(filename)
    local entry = h and h.root.index.entry

--io.write("name\tclass\tfilename\n")
    local count = #entry
    io.write(" : ", count, " elements.\n")
    
    for i = 1, count do
        if i % 10 == 0 then
            io.write("#")
        else
            io.write(".")
        end
        
        local e = entry[i]._attr
        local fn = e.value:gsub("\\\\", "/")
        fn = fn:gsub("\\", "/")
        
        if cache[fn] then
            goto skip
        else
            cache[fn] = true
        end
        
        local th = load_xml(fn .. ".xml")
        if not th then
--            err:write("xml not found\t", fn, "\n")
            goto skip
        end

        local tag = th.root[tag .. "s"][tag]
        if not tag then
            err:write("<tag> not found\t", fn, "\n")
            goto skip
        end

        local count = #tag
        if 0 == count then
            local a = tag._attr
            local name = a.name or "NO_NAME"
            local class = a.class or "NO_CLASS"
            table.insert(tbl, {name, class, fn})
--        io.write(name, "\t", class, "\t", fn, "\n")
        else
            for j = 1, count do
                local a = tag[j]._attr
                local name = a.name or "NO_NAME"
                local class = a.class or "NO_CLASS"
                table.insert(tbl, {name, class, fn})
--            io.write(name, "\t", class, "\t", fn, "\n")
            end
        end

        ::skip::
    end
    io.write("\n")
end

read_xml("index/macros.xml", "macro", index.macro)
read_xml("index/components.xml", "component", index.component)

local str = {}
table.insert(str, "local index = {")
table.insert(str, "macro = {")
local e = index.macro
for i = 1, #e do
    local m = e[i]
    table.insert(str, ("[%q] = { %q, %q },"):format(m[1], m[2], m[3]))
end
table.insert(str, "},")
table.insert(str, "component = {")
e = index.component
for i = 1, #e do
    local m = e[i]
    table.insert(str, ("[%q] = { %q, %q },"):format(m[1], m[2], m[3]))
end
table.insert(str, "} }")
table.insert(str, "return index")

local chunk = load(table.concat(str, "\n"))

local w = io.open("index.luac", "w+b")
w:write(string.dump(chunk, true))
w:close()
