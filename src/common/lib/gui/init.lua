--- Strap library together and provide the public API for the library
--- 
--- Provide all important classes while hidding interal complexity

local gui = {}

--- @module "common.lib.gui.enums"
local enums = require("ccmesystem.lib.gui.enums")
for k, v in pairs(enums) do
    gui[k] = v
end
--- @module "common.lib.gui.Sizing"
gui.Sizing = require("ccmesystem.lib.gui.Sizing")
--- @module "common.lib.gui.UiElement"
gui.UiElement = require("ccmesystem.lib.gui.UiElement")
--- @module "common.lib.gui.TextElement"
gui.TextElement = require("ccmesystem.lib.gui.TextElement")
--- @module "common.lib.gui.Layout"
local layout = require("ccmesystem.lib.gui.Layout")
for k, v in pairs(layout) do
    gui[k] = v
end

return gui