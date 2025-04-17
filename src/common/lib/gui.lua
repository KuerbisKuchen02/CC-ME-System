local expect = require("cc.expect")
local expect, field = expect.expect, expect.field

--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.log"
local log = require("ccmesystem.lib.log")
--- @module "common.lib.util"
local util = require("ccmesystem.lib.util")
--- @module "common.lib.tree"
local tree = require("ccmesystem.lib.tree")

local gui = {}

--- @class gui.UiElementClacData
--- @field width number
--- @field height number
--- @field x number
--- @field y number

--- @class gui.UiElementSizing
--- @field wtype gui.Sizing.Types
--- @field htype gui.Sizing.Types
--- @field width number
--- @field height number
--- @field minWidth? number
--- @field minHeight? number
--- @field maxWidth? number
--- @field maxHeight? number

--- @class gui.UiElement
--- @field package parent gui.UiElement
--- @field package children table
--- @field package _data gui.UiElementClacData
--- @field layoutDirection gui.LayoutDirection
--- @field sizing gui.UiElementSizing
--- @field padding gui.Padding
--- @field childGap number
--- @field position gui.Position
--- @field alignment gui.Alignment
gui.UiElement = class.class()

--- @enum gui.LayoutDirection 
gui.LayoutDirection = {
    LEFT_TO_RIGHT = 1,
    TOP_TO_BOTTOM = 2,
}

--- @enum  gui.Sizing.Types
gui._SizingType = {
    FIXED = 1,
    FIT = 2,
    GROW = 3,
    PERCENT = 4,
}

--- @alias gui.Sizing gui.Sizing.FixedSizing | gui.Sizing.FitSizing | gui.Sizing.GrowSizing | gui.Sizing.PercentSizing
gui.Sizing = {}

--- @class gui.Sizing.FixedSizing
--- @field type gui.Sizing.Types
--- @field value number

--- Fixed sizing
--- @param n number
--- @return gui.Sizing.FixedSizing
function gui.Sizing.FIXED(n) return {n, type=gui._SizingType.FIXED} end

--- @class gui.Sizing.FitSizing
--- @field type gui.Sizing.Types
--- @field min number?
--- @field max number?

--- Fit sizing
--- @param min number?
--- @param max number?
--- @return gui.Sizing.FitSizing
function gui.Sizing.FIT(min, max) return {type=gui._SizingType.FIT, min=min, max=max} end

--- @class gui.Sizing.GrowSizing
--- @field type gui.Sizing.Types
--- @field min number?
--- @field max number?

--- Grow sizing
--- @param min number?
--- @param max number?
--- @return gui.Sizing.GrowSizing
function gui.Sizing.GROW(min, max) return {type=gui._SizingType.GROW, min=min, max=max} end

--- @class gui.Sizing.PercentSizing
--- @field type gui.Sizing.Types
--- @field value number

--- Percent sizing
--- @param n number
--- @return gui.Sizing.PercentSizing
function gui.Sizing.PERCENT(n) return {n, type=gui._SizingType.PERCENT} end

--- Sizing table
--- @class gui.SizingTable
--- @field width gui.Sizing
--- @field height gui.Sizing

--- Padding table
--- @class gui.Padding
--- @field top number
--- @field left number
--- @field bottom number
--- @field right number

--- Position table
--- @class gui.Position
--- @field x number
--- @field y number

--- @enum gui.XAlignment
gui.XAlignment = {
    LEFT = 1,
    CENTER = 2,
    RIGHT = 3,
}

--- @enum gui.YAlignment
gui.YAlignment = {
    TOP = 1,
    CENTER = 2,
    BOTTOM = 3,
}

--- Alignment options
--- @class gui.Alignment
--- @field x gui.XAlignment
--- @field y gui.YAlignment

--- Args for UiElement constructor
--- @class gui.UiElementConfig
--- @field layoutDirection gui.LayoutDirection
--- @field sizing gui.SizingTable
--- @field padding gui.Padding
--- @field childGap number
--- @field position gui.Position
--- @field alignment gui.Alignment
--- @field backgroundColor number

--- UI element base class
--- @param config gui.UiElementConfig
function gui.UiElement:constructor(config)
    expect(1, config, "table")

    -- Layout
    self.layoutDirection = field(config, "layoutDirection", "number", "nil") or gui.LayoutDirection.LEFT_TO_RIGHT

    self.sizing = {width = 0, height = 0, wtype = gui._SizingType.FIT, htype = gui._SizingType.FIT}
    if config.sizing then
        expect(1, config.sizing, "table")
        if config.sizing.width then
            expect(1, config.sizing.width, "table")
            self.sizing.wtype = field(config.sizing.width, "type", "number")
            self.sizing.width = config.sizing.width[1]
            self.sizing.minWidth = field(config.sizing.width, "min", "number", "nil")
            self.sizing.maxWidth = field(config.sizing.width, "max", "number", "nil")
        end
        if config.sizing.height then
            expect(1, config.sizing.height, "table")
            self.sizing.htype = field(config.sizing.height, "type", "number", "nil")
            self.sizing.height = config.sizing.height[1]
            self.sizing.minHeight = field(config.sizing.height, "min", "number", "nil")
            self.sizing.maxHeight = field(config.sizing.height, "max", "number", "nil")
        end
    end

    self.padding = {top=0, bottom=0, left=0, right=0}
    if config.padding then
        expect(1, config.padding, "table")
        self.padding.top = config.padding[1] or self.padding.top
        self.padding.left = config.padding[2] or self.padding.left
        self.padding.bottom = config.padding[3] or self.padding.bottom
        self.padding.right = config.padding[4] or self.padding.right
        self.padding.top = field(config.padding, "top", "number", "nil") or self.padding.top
        self.padding.left = field(config.padding, "left", "number", "nil") or self.padding.left
        self.padding.bottom = field(config.padding, "bottom", "number", "nil") or self.padding.bottom
        self.padding.right = field(config.padding, "right", "number", "nil") or self.padding.right
    end

    self.childGap = field(config, "childGap", "number", "nil") or 0

    -- Position
    self.position = {x = 0, y = 0}
    if config.position then
        expect(1, config.position, "table")
        self.position.x = config.position[1] or self.position.x
        self.position.y = config.position[2] or self.position.y
        self.position.x = field(config.position, "x", "number", "nil") or self.position.x
        self.position.y = field(config.position, "y", "number", "nil") or self.position.y
    end

    self.alignment = {x=gui.XAlignment.LEFT, y=gui.YAlignment.TOP}
    if config.alignment then
        expect(1, config.alignment, "table")
        self.alignment.x = field(config.alignment, "x", "string", "nil") or self.alignment.x
        self.alignment.y = field(config.alignment, "y", "string", "nil") or self.alignment.y
    end

    self.parent = nil
    self.children = {}
    self._data = {width=0, height=0, x=0, y=0}

    self.backgroundColor = field(config, "backgroundColor", "number", "nil") or colors.black
    log.trace("Created UiElement: %s", util.serialize(self))
end

--- Add children to an UiElement
--- @param ... gui.UiElement children to add
function gui.UiElement:addChildren(...)
    for _, child in ipairs({...}) do
        table.insert(self.children, child)
        child.parent = self
    end
end

--- @param root gui.UiElement
function gui.fitSizing(root)
    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.POST_ORDER) do
        local padding = node.padding
        node._data.width = node._data.width + padding.left + padding.right
        node._data.height = node._data.height + padding.top + padding.bottom

        local childGap = (#node.children - 1) * node.childGap
        if (node.layoutDirection == gui.LayoutDirection.LEFT_TO_RIGHT) then
            node._data.width = node._data.width + childGap;
        else
            node._data.height = node._data.height + childGap
        end
        node._data.width = node.sizing.width or node._data.width
        node._data.height = node.sizing.height or node._data.height

        local parent = node.parent
        if not parent then return end
        if (parent.layoutDirection == gui.LayoutDirection.LEFT_TO_RIGHT) then
            parent._data.width = parent._data.width + node._data.width
            parent._data.height = math.max(parent._data.height, node._data.height)
        else
            parent._data.width = math.max(parent._data.width, node._data.width)
            parent._data.height = parent._data.height + node._data.height
        end
    end
end

function gui.growAndShrinkSizingWidth()
end

function gui.wrapText()
end

function gui.fitSizingHeights()
end

function gui.growAndShrinkSizingHeight()
end

function gui.positionAndAlignment(root)
    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.PRE_ORDER) do
        node._data.x = node._data.x + node.position.x
        node._data.y = node._data.y + node.position.y
        local offset = node.layoutDirection == gui.LayoutDirection.LEFT_TO_RIGHT and node.padding.left or node.padding.top
        for _, child in ipairs(node.children) do
            if node.layoutDirection == gui.LayoutDirection.LEFT_TO_RIGHT then
                child._data.x = node._data.x + offset
                child._data.y = node._data.y + node.padding.top
                offset = offset + child._data.width + node.childGap
            else
                child._data.x = node._data.x + node.padding.left
                child._data.y = node._data.y + offset
                offset = offset + child._data.height + node.childGap
            end
        end
    end
end

function gui.layout(root)
    gui.fitSizing(root)
    gui.positionAndAlignment(root)
end

function gui.draw(root)
    log.info("Term size: %d x %d", term.getSize())
    gui.layout(root)
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 1)
    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.PRE_ORDER) do
        log.info("Drawing node %s at (%d, %d) with size (%d, %d) ", node, node._data.x, node._data.y, node._data.width, node._data.height)
        paintutils.drawFilledBox(node._data.x, node._data.y, node._data.x + node._data.width - 1, node._data.y + node._data.height - 1, node.backgroundColor)
    end
end

function gui.UiElement:render()
end

return gui