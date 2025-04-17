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
--- @field minWidth number
--- @field minHeight number
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
--- @field package children gui.UiElement[]
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
function gui.Sizing.FIXED(n) return {n, type=gui._SizingType.FIXED, min=n} end

--- @class gui.Sizing.FitSizing
--- @field type gui.Sizing.Types
--- @field min number?
--- @field max number?

--- Fit sizing
--- @param min number?
--- @param max number?
--- @return gui.Sizing.FitSizing
function gui.Sizing.FIT(n, min, max) return {n, type=gui._SizingType.FIT, min=min, max=max} end

--- @class gui.Sizing.GrowSizing
--- @field type gui.Sizing.Types
--- @field min number?
--- @field max number?

--- Grow sizing
--- @param min number?
--- @param max number?
--- @return gui.Sizing.GrowSizing
function gui.Sizing.GROW(min, max) return {min, type=gui._SizingType.GROW, min=min, max=max} end

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
    self._data = {width=0, height=0, minWidth=0, minHeight=0, x=0, y=0}

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
--- @param dimension "width"|"height"
function gui.fitSizing(root, dimension)
    local isWidth = dimension == "width"
    local layoutDir = isWidth and gui.LayoutDirection.LEFT_TO_RIGHT or gui.LayoutDirection.TOP_TO_BOTTOM
    local sizeField = isWidth and "width" or "height"
    local minField = isWidth and "minWidth" or "minHeight"

    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.POST_ORDER) do
        local padding = isWidth and node.padding.left + node.padding.right or node.padding.top + node.padding.bottom
        node._data[sizeField] = node._data[sizeField] + padding
        node._data[minField] = node._data[minField] + padding
    
        local childGap = (#node.children - 1) * node.childGap
        if node.layoutDirection == layoutDir then
            node._data[sizeField] = node._data[sizeField] + childGap
            node._data[minField] = node._data[minField] + childGap
        end
        node._data[sizeField] = node.sizing[sizeField] or node._data[sizeField]
        node._data[minField] = node.sizing[minField] or node._data[minField]

        local parent = node.parent
        if not parent then return end
        if parent.layoutDirection == layoutDir then
            parent._data[sizeField] = parent._data[sizeField] + node._data[sizeField]
            parent._data[minField] = parent._data[minField] + node._data[minField]
        else
            parent._data[sizeField] = math.max(parent._data[sizeField], node._data[sizeField])
            parent._data[minField] = math.max(parent._data[minField], node._data[minField])
        end
    end
end

--- @param root gui.UiElement
--- @param dimension "width"|"height"
function gui.growAndShrinkSizing(root, dimension)
    local isWidth = dimension == "width"
    local layoutDir = isWidth and gui.LayoutDirection.TOP_TO_BOTTOM or gui.LayoutDirection.LEFT_TO_RIGHT
    local sizeField = isWidth and "width" or "height"
    local minField = isWidth and "minWidth" or "minHeight"
    local sizeType = isWidth and "wtype" or "htype"

    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.PRE_ORDER) do
        local padding = isWidth and node.padding.left + node.padding.right or node.padding.top + node.padding.bottom

        if node.layoutDirection == layoutDir then
            local remaining = node._data[sizeField] - padding
            for _, child in ipairs(node.children) do
                if child.sizing[sizeType] == gui._SizingType.GROW then
                    child._data[sizeField] = remaining
                end
            end
        else
            local remaining = node._data[sizeField] - padding
            for _, child in ipairs(node.children) do
                remaining = remaining - child._data[sizeField]
            end
            remaining = remaining - node.childGap * (#node.children - 1)
            log.debug("Remaining %s: %d", sizeField, remaining)

            local resizable = util.filter(node.children, function(c)
                return c.sizing[sizeType] == (remaining > 0 and gui._SizingType.GROW or gui._SizingType.FIT)
            end)

            if #resizable > 0 then
                while remaining ~= 0 and #resizable > 0 do
                    local compare = remaining > 0 and math.min or math.max
                    local extreme = resizable[1]._data[sizeField]
                    local secondExtreme = remaining > 0 and math.huge or 0
                    local delta = remaining

                    for _, child in ipairs(resizable) do
                        local size = child._data[sizeField]
                        if (remaining > 0 and size < extreme) or (remaining < 0 and size > extreme) then
                            secondExtreme = extreme
                            extreme = size
                        elseif size ~= extreme then
                            secondExtreme = compare(secondExtreme, size)
                            delta = secondExtreme - extreme
                        end
                    end

                    delta = compare(delta, remaining / #resizable)

                    for i, child in ipairs(resizable) do
                        if child._data[sizeField] == extreme then
                            local old = child._data[sizeField]
                            child._data[sizeField] = old + delta
                            if remaining < 0 and child._data[sizeField] < child._data[minField] then
                                child._data[sizeField] = child._data[minField]
                                table.remove(resizable, i)
                            end
                            remaining = remaining - (child._data[sizeField] - old)
                        end
                    end
                end
            end
        end
    end
end

function gui.wrapText(root)
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
    gui.fitSizing(root, "width")
    gui.growAndShrinkSizing(root, "width")
    gui.wrapText(root)
    gui.fitSizing(root, "height")
    gui.growAndShrinkSizing(root, "height")
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
        if (node._data.width > 0 and node._data.height > 0) then
            paintutils.drawFilledBox(node._data.x, node._data.y, node._data.x + node._data.width - 1, node._data.y + node._data.height - 1, node.backgroundColor)
        end
    end
end

function gui.UiElement:render()
end

return gui