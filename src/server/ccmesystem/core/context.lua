-- The context class is the central class of the system. 
-- It serves as a bootstrapper for all modules and provides an interface for communication between the modules. 
-- It also manages all threads and the configuration of the system.

local expect = require("cc.expect").expect

local class = require("ccmesystem.lib.class")
local concurrent = require("ccmesystem.lib.concurrent")
local Config = require("ccmesystem.lib.config")
local log = require("ccmesystem.lib.log")
local Mediator = require("ccmesystem.lib.mediator")

local sentinel = {}

--- @class Context
local Context = class.class()

function Context:constructor()
    self.config = Config(".ccmesystem/config.lua")
    self.mediator = Mediator()

    self._modules = {}
    self._mainPool = concurrent.createRunner()
    self._peripheralPool = concurrent.createRunner(64)
end

--- This method should be used to load a module. It is importatend to not use the require function directly.
--- This method will load the module and run itself only once and will return the same instance on every call.
---
--- @param module string|table The module to load. Can be a string with the module name or the module itself.
--- @return table instance The module instance
function Context:require(module)
    expect(1, module, "string", "table")
    log.debug("Require module %s", module)
    if type(module) == "string" then
        module = require(module)
        if module == true then
            log.error("Module should return a class or function", module)
            error("Module should return a class or function", 2)
        end
    end

    local instance = self._modules[module]
    if instance == sentinel then
        log.error("Circular dependency detected: %s", module)
        error("Circular dependency detected: " .. module, 2)
    elseif instance == nil then
        self._modules[module] = sentinel
        log.info("Loading module %s", module)
        instance = module(self)
        self._modules[module] = instance or true
    end

    return instance
end

--- Spawn a new coroutine in the main thread. 
--- This method should be used for all long running tasks.
---
---@param func function The function to run in the coroutine
function Context:spawn(func)
    expect(1, func, "function")
    self._mainPool.spawn(func)
end

--- Spawn a new coroutine in the peripheral thread.
--- This method should be used for short running tasks. Usally for perhipheral calls.
---
---@param func function The function to run in the coroutine
function Context:spawnPeripheral(func)
    expect(1, func, "function")
    self._peripheralPool.spawn(func)
end

--- Run the system.
--- This method will start the main thread and the peripheral thread.
function Context:run()
    self._mainPool.spawn(self._peripheralPool.runForever)

    local ok, err = pcall(self._mainPool.runUntilDone)
    if not ok then
        log.fatal("Error: %s", err)
        error(err)
    end

    log.info("Shutting down...")
end

return Context