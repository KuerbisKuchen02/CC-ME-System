--- Strap library together and provide the public API for the library
--- 
--- Provide all important classes while hidding interal complexity

local gui = {}

--- @module "common.lib.errorManager"
local errorManager = require("ccmesystem.lib.errorManager")

--- @module "common.lib.gui.UiContext"
local UiContext = require("ccmesystem.lib.gui.UiContext")
--- @module "common.lib.gui.enums"
local enums = require("ccmesystem.lib.gui.enums")
--- @module "common.lib.gui.Layout"
local layout = require("ccmesystem.lib.gui.Layout")
--- @module "common.lib.gui.events"
local handleEvent = require("ccmesystem.lib.gui.events").handleEvent
--- @module "common.lib.gui.Sizing"
gui.Sizing = require("ccmesystem.lib.gui.Sizing")
--- @module "common.lib.gui.UiElement"
gui.UiElement = require("ccmesystem.lib.gui.UiElement")
--- @module "common.lib.gui.TextElement"
gui.TextElement = require("ccmesystem.lib.gui.TextElement")

local context = UiContext()

gui.handleEvent = function (event, ...)
    handleEvent(context, event, ...)
end

for k, v in pairs(enums) do
    gui[k] = v
end

for k, v in pairs(layout) do
    gui[k] = v
end

--- Set the root element for the GUI
--- @param element gui.UiElement
function gui.setRoot(element)
    context.root = element
    element:setContext(context)
end

--- If set to true, the GUI will pull and consume all cc events
--- If you want to handle events manually, set this to false and call `handleEvent` with the event data yourself
--- @type boolean
gui.doPullEvents = true

function gui.run()
    if not context.root then
        errorManager.error("Cannot run GUI without root element set", 2)
    end
    if context.isRunning then
        errorManager.error("GUI main loop already running", 2)
    end
    context.isRunning = true
    local ok, err = pcall(function()
        while context.isRunning do

            if gui.doPullEvents then
                handleEvent(context, os.pullEventRaw())
            end

            if context.needsLayout then
                layout.layout(context.root)
                context.needsLayout = false
            end
            layout.render(context.root)
        end
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Goodbye...")
        os.sleep(0.5)
        term.clear()
        term.setCursorPos(1, 1)
    end)
    if not ok then
        errorManager.error(("Error in gui run loop: %s"):format(err), 1)
    end
end

return gui
