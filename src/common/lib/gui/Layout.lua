--- @module "common.lib.expect"
local expect = require("ccmesystem.lib.expect").expect

--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.log"
local log = require("ccmesystem.lib.log")
--- @module "common.lib.util"
local util = require("ccmesystem.lib.util")
--- @module "common.lib.tree"
local tree = require("ccmesystem.lib.tree")

--- @module "common.lib.gui.enums"
local enums = require("ccmesystem.lib.gui.enums")
--- @module "common.lib.gui.Sizing"
local Sizing = require("ccmesystem.lib.gui.Sizing")
--- @module "common.lib.gui.UiElement"
local UiElement = require("ccmesystem.lib.gui.UiElement")
--- @module "common.lib.gui.TextElement"
local TextElement = require("ccmesystem.lib.gui.TextElement")


local layout = {}

--- @param root gui.UiElement
--- @param dimension "width"|"height"
local function fitSizing(root, dimension)
    local isWidth = dimension == "width"
    local layoutDir = isWidth and enums.LayoutDirection.LEFT_TO_RIGHT or enums.LayoutDirection.TOP_TO_BOTTOM
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
        if node._data[minField] > node._data[sizeField] then
            node._data[sizeField] = node._data[minField]
        end
    end
end

--- @param root gui.UiElement
--- @param dimension "width"|"height"
local function growAndShrinkSizing(root, dimension)
    local isWidth = dimension == "width"
    local layoutDir = isWidth and enums.LayoutDirection.TOP_TO_BOTTOM or enums.LayoutDirection.LEFT_TO_RIGHT
    local sizeField = isWidth and "width" or "height"
    local minField = isWidth and "minWidth" or "minHeight"
    local sizeType = isWidth and "wtype" or "htype"

    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.PRE_ORDER) do
        local padding = isWidth and node.padding.left + node.padding.right or node.padding.top + node.padding.bottom

        if node.layoutDirection == layoutDir then
            local remaining = node._data[sizeField] - padding
            for _, child in ipairs(node.children) do
                if child.sizing[sizeType] == Sizing._Type.GROW then
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
                return c.sizing[sizeType] == (remaining > 0 and Sizing._Type.GROW or Sizing._Type.FIT)
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

--- @param root gui.UiElement
local function wrapText(root)
    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.POST_ORDER) do
        if class.instanceOf(node, TextElement) then
            ---@cast node gui.TextElement
            local lineBreaks = 0
            local lines = util.split(node.text, "\n")
            for _, line in ipairs(lines) do
                lineBreaks = lineBreaks + 1
                if #line < node._data.width then
                    node._data.text = node._data.text .. line .. "\n"
                else
                local words = util.split(line, " ")
                local linelength = 0
                for _, word in ipairs(words) do
                    if linelength + #word + 1 > node._data.width then
                        node._data.text = node._data.text .. "\n"
                        lineBreaks = lineBreaks + 1
                        linelength = 0
                    end
                    linelength = linelength + #word + 1
                    node._data.text = node._data.text .. word .. " "
                end
                end
                node._data.text = node._data.text .. "\n"
            end
            log.debug(node.sizing.minHeight)
            if node.sizing.minHeight < lineBreaks then
                node.sizing.minHeight = lineBreaks
            end
        end
    end
end

local function positionAndAlignment(root)
    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.PRE_ORDER) do
        node._data.x = node._data.x + node.position.x
        node._data.y = node._data.y + node.position.y
        local offset = node.layoutDirection == enums.LayoutDirection.LEFT_TO_RIGHT and node.padding.left or node.padding.top
        for _, child in ipairs(node.children) do
            if node.layoutDirection == enums.LayoutDirection.LEFT_TO_RIGHT then
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

--- @param root gui.UiElement
function layout.layout(root)
    expect(1, root, "table")
    fitSizing(root, "width")
    growAndShrinkSizing(root, "width")
    wrapText(root)
    fitSizing(root, "height")
    growAndShrinkSizing(root, "height")
    positionAndAlignment(root)
end

--- @param root gui.UiElement
function layout.draw(root)
    expect(1, root, "table")
    log.info("Term size: %d x %d", term.getSize())
    layout.layout(root)
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 1)
    for node in tree.depthFirstIter(root, tree.DepthFirstOrder.PRE_ORDER) do
        log.info("Drawing node %s at (%d, %d) with size (%d, %d) ", node, node._data.x, node._data.y, node._data.width, node._data.height)
        node:draw()
    end
end

return layout