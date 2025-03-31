local expect = require("cc.expect").expect
local log = require("log")
local schema = require("ccmesystem.lib.config").schema
local util = require("ccmesystem.lib.util")

return function(context)
    expect(1, context, "table")

    local items = context:require("ccmesystem.core.items")

    local config = context.config
        :group("rednet", "Options configuring the rednet API")
        :define("trustedClients", "A list of trusted clients; all clients if empty", {}, schema.list(schema.peripheral))
        :define("ignoredModems", "A list of ignored modems", {}, schema.list(schema.peripheral))
        :get()

    local trustedClients = util.lookup(config.trustedClients)
    local rednetPeripherals = util.lookup(config.rednetPeripherals)

    local requests = {
        ["peripherals"] = function() return items.peripherals end,
        ["items"] = function() return items.items end,
        ["getItem"] = items.getItem,
        ["insert"] = items.insert,
        ["extract"] = items.extract,
    }

    local modems = peripheral.find("modem")
    for _, name in ipairs(modems) do
        if not rednetPeripherals[name] then
            log.info("Opening rednet on modem %s", name)
            rednet.open(name)
        end
    end

    rednet.host("ccmesystem", "server")

    context:spawn(function()
        while true do
            local sender, message = rednet.receive("ccmesystem")
            if trustedClients[message] or #trustedClients == 0 then
                log.info("Receviced request '%s' from client %d", message, sender)
                local args = util.split(message, ",")
                local request = table.remove(args, 1)
                if requests[request] then
                    ---@diagnostic disable-next-line: redundant-parameter
                    local result = requests[request](table.unpack(args))
                    if result then
                        rednet.send(sender, "true," + util.serialize(result))
                    else
                        rednet.send(sender, "true")
                    end
                else
                    rednet.send(sender, "false,Unknown request")
                    log.warn("Unknown request '%s'", message)
                end
            else
                rednet.send(sender, "false,Client not trusted")
                log.info("Ignoring request '%s' from client %d", message, sender)
            end
        end
    end)
end