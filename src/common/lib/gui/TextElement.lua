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
--- @module "common.lib.gui.UiElement"
local UiElement = require("ccmesystem.lib.gui.UiElement")

--- @class gui.TextElemetClacData: gui.UiElementClacData
--- @field text string

--- @class gui.TextElement: gui.UiElement
--- @field _data gui.TextElemetClacData
local TextElement = class.class(UiElement)

function TextElement:constructor(config)
    self:super("constructor", config)
    expect(1, config, "table", "nil")
    config = config or {}

    self.text = field(config, "text", "string")

    local words = util.split(self.text, " ")
    local min = math.huge
    for _, word in ipairs(words) do
        if #word < min then min = #word end
    end
    self.sizing.minWidth = min
    self.sizing.width = #self.text
    self.sizing.minHeight = 1
    self._data.text = ""
end

function TextElement:draw()
    self:super("draw")
    term.setBackgroundColor(self.backgroundColor)
    local lines = util.split(self._data.text, "\n")
    for i, line in ipairs(lines) do
        term.setCursorPos(self._data.x + self.padding.left, self._data.y + self.padding.top + i - 1)
        term.write(line)
    end
end

return TextElement

