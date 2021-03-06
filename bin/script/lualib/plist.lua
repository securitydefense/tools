-- See http://xmlsoft.org/xmlreader.html for more examples
local xmlreader = require "xmlreader"
local json = require "lualib.json"

local function load_plist(text)
    local r = assert(xmlreader.from_string(text))

    local function next_tag()
        while r:read() do
            if r:node_type() == "element" then
                return r:name()
            elseif r:node_type() == "end element" then
                return "end"
            end
        end
    end

    local function next_text(tag)
        local result
        while r:read() do
            if r:node_type() == "element" then
                if r:name() ~= tag then
                    break
                end
            elseif r:node_type() == "text" then
                result = r:value()
            elseif r:node_type() == "end element" then
                break
            end
        end
        return result
    end

    local function next_value(tag)
        local loaders = {
            ["plist"] = function()
                return next_value()
            end,
            ["dict"] = function()
                if r:is_empty_element() then
                    return {}
                end
                local dict = {}
                while true do
                    local key = next_text("key")
                    if key == nil then
                        break
                    end
                    local tag = next_tag()
                    if tag == "key" then
                        dict[key] = "null"
                        dict[next_text()] = "null"
                    elseif tag == "end" then
                    else
                        local value = next_value(tag)
                        dict[key] = value
                    end
                end
                return dict
            end,
            ["array"] = function()
                if r:is_empty_element() then
                    return {}
                end
                local array = {}
                while true do
                    local tag = next_tag()
                    if tag == "end" then
                        break
                    else
                        table.insert(array, next_value(tag))
                    end
                end
                return array
            end,
            ["string"] = function()
                return next_text("string")
            end,
            ["integer"] = function()
                return tonumber(next_text("integer"))
            end,
            ["real"] = function()
                return tonumber(next_text("real"))
            end,
            ["true"] = function()
                return true
            end,
            ["false"] = function()
                return false
            end,
        }

        local tag = tag or next_tag()
        local f = assert(loaders[tag], "unknown tag: " .. (tag or "nil"))
        return f()
    end

    local result = next_value()
    r:close()
    return result
end

return {
    decode = load_plist
}
