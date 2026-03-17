--- The gui event system is based on the [JavaFX event system](https://docs.oracle.com/javafx/2/events/processing.htm)
---
--- Every event is represented by an instance of the `Event` class.
--- An event MUST have a type, source, and target.
--- Specific events MAY have additional properties or methods.
---
--- To start the event handling process the main handleEvent function MUST be called. This is either done in the main application loop or manually.
---
--- # Event Delivery Process
--- 
--- When an event is thrown it is delivered in a four step process
--- 
--- 1. Target Selection
--- 2. Route construction
--- 3. Event capturing
--- 4. Event bubbling
---
--- ## Target Selection
---
--- - for key and scroll events the target is the focused element
--- - for mouse down, up and drag events the target is the element under the mouse cursor
---
--- If a mouse button is pressed all subsequent mouse events will be targeted at the same element until the button is released.
--- 
--- ## Route Construction
---
--- The event route is determined by the implemementation of the @see gui.UiElement.buildEventDispatchChain method of the selected target.
--- The default implementation of the method is the route from the root node to the target node.
--- The route can be modified by event filter and event handlers while they process the event.
--- If the event is consumed at any point, some node of the initial route MAY NOT receive the event.
---
--- ## Event Capturing Phase
--- 
--- In the capturing phase the event is dispatched by the root node of the application and passed down the event dispatch chain to the target node.
--- If any node in the event dispatch chain has an event filter registered for the event type that occurred, that filter is called.
--- When the filter completes, the event is passed to the next node down the chain.
--- If no filter is registered for that node, the event is passed to the next node in the chain.
--- If no filter consumes the event, the event WILL eventually reach the target node.
---
--- ## Event Bubbling Phase
---
--- After the event reached the target and all registered filters have processed the event, the event returns along the dispatch chain from the target to the root node.
--- If any node in the event dispatch chain has an event handler registered for the event type that occurred, that handler is called.
--- When the handler completes, the event is passed to the next node up the chain.
--- If no handler is registered for that node, the event is passed to the next node in the chain.
--- If no handler consumes the event, the event WILL eventually reach the root node.
--- @class gui.events

--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.expect"
local expect = require("ccmesystem.lib.expect").expect
--- @module "common.lib.log"
local log = require("ccmesystem.lib.log")
--- @module "common.lib.util"
local util = require("ccmesystem.lib.util")

--- @module "common.lib.gui.enums"
local enums = require("ccmesystem.lib.gui.enums")

--- The base class for every gui event
--- @class (exact) gui.Event
--- @field source gui.UiElement|nil
--- @field target gui.UiElement|nil
--- @field type string
--- @field args table
--- @field isConsumed boolean
--- @field dispatchChain gui.UiElement[]
--- @field handleChain gui.UiElement[]
local Event = class.class()

--- @param type string
--- @param ... any
function Event:constructor(type, ...)
    expect(1, type, "string")

    self.type = type
    self.args = {...}
    self.isConsumed = false
    self.dispatchChain = {}
    self.handleChain = {}
end

function Event:consume()
    self.isConsumed = true
end


--- @param element gui.UiElement
--- @param x number
--- @param y number
--- @return gui.UiElement|nil
local function hitTest(element, x, y) -- 1 37
    log.trace("Hit testing at %s %s with element: %s", x, y, util.serialize(element))

    -- _data.x = 2 _data.y = 2 _data.width = 37 _data.height = 7
    local isInside = element._data.x <= x and element._data.x + element._data.width > x and element._data.y <= y and element._data.y + element._data.height > y

    -- If the mouse is not inside the element and the overflow is hidden, return nil
    -- Otherwise we need to continue looking through possibly all descendants
    if not isInside and element.overflow == enums.Overflow.HIDDEN then
        log.trace("Element '%s' overflow is hidden and mouse is outside, skipping children", element.name)
        return nil
    end

    for i = #element.children, 1, -1 do
        local child = element.children[i]
        local hit = hitTest(child, x, y)
        if hit then return hit end
    end

    return element
end

--- Calculate the event target for a given event
--- @param context gui.UiContext
--- @param eventName string
--- @param ... any
--- @return gui.UiElement
local function calculateEventTarget(context, eventName, ...)
    expect(1, context.root, "table")
    local target

    if eventName == "mouse_click" then
        local _, x, y = ... -- args = mouse button, x, y
        local element = hitTest(context.root, x, y)
        if element then
            target = element
            context.focusedElement = element
            context.clickedElement = element
        end
    elseif eventName == "mouse_drag" or eventName == "mouse_up" then
        if context.clickedElement then
            target = context.clickedElement
        end
        if eventName == "mouse_up" then
            context.clickedElement = nil
        end
    elseif context.focusedElement then
        target = context.focusedElement
    end

    if not target then
        target = context.root
    end

    return target
end

--- Base event handler
---
--- The function will
--- 1. Create a new instance of @see gui.Event
--- 2. Calculate the event's target node
--- 3. Create the event dispatch chain
--- 4. Dispatch the event down the chain
--- 
--- @param context gui.UiContext
--- @param eventName string
--- @param ... any
local function handleEvent(context, eventName, ...)
    expect(1, context, "table")
    expect(2, eventName, "string")

    if not context.root then return end

    --- @type gui.Event
    local newUiEvent = Event(eventName, ...)

    newUiEvent.target = calculateEventTarget(context, eventName, ...)
    newUiEvent.source = context.root

    newUiEvent.dispatchChain = newUiEvent.target:buildEventDispatchChain()

    local chainString = ""
    for i, element in ipairs(newUiEvent.dispatchChain) do
        chainString = chainString .. element.name .. (i < #newUiEvent.dispatchChain and " -> " or "")
    end

    log.trace("Calculate event dispatch chain '%s' for element: %s", chainString, newUiEvent.target.name)

    context.root:dispatchEvent(newUiEvent)
end

--- @type gui.events
return {
    Event = Event,
    handleEvent = handleEvent
}