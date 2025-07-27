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

    local child1 = gui.UiElement({
        sizing = {
            width = gui.Sizing.FIXED(2),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.orange,
    })
    local child2 = gui.TextElement({
        text = "This is a extra long text so that we can test the automatic line break feature",
        backgroundColor = colors.orange,
    })
    local child3 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW(10),
            height = gui.Sizing.GROW(),
        },
        backgroundColor = colors.orange,
    })
    root:addChildren(child1, child2, child3)
    local hbox = gui.UiElement({
        layoutDirection = gui.LayoutDirection.TOP_TO_BOTTOM,
        sizing = {
            width = gui.Sizing.FIXED(5),
            height = gui.Sizing.FIXED(5),
        },
        padding = {1,1,1,1},
        childGap = 1,
        backgroundColor = colors.red,
    })
    local child4 = gui.UiElement({
        sizing = {
            width = gui.Sizing.FIXED(2),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.blue,
    })
    local child5 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW(),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.blue,
    })
    local child6 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW(),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.blue,
    })
    local child7 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW(),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.blue,
    })
    hbox:addChildren(child4, child5, child6, child7)

    root:addChildren(hbox)
    gui.draw(root)
    term.setCursorPos(1, height)
end

return Application

