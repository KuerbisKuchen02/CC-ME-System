--- Allows specifying"dropoff chests" - items deposited into them will be
-- transferred into the main system.

local log = require("ccmesystem.lib.log")
local schema = require("ccmesystem.lib.config").schema

log.info("Loading dropoff module")
return function(context)
    local items = context:require "ccmesystem.core.items"
    local peripherals = context:require "ccmesystem.modules.peripherals"

    local config = context.config
        :group("dropoff", "Defines chests where you can drop off items")
        :define("chests", "The chest names available", {}, schema.list(schema.peripheral))
        :define("cold_delay", "The time between rescanning dropoff chests when there's been no recent activity", 5,
            schema.positive)
        :define("hot_delay", "The time between rescanning dropoff chests when there's been recent activity.", 0.2,
            schema.positive)
        :get()

    -- Don't bother to register anything if we've got no chests!
    if #config.chests == 0 then return end

    -- Dropoff peripherals shouldn't be treated as storage by the main item system.
    for i = 1, #config.chests do
        peripherals:addIgnoredName(config.chests[i])
    end

    -- Register a thread which just scans chests periodically.
    context:spawn(function()
        while true do
            local pickedAny = false
            for i = 1, #config.chests do
                local chest = config.chests[i]

                -- We perform multiple passes to ensure we get everything when people are spamming items.
                local contents = peripheral.call(chest, "list")
                if contents then
                    for slot, item in pairs(contents) do
                        pickedAny = true
                        items:insert(chest, slot, item)
                    end
                end
            end

            if pickedAny then
                log("Picked up items from chests, rechecking in %.2fs", config.hot_delay)
                sleep(config.hot_delay)
            else
                sleep(config.cold_delay)
            end
        end
    end)
end
