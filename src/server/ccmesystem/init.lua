return function ()
    local context = require("ccmesystem.core.context")()

    context:require("ccmesystem.modules.items")
    context:require("ccmesystem.modules.peripherals")
    context:require("ccmesystem.modules.dropoff")
    context:require("ccmesystem.modules.rednet")

    return context
end