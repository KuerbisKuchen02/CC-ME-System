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
--- @class (exact) gui.events.GenericEvent : class.baseClass
--- @field source gui.UiElement|nil
--- @field target gui.UiElement|nil
--- @field type string
--- @field args table
--- @field isConsumed boolean
--- @field dispatchChain gui.UiElement[]
--- @field handleChain gui.UiElement[]
local GenericEvent = class.class()

--- @param type string
--- @param ... any
function GenericEvent:constructor(type, ...)
    expect(1, type, "string")

    self.type = type
    self.args = {...}
    self.isConsumed = false
    self.dispatchChain = {}
    self.handleChain = {}
end

function GenericEvent:consume()
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

--- @class (exact) gui.events.AlarmEvent : gui.events.GenericEvent
--- @field id number
local AlarmEvent = class.class(GenericEvent)

function AlarmEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local id = ...
    self.id = id
end

--- @class (exact) gui.events.CharEvent : gui.events.GenericEvent
--- @field character string
local CharEvent = class.class(GenericEvent)

function CharEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local character = ...
    self.character = character
end

--- @class (exact) gui.events.ComputerCommandEvent : gui.events.GenericEvent
--- @field arguments table
local ComputerCommandEvent = class.class(GenericEvent)

function ComputerCommandEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local arguments = ...
    self.arguments = arguments
end

--- @class (exact) gui.events.DiskEvent : gui.events.GenericEvent
--- @field side string
local DiskEvent = class.class(GenericEvent)

function DiskEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local side = ...
    self.side = side
end

--- @class (exact) gui.events.DiskEjectEvent : gui.events.GenericEvent
--- @field side string
local DiskEjectEvent = class.class(GenericEvent)

function DiskEjectEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local side = ...
    self.side = side
end

--- @class (exact) gui.events.FileTransferEvent : gui.events.GenericEvent
--- @field transferredFiles table[]
local FileTransferEvent = class.class(GenericEvent)

function FileTransferEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local transferredFiles = ...
    self.transferredFiles = transferredFiles
end

--- @class (exact) gui.events.HttpCheckEvent : gui.events.GenericEvent
--- @field url string
--- @field ok boolean
--- @field error string?
local HttpCheckEvent = class.class(GenericEvent)

function HttpCheckEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, ok, error = ...
    self.url = url
    self.ok = ok
    self.error = error
end

--- @class (exact) gui.events.HttpFailureEvent : gui.events.GenericEvent
--- @field url string
--- @field error string
--- @field handle table?
local HttpFailureEvent = class.class(GenericEvent)

function HttpFailureEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, error, handle = ...
    self.url = url
    self.error = error
    self.handle = handle
end

--- @class (exact) gui.events.HttpSuccessEvent : gui.events.GenericEvent
--- @field url string
--- @field handle table
local HttpSuccessEvent = class.class(GenericEvent)

function HttpSuccessEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, handle = ...
    self.url = url
    self.handle = handle
end

--- @class (exact) gui.events.KeyEvent : gui.events.GenericEvent
--- @field key number
--- @field isHeld boolean
local KeyEvent = class.class(GenericEvent)

function KeyEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local key, isHeld = ...
    self.key = key
    self.isHeld = isHeld
end

--- @class (exact) gui.events.KeyUpEvent : gui.events.GenericEvent
--- @field key number
local KeyUpEvent = class.class(GenericEvent)

function KeyUpEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local key = ...
    self.key = key
end

--- @class (exact) gui.events.ModemMessageEvent : gui.events.GenericEvent
--- @field side string
--- @field channel number
--- @field replyChannel number
--- @field message any
--- @field distance number
local ModemMessageEvent = class.class(GenericEvent)

function ModemMessageEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local side, channel, replyChannel, message, distance = ...
    self.side = side
    self.channel = channel
    self.replyChannel = replyChannel
    self.message = message
    self.distance = distance
end

--- @class (exact) gui.events.MouseClickEvent : gui.events.GenericEvent
--- @field button number
--- @field x number
--- @field y number
local MouseClickEvent = class.class(GenericEvent)

function MouseClickEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local button, x, y = ...
    self.button = button
    self.x = x
    self.y = y
end

--- @class (exact) gui.events.MouseDragEvent : gui.events.GenericEvent
--- @field button number
--- @field x number
--- @field y number
local MouseDragEvent = class.class(GenericEvent)

function MouseDragEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local button, x, y = ...
    self.button = button
    self.x = x
    self.y = y
end

--- @class (exact) gui.events.MouseScrollEvent : gui.events.GenericEvent
--- @field direction number
--- @field x number
--- @field y number
local MouseScrollEvent = class.class(GenericEvent)

function MouseScrollEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local direction, x, y = ...
    self.direction = direction
    self.x = x
    self.y = y
end

--- @class (exact) gui.events.MouseUpEvent : gui.events.GenericEvent
--- @field button number
--- @field x number
--- @field y number
local MouseUpEvent = class.class(GenericEvent)

function MouseUpEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local button, x, y = ...
    self.button = button
    self.x = x
    self.y = y
end

--- @class (exact) gui.events.PasteEvent : gui.events.GenericEvent
--- @field text string
local PasteEvent = class.class(GenericEvent)

function PasteEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local text = ...
    self.text = text
end

--- @class (exact) gui.events.PeripheralDetachEvent : gui.events.GenericEvent
--- @field side string
local PeripheralDetachEvent = class.class(GenericEvent)

function PeripheralDetachEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local side = ...
    self.side = side
end

--- @class (exact) gui.events.PeripheralEvent : gui.events.GenericEvent
--- @field side string
local PeripheralEvent = class.class(GenericEvent)

function PeripheralEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local side = ...
    self.side = side
end

--- @class (exact) gui.events.RednetMessageEvent : gui.events.GenericEvent
--- @field senderId number
--- @field message any
--- @field protocol string?
local RednetMessageEvent = class.class(GenericEvent)

function RednetMessageEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local senderId, message, protocol = ...
    self.senderId = senderId
    self.message = message
    self.protocol = protocol
end

--- @class (exact) gui.events.RedstoneEvent : gui.events.GenericEvent
local RedstoneEvent = class.class(GenericEvent)

function RedstoneEvent:constructor(event, ...)
    self:super("constructor", event, ...)
end

--- @class (exact) gui.events.SpeakerAudioEmptyEvent : gui.events.GenericEvent
--- @field name string
local SpeakerAudioEmptyEvent = class.class(GenericEvent)

function SpeakerAudioEmptyEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local name = ...
    self.name = name
end

--- @class (exact) gui.events.TaskCompleteEvent : gui.events.GenericEvent
--- @field id number
--- @field success boolean
--- @field errorMsg string?
--- @field parameters table?
local TaskCompleteEvent = class.class(GenericEvent)

function TaskCompleteEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local id, success, errorMsg, parameters = ...
    self.id = id
    self.success = success
    self.errorMsg = errorMsg
    self.parameters = parameters
end

--- @class (exact) gui.events.TermResizeEvent : gui.events.GenericEvent
local TermResizeEvent = class.class(GenericEvent)

function TermResizeEvent:constructor(event, ...)
    self:super("constructor", event, ...)
end

--- @class (exact) gui.events.TerminateEvent : gui.events.GenericEvent
local TerminateEvent = class.class(GenericEvent)

function TerminateEvent:constructor(event, ...)
    self:super("constructor", event, ...)
end

--- @class (exact) gui.events.TimerEvent : gui.events.GenericEvent
--- @field id number
local TimerEvent = class.class(GenericEvent)

function TimerEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local id = ...
    self.id = id
end

--- @class (exact) gui.events.TurtleInventoryEvent : gui.events.GenericEvent
local TurtleInventoryEvent = class.class(GenericEvent)

function TurtleInventoryEvent:constructor(event, ...)
    self:super("constructor", event, ...)
end

--- @class (exact) gui.events.WebsocketClosedEvent : gui.events.GenericEvent
--- @field url string
--- @field reason string?
--- @field code number?
local WebsocketClosedEvent = class.class(GenericEvent)

function WebsocketClosedEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, reason, code = ...
    self.url = url
    self.reason = reason
    self.code = code
end

--- @class (exact) gui.events.WebsocketFailureEvent : gui.events.GenericEvent
--- @field url string
--- @field error string
local WebsocketFailureEvent = class.class(GenericEvent)

function WebsocketFailureEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, error = ...
    self.url = url
    self.error = error
end

--- @class (exact) gui.events.WebsocketMessageEvent : gui.events.GenericEvent
--- @field url string
--- @field message string
--- @field isBinary boolean
local WebsocketMessageEvent = class.class(GenericEvent)

function WebsocketMessageEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, message, isBinary = ...
    self.url = url
    self.message = message
    self.isBinary = isBinary
end

--- @class (exact) gui.events.WebsocketSuccessEvent : gui.events.GenericEvent
--- @field url string
--- @field handle table
local WebsocketSuccessEvent = class.class(GenericEvent)

function WebsocketSuccessEvent:constructor(event, ...)
    self:super("constructor", event, ...)
    local url, handle = ...
    self.url = url
    self.handle = handle
end

--- This table maps all cc event names to their corresponding event classes.
--- @type table<string, gui.events.GenericEvent>
local EventMap = {
    alarm = AlarmEvent,
    char = CharEvent,
    computer_command = ComputerCommandEvent,
    disk = DiskEvent,
    disk_eject = DiskEjectEvent,
    file_transfer = FileTransferEvent,
    http_check = HttpCheckEvent,
    http_failure = HttpFailureEvent,
    http_success = HttpSuccessEvent,
    key = KeyEvent,
    key_up = KeyUpEvent,
    modem_message = ModemMessageEvent,
    mouse_click = MouseClickEvent,
    mouse_drag = MouseDragEvent,
    mouse_scroll = MouseScrollEvent,
    mouse_up = MouseUpEvent,
    paste = PasteEvent,
    peripheral = PeripheralEvent,
    peripheral_detach = PeripheralDetachEvent,
    rednet_message = RednetMessageEvent,
    redstone = RedstoneEvent,
    speaker_audio_empty = SpeakerAudioEmptyEvent,
    task_complete = TaskCompleteEvent,
    term_resize = TermResizeEvent,
    terminate = TerminateEvent,
    timer = TimerEvent,
    turtle_inventory = TurtleInventoryEvent,
    websocket_closed = WebsocketClosedEvent,
    websocket_failure = WebsocketFailureEvent,
    websocket_message = WebsocketMessageEvent,
    websocket_success = WebsocketSuccessEvent,
}


--- Factory function for creating event classes for cc events
--- @param eventName string
--- @param ... any
--- @return gui.events.GenericEvent
local function createEvent(eventName, ...)
    local EventClass = EventMap[eventName]

    if not EventClass then
        -- Fallback auf GenericEvent
        return GenericEvent(eventName, ...)
    end

    return EventClass(eventName, ...)
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

    local newUiEvent = createEvent(eventName, ...)

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
    handleEvent = handleEvent,
    createEvent = createEvent,
    GenericEvent = GenericEvent,

    AlarmEvent = AlarmEvent,
    CharEvent = CharEvent,
    ComputerCommandEvent = ComputerCommandEvent,
    DiskEvent = DiskEvent,
    DiskEjectEvent = DiskEjectEvent,
    FileTransferEvent = FileTransferEvent,
    HttpCheckEvent = HttpCheckEvent,
    HttpFailureEvent = HttpFailureEvent,
    HttpSuccessEvent = HttpSuccessEvent,
    KeyEvent = KeyEvent,
    KeyUpEvent = KeyUpEvent,
    ModemMessageEvent = ModemMessageEvent,
    MouseClickEvent = MouseClickEvent,
    MouseDragEvent = MouseDragEvent,
    MouseScrollEvent = MouseScrollEvent,
    MouseUpEvent = MouseUpEvent,
    PasteEvent = PasteEvent,
    PeripheralDetachEvent = PeripheralDetachEvent,
    PeripheralEvent = PeripheralEvent,
    RednetMessageEvent = RednetMessageEvent,
    RedstoneEvent = RedstoneEvent,
    SpeakerAudioEmptyEvent = SpeakerAudioEmptyEvent,
    TaskCompleteEvent = TaskCompleteEvent,
    TermResizeEvent = TermResizeEvent,
    TerminateEvent = TerminateEvent,
    TimerEvent = TimerEvent,
    TurtleInventoryEvent = TurtleInventoryEvent,
    WebsocketClosedEvent = WebsocketClosedEvent,
    WebsocketFailureEvent = WebsocketFailureEvent,
    WebsocketMessageEvent = WebsocketMessageEvent,
    WebsocketSuccessEvent = WebsocketSuccessEvent,
}