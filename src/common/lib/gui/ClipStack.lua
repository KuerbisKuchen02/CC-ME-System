--- @module "common.lib.expect"
local expect = require("ccmesystem.lib.expect").expect
--- @module "common.lib.errorManager"
local errorManager = require("ccmesystem.lib.errorManager")
--- @module "common.lib.log"
local log = require("ccmesystem.lib.log")
--- @module "common.lib.util"
local util = require("ccmesystem.lib.util")

--- @class gui.ClipStack.clipRegion
--- @field x number
--- @field y number
--- @field width number
--- @field height number


--- @class gui.ClipStack
--- @field _stack gui.ClipStack.clipRegion[]
local ClipStack = {_stack = {}}

function ClipStack:pushClip(x, y, width, height)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, width, "number")
    expect(4, height, "number")

    local currentClip = self._stack[#self._stack]
    if not currentClip then
        table.insert(self._stack, {x = x, y = y, width = width, height = height})
        log.debug("Pushed first clip region: %s", util.serialize(self._stack[#self._stack]))
        return
    end

    local ix = math.max(x, currentClip.x)
    local iy = math.max(y, currentClip.y)
    local iw = math.max(0, math.min(x + width, currentClip.x + currentClip.width) - ix)
    local ih = math.max(0, math.min(y + height, currentClip.y + currentClip.height) - iy)
    table.insert(self._stack, {x = ix, y = iy, width = iw, height = ih})
    log.debug("Pushed clip region: %s", util.serialize(self._stack[#self._stack]))
end

function ClipStack:popClip()
    if #self._stack == 0 then
        errorManager.error("No clip region to pop")
    end
    return table.remove(self._stack)
end

function ClipStack:currentClip()
    if #self._stack == 0 then
        local width, height = term.getSize()
        return {x = 0, y = 0, width = width, height = height}
    end
    return self._stack[#self._stack]
end

return ClipStack