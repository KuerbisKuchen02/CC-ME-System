--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.gui"
local gui = require("ccmesystem.lib.gui")

--- @class ccmesystem.gui.Application
local Application = class.class()

function Application:constructor()
    local width, height = term.getSize()
    --- @type gui.UiElement
    local root = gui.UiElement({
        layoutDirection = gui.LayoutDirection.LEFT_TO_RIGHT,
        position = {2, 2},
        sizing = {
            width = gui.Sizing.FIXED(width - 2),
            height = gui.Sizing.FIT(),
        },
        padding = 1,
        childGap = 1,
        backgroundColor = colors.purple,
        overflow = gui.Overflow.HIDDEN,
        name = "root",
    })

    local child1 = gui.UiElement({
        sizing = {
            width = gui.Sizing.FIXED(2),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.orange,
        name = "child1",
    })
    local child2 = gui.TextElement({
        text = "This is a extra long text so that we can test the automatic line break feature",
        backgroundColor = colors.orange,
        name = "child2",
    })
    local child3 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW{min=10},
            height = gui.Sizing.GROW(),
        },
        backgroundColor = colors.orange,
        name = "child3",
    })
    root:addChildren(child1, child2, child3)
    local hbox = gui.UiElement({
        layoutDirection = gui.LayoutDirection.TOP_TO_BOTTOM,
        sizing = {
            width = gui.Sizing.FIXED(5),
            height = gui.Sizing.FIXED(5),
        },
        padding = {1, 2},
        childGap = 1,
        backgroundColor = colors.red,
        name = "hbox",
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
        name = "child5",
    })
    local child6 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW(),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.blue,
        name = "child6",
    })
    local child7 = gui.UiElement({
        sizing = {
            width = gui.Sizing.GROW(),
            height = gui.Sizing.FIXED(2),
        },
        backgroundColor = colors.blue,
        name = "child7",
    })
    hbox:addChildren(child4, child5, child6, child7)

    root:addChildren(hbox)
    root.childOffset.x = 2
    hbox.childOffset.y = 1

    root:addEventHandler(function()
        root._context.isRunning = false
    end, "terminate")

    gui.setRoot(root)
    gui.run()
end

return Application

