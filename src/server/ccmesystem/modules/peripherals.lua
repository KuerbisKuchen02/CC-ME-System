--- Registers various methods for interacting with storage peripherals.
--
-- This observes any peripherals attached to the network and registers them with
-- the item provider. We also re-scan storage periodically in order to
-- ensure external changes are taken into account.

local expect = require("cc.expect").expect
local class = require("ccmesystem.lib.class")
local util = require("ccmesystem.lib.util")
local log = require("ccmesystem.lib.log")
local schema = require("ccmesystem.lib.config").schema
local sides = require("ccmesystem.lib.config").sides

local ALLOWED_PERIPHERAL_TYPES = {
    ["inventory"] = true,
    ["item_storage"] = true,
}

local Peripherals = class.class()

function Peripherals:constructor(context)
    expect(1, context, "table")

    local items = context:require("ccmesystem.core.items")

    local config = context.config
        :group("peripherals", "Options handling how periphrals are read")
        :define("rescan", "The time between rescanning each peripheral", 10, schema.positive)
        :define("ignoredNames", "A list of ignored peripheral names", {}, schema.list(schema.peripheral))
        :define("ignoredTypes", "A list of ignored peripheral types", {}, schema.list(schema.string))
        :get()

    self.ignoredNames = util.lookup(config.ignoredNames)
    self.ignoredTypes = util.lookup(config.ignoredTypes)

    context:spawn(function ()
        -- Load all peripheral. Done in a task (rather than during init)
        -- so that other modules can ignore specific types/ names.
        for _, name in ipairs(peripheral.getNames()) do
            if self.enabled(name) then
                items:loadPeripheral(name)
            end
        end

        local name = nil
        local timer = os.startTimer(config.rescan)
        while true do
            local event, arg = os.pullEvent()

            if event == "peripheral" and self:enabled(arg) then
                log.info("Loading %s due to peripheral event", arg)
                items:loadPeripheral(arg)
            elseif event == "peripheral_detach" then
                log.info("Unloading %s due to peripheral_detach event", arg)
                items:unloadPeripheral(arg)
            elseif event == "timer" and arg == timer then
                if items.peripheral[name] then
                    name = next(items.peripheral, name)
                else
                    name = nil
                end

                if name ~= nil then
                    log.info("Rescanning %s", name)
                    items:loadPeripheral(name)
                end

                timer = os.startTimer(config.rescan)
            end
        end
    end)

    function Peripherals:addIgnoredName(name)
        expect(1, name, "string")
        self.ignoredNames[name] = true
    end

    function Peripherals:addIgnoredType(name)
        expect(1, name, "string")
        self.ignoredTypes[name] = true
    end

    function Peripherals:enabled(name)
        expect(1, name, "string")
        if sides[name] or self.ignoredNames[name] then return false end

        local types, isAllowed = { peripheral.getType }, false
        for _, t in ipairs(types) do
            if self.ignoredTypes[t] then return false end
            if ALLOWED_PERIPHERAL_TYPES[t] then isAllowed = true end
        end

        return isAllowed
    end
end

return Peripherals