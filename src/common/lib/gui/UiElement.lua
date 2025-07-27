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

--- @module "common.lib.gui.enums"
local enums = require("ccmesystem.lib.gui.enums")
--- @module "common.lib.gui.Sizing"
local Sizing = require("ccmesystem.lib.gui.Sizing")

--- Abstact base class of every ui component
--- 
--- This class provides all relevant field for layouting and positioning.
--- The layout uses a flow like layouting, either horizontal or vertical.
--- Complex layouts can be created by nesting multiple elements.
--- The class is configured using named parameters (table). 
--- 
--- 
------
--- # Parameter
--- > Every paramter is optional. 
--- 
--- - `layoutDirection`: Flow direction [LEFT_TO_RIGHT or TOP_TO_BOTTOM]; default LEFT_TO_RIGH`
--- - `sizing`: [FIT(n, min, max), FIXED(n), GROW(n, min, max), PERCENT(n)] parameters can be named or unnamed; default FIT()
--- - `padding`: {top, left, bottom, right} paramters can be named or unnamed; default 0,0,0,0
--- - `childGap`: 0...n; default 0
--- - `position`: {x=0..n, y=0..n} paramters can be named or unnamed; default 0,0
--- - `alignment`: {x=[LEFT or CENTER or RIGHT], y=[TOP or CENTER or BOTTOM]}; default LEFT,TOP
---
--- # Functions
--- - `function gui.UiElement.addChildren(...: UiElement)` add one or more children
--- 
------
--- Example:
--- ```lua
--- root = gui.UiElement({sizing={width=gui.Sizing.FIXED(20), height=gui.FIT()}, padding={1,1,1,1}, childGap=1})
--- child1 = gui.UiElement({sizing={width=gui.Sizing.GROW(), height=gui.Sizing.GROW()}})
--- child2 = gui.UiElement({sizing={width=gui.Sizing.FIXED(10), height=gui.FIXED(10)})
--- root.addChildren(child1, child2)
--- gui.render(root)
--- ```
--- @class gui.UiElement : class.baseClass
--- @field parent gui.UiElement
--- @field children gui.UiElement[]
--- @field _data gui.UiElementClacData
--- @field layoutDirection gui.LayoutDirection
--- @field sizing gui.UiElementSizing
--- @field padding gui.Padding
--- @field childGap number
--- @field position gui.Position
--- @field alignment gui.Alignment
local UiElement = class.class()

--- @class gui.UiElementClacData
--- @field width number
--- @field height number
--- @field minWidth number
--- @field minHeight number
--- @field x number
--- @field y number

--- @class gui.UiElementSizing
--- @field wtype gui.Sizing.Type
--- @field htype gui.Sizing.Type
--- @field width number
--- @field height number
--- @field minWidth? number
--- @field minHeight? number
--- @field maxWidth? number
--- @field maxHeight? number

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
function UiElement:constructor(config)
    expect(1, config, "table", "nil")

    config = config or {}
    -- Layout
    self.layoutDirection = field(config, "layoutDirection", "number", "nil") or enums.LayoutDirection.LEFT_TO_RIGHT

    self.sizing = {width = 0, height = 0, wtype = Sizing._Type.FIT, htype = Sizing._Type.FIT}
    if config.sizing then
        expect(1, config.sizing, "table")
        if config.sizing.width then
            expect(1, config.sizing.width, "table")
            self.sizing.wtype = field(config.sizing.width, "type", "number")
            self.sizing.width = config.sizing.width[1]
            self.sizing.minWidth = field(config.sizing.width, "min", "number", "nil") or 0
            self.sizing.maxWidth = field(config.sizing.width, "max", "number", "nil")
        end
        if config.sizing.height then
            expect(1, config.sizing.height, "table")
            self.sizing.htype = field(config.sizing.height, "type", "number", "nil")
            self.sizing.height = config.sizing.height[1]
            self.sizing.minHeight = field(config.sizing.height, "min", "number", "nil") or 0
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

    self.alignment = {x=enums.XAlignment.LEFT, y=enums.YAlignment.TOP}
    if config.alignment then
        expect(1, config.alignment, "table")
        self.alignment.x = field(config.alignment, "x", "string", "nil") or self.alignment.x
        self.alignment.y = field(config.alignment, "y", "string", "nil") or self.alignment.y
    end

    self.parent = nil
    self.children = {}
    self._data = {width=0, height=0, minWidth=0, minHeight=0, x=0, y=0}

    self.backgroundColor = field(config, "backgroundColor", "number", "nil") or colors.black
    -- log.trace("Created UiElement: %s", util.serialize(self))
end

--- Add children to an UiElement
--- @param ... gui.UiElement children to add
function UiElement:addChildren(...)
    for _, child in ipairs({...}) do
        table.insert(self.children, child)
        child.parent = self
    end
end

function UiElement:draw()
    if (self._data.width > 0 and self._data.height > 0) then
        paintutils.drawFilledBox(self._data.x, self._data.y, self._data.x + self._data.width - 1,
            self._data.y + self._data.height - 1, self.backgroundColor)
    end
end

return UiElement