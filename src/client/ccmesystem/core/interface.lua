--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.gui"
local gui = require("ccmesystem.lib.gui")

--- @class ccmesystem.gui.Application
local Application = class.class()

function Application:constructor()
    local width, height = term.getSize()
    local root = gui.UiElement({
        layoutDirection = gui.LayoutDirection.LEFT_TO_RIGHT,
        position = {2, 2},
        sizing = {
            width = gui.Sizing.FIXED(width - 2),
            height = gui.Sizing.FIT(),
        },
        padding = {1,1,1,1},
        childGap = 1,
        backgroundColor = colors.purple,
    })

    for i = 1, 3 do
        local child = gui.UiElement({
            sizing = {
                width = gui.Sizing.FIXED(2),
                height = gui.Sizing.FIXED(2),
            },
            backgroundColor = colors.orange,
        })
        root:addChildren(child)
    end
    local hbox = gui.UiElement({
        layoutDirection = gui.LayoutDirection.TOP_TO_BOTTOM,
        sizing = {
            width = gui.Sizing.FIT(),
            height = gui.Sizing.FIT(),
        },
        padding = {1,1,1,1},
        childGap = 1,
        backgroundColor = colors.red,
    })
    for i = 1, 2 do
        local child = gui.UiElement({
            sizing = {
                width = gui.Sizing.FIXED(2),
                height = gui.Sizing.FIXED(2),
            },
            backgroundColor = colors.blue,
        })
        hbox:addChildren(child)
    end
    root:addChildren(hbox)
    gui.draw(root)
    term.setCursorPos(1, height)
end

return Application

