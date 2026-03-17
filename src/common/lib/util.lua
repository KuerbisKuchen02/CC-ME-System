local expect = require("cc.expect").expect

--- Auxilary functions for other modules

--- Convert a list to a lookup table. Allow you to easily check,
--- if a value is present in a list
---
--- @param list any[] List which should be converted
--- @return {[any]: true} lookup with the provided items
local function lookup(list)
    expect(1, list, "table")

    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end


--- Returns a new list containing all entries from both lists
---
--- @param ... any[] lists
--- @return any[] list new list with all entries
local function concat_lists(...)
    local list = {}
    for _,l in ipairs({...}) do
        for i = 1, #l do
            table.insert(list, l[i])
        end
    end
    return list
end

--- Make a deep copy of an object
---
--- @param obj table object to copy
--- @return table copy of the object
local function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    seen = seen or {}
    if seen[obj] then return seen[obj] end
    local s = seen
    local res = {}
    s[obj] = res
    for k, v in next, obj do res[copy(k, s)] = copy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

--- Merge two sets
---
--- @param set1 table first set
--- @param set2 table second set
--- @return table merged set
local function union(set1, set2)
    expect(1, set1, "table")
    expect(2, set2, "table")
    if set1 == set2 then return set1 end

    local set = {}
    for k, v in pairs(set1) do set[k] = v end
    for k, v in pairs(set2) do set[k] = v end
    return set
end

--- Serialize an object
---
--- @param obj any object to serialize
--- @return string serialized object
local function serialize(obj)
    local function inner(obj, n, seen)
        if type(obj) == "table" then
            if seen[obj] then return "self" end
            seen[obj] = true
        end
        if n > 20 then return "...(truncated)..." end
        
        if obj == nil or type(obj) == "number" or type(obj) == "boolean" or type(obj) == "function" then
            return tostring(obj)
        elseif type(obj) == "string" then
            return string.format("%q", obj)
        elseif type(obj) == "table" then
            local string = "{"
            for k,v in pairs(obj) do
                if k == "children" then
                    string = string .. "[" .. inner(k, n + 1, seen) .. "]=" .. "..." .. ","
                else
                    string = string .. "[" .. inner(k, n + 1, seen) .. "]=" .. inner(v, n + 1, seen) .. ","
                end
            end
            return string .. "}"
        elseif type(obj) == "thread" then
            return "thread("..coroutine.status(obj)..")"
        else
            error("cannot serialize a " .. type(obj))
        end
    end
    return inner(obj, 0, {})
end


--- Split a string into a list of strings
---
--- @param str string string to split
--- @param sep? string separator
--- @return table list list of strings
local function split(str, sep)
    expect(1, str, "string")
    expect(2, sep, "string", "nil")

    local sep, fields = sep or " ", {}
    local pattern = string.format("([^%s]+)", sep)
    local _ = str:gsub(pattern, function(c) table.insert(fields, c) end)
    return fields
end

--- Filter a table by a function
--- 
--- @generic T: any[]
--- @param list T table that should be filtered
--- @param predicate fun(elem): boolean function to filter the table
--- @return T filtered table
local function filter(list, predicate)
    expect(1, list, "table")
    expect(2, predicate, "function")

    local result = {}
    for _, v in ipairs(list) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

--- Returns a new list with the elements in reverse order.
--- @generic T: any[]
--- @param list T
--- @return T
local function reverse(list)
    expect(1, list, "table")

    local result = {}
    for i = #list, 1, -1 do
        table.insert(result, list[i])
    end
    return result
end


--- return the module
return {
    lookup = lookup,
    concat_lists = concat_lists,
    copy = copy,
    union = union,
    serialize = serialize,
    split = split,
    filter = filter,
    reverse = reverse,
}