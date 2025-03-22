return function ()
    local context = require("ccmesystem.core.context")()

    context:require("ccmesystem.modules.items")
    context:require("ccmesystem.modules.peripherals")

    return context
end