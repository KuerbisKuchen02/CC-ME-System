local expect = require("cc.expect").expect

--- @class class.baseClass
--- @field new function Create a new instance of a class
--- @field super function Invoke a parent method that was overriden by the child

--- Class system for Lua

--- Create a new object of a class
---
--- @generic T: class.baseClass
--- @param c table the class
--- @param ...? any the arguments for the constructor (optional)
--- @return T object  the new object
local function new(c, ...)
    expect(1, c, "table")

    local o = {}
    setmetatable(o, c)

    if c.constructor then
        c.constructor(o, ...)
    end

    return o
end


--- Invoke a parent method that is overriden by the current class
---
--- @param object table the object
--- @param methodName? string|nil the method name
--- @param ...? any the arguments for the method (optional)
--- @return ... values the return values of the method
local function super(object, methodName, ...)
    expect(1, object, "table")
    expect(2, methodName, "string", "nil")

    if methodName == nil then
        methodName = "constructor"
    end
    -- store the current scope of the super method for recursive super calls,
    -- because the original object must be passed to the super method to access its attributes
    local current = object.__superScope
    local next
    if current then
        next = getmetatable(current).__index
    else 
        next = getmetatable(getmetatable(object)).__index
    end

    local result
    while next do
        if next[methodName] then
            -- call the super method with the original object but with the scope of the super method
            object.__superScope = next
            result = {pcall(next[methodName], object, ...)}
            object.__superScope = current
            break
        end
        next = getmetatable(next).__index
    end

    if result == nil then
        error("No super method found", 2)
    elseif table.remove(result, 1) then
        return table.unpack(result)
    else
        error(result[1], 2)
    end
end


--- check if an object is an instance of a class
---
--- @param object table the object to verify
--- @param class table the class to check against
--- @return boolean isInstance true if the object is an instance of the class
local function instanceOf(object, class)
    expect(1, object, "table")
    expect(2, class, "table")

    local c = getmetatable(object).__index
    while c do 
        if c == class then
            return true
        end
        c = getmetatable(c).__index
    end
    return false
end


--- Object destructor handler
---
--- This is the _gc implementation and should not be called manually
---
--- @param object table the object
local function finalizer(object)
    assert(type(object) == "table", "Object must be a table")

    if object.destructor then
        object:destructor()
    end
end


--- Class table factory
---
--- @generic T: class.baseClass
--- @param parent? table class to inherit from (optional)
--- @return T class the class table
local function class(parent)
    assert(parent == nil or type(parent) == "table", "Parent must be a table or nil")

    local c = {}
    local mt = {}
    
    if parent then
        c.super = super
        mt.__index = parent
    end

    c.new = new
    mt.__gc = finalizer
    mt.__call = new

    c.__index = c
    setmetatable(c, mt)
    if c.__init then
        c:__init()
    end

    return c
end


--- return the module
return {
    class = class,
    new = new,
    super = super,
    instanceOf = instanceOf
}