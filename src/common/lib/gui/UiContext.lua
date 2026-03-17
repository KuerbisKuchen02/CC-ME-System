--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")

--- @class (exact) gui.UiContext
--- @field isRunning boolean
--- @field needsLayout boolean
--- @field canTapChangeFocus boolean
--- @field root gui.UiElement
--- @field focusedElement gui.UiElement
--- @field clickedElement gui.UiElement
local UiContext = class.class()

function UiContext:constructor()
    self.isRunning = false
    self.needsLayout = true
end

function UiContext:invalidateLayout()
    self.needsLayout = true
end

--- @param event gui.Event
function UiContext:fireEvent(event)
    if not self.root then return end
    self.root:dispatchEvent(event)
end

return UiContext
