local expect = require("cc.expect").expect
local log = require("ccmesystem.lib.log")
local schema = require("ccmesystem.lib.config").schema
local util = require("ccmesystem.lib.util")

local PROTOCOL = "ccmesystem"
local SERVER_NAME = "server"

log.info("Loading rednet module")
return function(context)
    expect(1, context, "table")

    local items = context:require("ccmesystem.core.items")

    local config = context.config
        :group("rednet", "Options configuring the rednet API")
        :define("trustedClients", "A list of trusted clients; all clients if empty", {}, schema.list(schema.peripheral))
        :define("ignoredModems", "A list of ignored modems", {}, schema.list(schema.peripheral))
        :get()

    local trustedClients = util.lookup(config.trustedClients)
    local ignoredModems = util.lookup(config.ignoredModems)

    log.info("Trusted clients: %s", util.serialize(trustedClients))
    log.info("Ignored modems: %s", util.serialize(ignoredModems))

    local requests = {
        ["peripherals"] = function () return items.peripherals end,
        ["items"] = function () return items.items end,
        ["getItem"] = function (hash) return items:getItem(hash) end,
        ["insert"] = function (from, fromSlot, item) 
            return items:insert(from, tonumber(fromSlot), tonumber(item) or textutils.unserialise(item)) end,
        ["extract"] = function (toPeripheral, hash, count) return items:extract(toPeripheral, hash, tonumber(count)) end,
    }

    context:spawn(function()
        log.info("Starting rednet server")
        local modems = {peripheral.find("modem")}
        if #modems == 0 then
            log.error("No modems found")
            return
        end
        for _, wrapped in ipairs(modems) do
            local name = peripheral.getName(wrapped)
            if not ignoredModems[name] then
                log.info("Opening rednet on modem %s", name)
                rednet.open(name)
            end
        end

        rednet.host(PROTOCOL, SERVER_NAME)

        while true do
            local sender, message = rednet.receive(PROTOCOL)
            if trustedClients[message] or #trustedClients == 0 then
                log.info("Receviced request '%s' from client %d", message, sender)
                local args = util.split(message, "|")
                local request = table.remove(args, 1)
                log.info("Request '%s' with args %s", request, util.serialize(args))
                if requests[request] then
                    ---@diagnostic disable-next-line: redundant-parameter
                    local result = requests[request](table.unpack(args))
                    if result then
                        rednet.send(sender, "true," .. util.serialize(result), PROTOCOL)
                    else
                        rednet.send(sender, "true", PROTOCOL)
                    end
                else
                    rednet.send(sender, "false,Unknown request", PROTOCOL)
                    log.warn("Unknown request '%s'", message)
                end
            else
                rednet.send(sender, "false,Client not trusted", PROTOCOL)
                log.info("Ignoring request '%s' from client %d", message, sender)
            end
        end
    end)
end
