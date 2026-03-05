--- @module "common.lib.expect"
local expect = require("ccmesystem.lib.expect").expect

--- @module "common.lib.gui.ClipStack"
local clipStack = require("ccmesystem.lib.gui.ClipStack")

local function drawRectangle(x, y, width, height, color)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, width, "number")
    expect(4, height, "number")
    expect(5, color, "number")

    local clip = clipStack:currentClip()
    if not clip then return end

    local ix = math.max(x, clip.x)
    local iy = math.max(y, clip.y)
    local iw = math.max(0, math.min(x + width, clip.x + clip.width) - ix)
    local ih = math.max(0, math.min(y + height, clip.y + clip.height) - iy)

    if iw > 0 and ih > 0 then
        paintutils.drawFilledBox(ix, iy, ix + iw - 1, iy + ih - 1, color)
    end
end

local function drawClipOutline()
    local clip = clipStack:currentClip()
    if not clip then return end
    paintutils.drawBox(clip.x, clip.y, clip.x + clip.width, clip.y + clip.height, colors.red)
end

return {
    drawRectangle = drawRectangle,
    drawClipOutline = drawClipOutline,
    currentClip = function () return clipStack:currentClip() end,
    pushClip = function (x, y, width, height) clipStack:pushClip(x, y, width, height) end,
    popClip = function () clipStack:popClip() end,
}