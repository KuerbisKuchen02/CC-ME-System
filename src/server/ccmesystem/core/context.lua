local expect = require("cc.expect").expect

local class = require("ccmesystem.lib.class")
local concurrent = require("ccmesystem.lib.concurrent")
local Config = require("ccmesystem.lib.config")
local log = require("ccmesystem.lib.log")
local Mediator = require("ccmesystem.lib.mediator")

local sentinel = {}

local Context = class.class()

function Context:constructor()
    self.config = Config(".ccmesystem/config.lua")
    self.mediator = Mediator()

    self._modules = {}
    self._mainPool = concurrent.createRunner()
    self._peripheralPool = concurrent.createRunner(64)
end

function Context:require(module)
    expect(1, module, "string", "table")

    if type(module) == "string" then
        module = require(module)
    end

    local instance = self._modules[module]
    if instance == sentinel then
        error("Circular dependency detected: " .. module, 2)
    elseif instance == nil then
        self._modules[module] = sentinel
        instance = module(self)
        self._modules[module] = instance or true
    end

    return instance
end

function Context:spawn(func)
    expect(1, func, "function")
    return self._mainPool.spawn(func)
end

function Context:spawnPeripheral(func)
    expect(1, func, "function")
    return self._peripheralPool.spawn(func)
end

function Context:run()
    self._mainPool.spawn(self._peripheralPool.runForever)

    local ok, err = pcall(self._mainPool.runUntilDone)
    if not ok then
        log.error("Error: %s", err)
        error(err)
    end

    log.info("Shutting down...")
end

return Context