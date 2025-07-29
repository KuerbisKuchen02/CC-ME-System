--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.errorManager"
local errorManager = require("ccmesystem.lib.errorManager")
--- @module "common.lib.expect"
local expect = require("ccmesystem.lib.expect").expect
--- @module "common.lib.log"
local log = require("ccmesystem.lib.log")
--- @module "common.lib.util"
local copy = require("ccmesystem.lib.util").copy


--- @type gui.properties.hookType[]
local setterHooks = {}

local function applyHooks(self, propertyName, value)
    for _, hook in ipairs(setterHooks) do
        local newValue = hook(self, propertyName, value)
        value = newValue or value
    end
    return value
end

--- Update the value of a property
---
--- Includes validation, type check and observer calls
--- @param self gui.properties.PropertyClass
--- @param name string
--- @param value any
local function updateProperty(self, name, value)
    local config = self._properties[name]
    if config == nil then return end

    local oldValue = self._values[name]
    if type(oldValue) == "function" and config.type ~= "function" then
        oldValue = oldValue(self)
    end
    local newValue = (type(value) == "function" and config.type ~= "function") and value(self) or value
    if config.type and config.type ~= type(newValue) then
        errorManager.error(("Cannot set property %s to %s: Unsupported Type"):format(name, value), 4)
    end
    if newValue == nil and not config.allowNil then
        errorManager.error(("Cannot set property %s to nil: AllowNil is set to false"):format(name), 4)
    end
    self._values[name] = value

    if oldValue == newValue then
        return
    end

    if self._properties[name].canTriggerRender then
        -- TODO: Handle rerender
    end
    for _, callback in ipairs(self._properties[name].observers) do
        callback(self, oldValue, newValue)
    end
end

--- Provides a simple way to define properties for classes.
--- 
--- A property is a field that can be accessed like a normal field, but has additional features like 
--- - validation
--- - type checking
--- - custom setter and getter
--- - observer callbacks
--- 
--- ## Usage:
--- ```lua
--- local PropertyClass = require("ccmesystem.lib.gui.properties")
--- local MyClass = class.class(PropertyClass)
--- MyClass:defineProperty("myProperty", {
---     type = PropertyClass.Type.STRING,
---     default = "default value",
---     canTriggerRender = true,
---     allowNil = false,
---     getter = function(self, value)
---         return value:upper() -- custom getter that returns the value in uppercase
---     end,
---     setter = function(self, value)
---         return value:lower() -- custom setter that converts the value to lowercase
---     end,
---     observers = {
---         function(self, oldValue, newValue)
---             log.info("Property myProperty changed from %s to %s", oldValue, newValue)
---         end
---     }
--- })
--- local myObject = MyClass()
--- myObject.myProperty = "Hello World" -- This will trigger the setter and observer
--- local value = myObject.myProperty -- This will trigger the getter
--- log.info("Value of myProperty: %s", value) -- This will print "Value of myProperty: HELLO WORLD"
--- ```
--- @class gui.properties.PropertyClass
--- @field _properties table<string, gui.properties.PropertyConfig>
--- @field _values table<string, any>
local PropertyClass = class.class()

--- @generic T
--- @alias gui.properties.hookType fun(self: gui.properties.PropertyClass, property: string, value: T): T

--- @alias gui.properties.getterType fun(self: gui.properties.PropertyClass, value: any, ...): ...

--- @generic T
--- @alias gui.properties.setterType fun(self: gui.properties.PropertyClass, value: any, ...): ...

--- @generic T
--- @alias gui.properties.observerType fun(self: gui.properties.PropertyClass, newValue: T, oldValue: T)

--- @class gui.properties.PropertyConfig
--- @field type gui.properties.Type?
--- @field default any?
--- @field canTriggerRender boolean?
--- @field allowNil boolean?
--- @field getter gui.properties.getterType?
--- @field setter gui.properties.setterType?
--- @field observers gui.properties.observerType[]?

--- @enum gui.properties.Type
PropertyClass.Type = {
    STRING = "string",
    NUMBER = "number",
    BOOLEAN = "boolean",
    NIL = "nil",
    TABLE = "table",
    FUNCTION = "function"
}

--- Init values on class creation
function PropertyClass:__init()
    self._properties = self._properties or {}
    self._values = self._values or {}
end

--- Init values on object creation
function PropertyClass:constructor()
    local metaTable = getmetatable(self) or {}
    local originalIndex = metaTable.__index
    local originalNewIndex = metaTable.__newindex

    metaTable.__index = function(t, k)
        local config = self._properties[k]
        if not config then
            if not originalIndex then
                return rawget(t, k)
            elseif type(originalIndex) == "function" then
                return originalIndex(t, k)
            else
                return originalIndex[k]
            end
        end
        return self:get(k)
    end
    metaTable.__newindex = function(t, k, v)
        local config = self._properties[k]
        if not config then
            if not originalNewIndex then
                rawset(t, k, v)
            elseif type(originalNewIndex) == "function" then
                return originalNewIndex(t, k, v)
            else
                return originalNewIndex[k]
            end
        end
        self:set(k, v)
    end

    for name, config in pairs(self._properties) do
        if self._values[name] == nil then
            self._values[name] = copy(config.default)
        end
    end
end

--- Add a new setter hook that is applied each time any property is set
--- @param hook gui.properties.hookType
function PropertyClass.addSetterHook(hook)
    expect(1, hook, "function")
    for _, h in ipairs(setterHooks) do
        if h == hook then
            log.error("Hook %s already exists in setter hook list", hook)
            return
        end
    end

    table.insert(setterHooks, hook)
end

--- Remove an existing setter hook
--- @param hook gui.properties.hookType
function PropertyClass.removeSetterHook(hook)
    expect(1, hook, "function")
    for i, h in ipairs(setterHooks) do
        if h == hook then
            table.remove(setterHooks, i)
            return
        end
    end

    log.error("Cannot remove setter hook %s. This hook does not exist", hook)
end

--- Define a new property for the class
---
--- ## Config
--- - `type` (string): The type of the property. Can be one of `gui.properties.Type` (STRING, NUMBER, BOOLEAN, NIL, TABLE, FUNCTION).
--- - `default` (any): The default value of the property. The type of the default value must match the type of the property.
--- - `canTriggerRender` (boolean): If true, the property change will trigger a render of the element.
--- - `allowNil` (boolean): If true, the property can be set to nil.
--- - `getter` (function): A custom getter function that takes the class instance and the current value as arguments and returns the value.
--- - `setter` (function): A custom setter function that takes the class instance and the new value as arguments and returns the value.
--- - `observers` (function[]): A list of observer functions that are called when the property is changed. 
---   Each observer function takes the class instance, the old value and the new value as arguments.
--- 
--- ## Example
--- ```lua
--- MyClass:defineProperty("myProperty", {
---     type = PropertyClass.Type.STRING,
---     default = "default value",
---     canTriggerRender = true,
---     allowNil = false,
---     getter = function(self, value)
---         return value:upper() -- custom getter that returns the value in uppercase
---     end,
---     setter = function(self, value)
---         return value:lower() -- custom setter that converts the value to lowercase
---     end,
---     observers = {
---         function(self, oldValue, newValue)
---             log.info("Property myProperty changed from %s to %s", oldValue, newValue)
---         end
---     }
--- })
--- ```
--- @param name string
--- @param config gui.properties.PropertyConfig
function PropertyClass:defineProperty(name, config)
    expect(1, name, "string")
    expect(2, config, "table")

    if config.default and config.type and config.type ~= type(config.default) then
        errorManager.error(("Default value %s must match type %s of property %s")
            :format(config.default, config.type, name), 3)
    end
    self._properties[name] = {
        type = config.type,
        default = config.default,
        canTriggerRender = config.canTriggerRender or false,
        allowNil = config.allowNil or true,
        getter = config.getter,
        setter = config.setter,
        observers = {},
    }
    return self
end

--- Remove a property from the class
--- @param name string
function PropertyClass:removeProperty(name)
    expect(1, name, "string")

    if not self._properties[name] then
        errorManager.error(("Cannot remove property %s: No such property"):format(name), 3)
    end

    self._values[name] = nil
    self._properties[name] = nil
    return self
end

--- Combine two or more properties into one setter/ getter
--- @param name string
--- @param ... string
--- @usage element:combineProperties("position", "x", "y")
function PropertyClass:combineProperties(name, ...)
    local propertyNames = { ... }
    for _, n in ipairs(propertyNames) do
        if not self._properties[n] then
            errorManager.error(("Cannot create combined property: No such property %s"):format(n))
        end
    end
    self:defineProperty(name, {
        getter = function(clazz)
            expect(1, clazz, "table")
            local values = {}
            for _, n in ipairs(propertyNames) do
                table.insert(values, clazz:get(n))
            end
            return table.unpack(values)
        end,

        setter = function (clazz, ...)
            expect(1, clazz, "table")
            local values = {...}
            if #values > #propertyNames then
                errorManager.error(("Unsupported number of arguments: Expected %s got %s"):format(#propertyNames, #values))
            end
            for i, n in ipairs(propertyNames) do
                clazz:set(n, values[i])
            end
            return ...
        end
    })
end

--- Add an observer to a property of that class
---@param name string
---@param callback gui.properties.observerType
function PropertyClass:addObserver(name, callback)
    expect(1, name, "string")
    expect(2, callback, "function")
    if not self._properties[name] then
        errorManager.error(("Cannot add callback %s for property %s: No such property")
            :format(callback, name))
    end

    table.insert(self._properties[name].observers, callback)
    return self
end

--- Remove observer from a property of that class
--- @param name string
--- @param callback gui.properties.observerType
function PropertyClass:removeObserver(name, callback)
    expect(1, name, "string")
    expect(2, callback, "function")
    if not self._properties[name] then
        errorManager.error(("Cannot remove callback %s for property %s: No such property")
            :format(callback, name))
    end

    for i, cb in ipairs(self._properties[name].observers) do
        if cb == callback then
            table.remove(self._properties[name].observers, i)
            return self
        end
    end
    errorManager.error(("There is no such callback %s for property %s"):format(callback, name))
end

--- Remove all observers for the given property
---@param name string
function PropertyClass:removeAllObservers(name)
    expect(1, name, "string")
    if not self._properties[name] then
        errorManager.error(("Cannot clear observers for property %s: No such property"):format(name))
    end

    self._properties[name].observers = {}
    return self
end

--- Set property `name` to `value`
--- 
--- The value must match the type of the property.
--- If the property type is not a function, 
--- you can pass a function that takes the class instance as an argument and returns the value.
---
--- Alternative for: clazz.name = value
--- @param name string
--- @param value any
--- @param ... unknown
function PropertyClass:set(name, value, ...)
    expect(1, name, "string")
    local config = self._properties[name]
    if config == nil then
        errorManager.error(("Cannot set property %s to %s: No such property"):format(name, value))
        error() -- only to satisfy linter, error will be already thrown in errorManager
    end
    if config.setter then
        value = config.setter(self, value, ...)
    end
    value = applyHooks(self, name, value)
    updateProperty(self, name, value)
end

--- Get property `name`
---
--- Alternative for: local value = clazz.name
--- @param name any
--- @param ... unknown
function PropertyClass:get(name, ...)
    expect(1, name, "string")
    local config = self._properties[name]
    if config == nil then
        errorManager.error(("Cannot get property %s: No such property"):format(name))
        error() -- only to satisfy linter, error will be already thrown in errorManager
    end
    local value = self._values[name]
    if type(value) == "function" and config.type ~= "function" then
        value = value(self)
    end
    if config.getter then
        value = config.getter(self, value, ...)
    end
    if config.type and config.type ~= type(value) then
        errorManager.error(("Got unsupported type for property %s: Expected %s got %s")
            :format(name, config.type, type(value)))
    end
    if value == nil and not config.allowNil then
        errorManager.error(("Got nil for property %s: AllowNil = false"):format(name))
    end
    return value
end
