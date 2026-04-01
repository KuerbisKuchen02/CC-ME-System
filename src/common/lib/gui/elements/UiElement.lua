--- @module "common.lib.expect"
local expect = require("ccmesystem.lib.expect")
local expect, field = expect.expect, expect.field

--- @module "common.lib.class"
local class = require("ccmesystem.lib.class")
--- @module "common.lib.log"
local log = require("ccmesystem.lib.log")
--- @module "common.lib.util"
local util = require("ccmesystem.lib.util")
--- @module "common.lib.tree"
local tree = require("ccmesystem.lib.tree")
--- @module "common.lib.errorManager"
local errorManager = require("ccmesystem.lib.errorManager")

--- @module "common.lib.gui.draw"
local draw = require("ccmesystem.lib.gui.draw")
--- @module "common.lib.gui.enums"
local enums = require("ccmesystem.lib.gui.enums")
--- @module "common.lib.gui.Sizing"
local Sizing = require("ccmesystem.lib.gui.Sizing")

--- Abstract base class of every ui component
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
--- - `layoutDirection`: Flow direction [LEFT_TO_RIGHT or TOP_TO_BOTTOM]; default LEFT_TO_RIGHT
--- - `sizing`: [FIT(n, min, max), FIXED(n), GROW(n, min, max), PERCENT(n)] parameters can be named or unnamed; default FIT()
--- - `padding`: {top, left, bottom, right} parameters can be named or unnamed; default 0,0,0,0
--- - `childGap`: 0...n; default 0
--- - `position`: {x=0..n, y=0..n} parameters can be named or unnamed; default 0,0
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
--- @class (exact) gui.UiElement : class.baseClass
--- @field parent gui.UiElement
--- @field children gui.UiElement[]
--- @field layoutDirection gui.LayoutDirection
--- @field sizing gui.UiElementSizing
--- @field padding gui.Padding
--- @field childGap number
--- @field overflow gui.Overflow
--- @field position gui.Position
--- @field childOffset gui.Position
--- @field alignment gui.Alignment
--- @field _data gui.UiElementCalcData
--- @field _context gui.UiContext
--- @field _filters {[string]: gui.FilterFunction[]}
--- @field _eventHandlers {[string]: gui.EventHandler[]}
--- @field name string
--- @field backgroundColor number
local UiElement = class.class()

--- @alias gui.FilterFunction fun(self: gui.UiElement, e: gui.events.GenericEvent)
--- @alias gui.EventHandler fun(self: gui.UiElement, e: gui.events.GenericEvent)

--- @class gui.UiElementCalcData
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
--- @field right number
--- @field bottom number
--- @field left number

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
--- @field padding gui.Padding | number
--- @field childGap number
--- @field overflow gui.Overflow
--- @field position gui.Position
--- @field alignment gui.Alignment
--- @field backgroundColor number
--- @field name string

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

    self.padding = {top=0, right=0, bottom=0, left=0}
    if config.padding then
        expect(1, config.padding, "table", "number")
        if type(config.padding) == "number" then
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.padding.top = config.padding
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.padding.right = config.padding
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.padding.bottom = config.padding
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.padding.left = config.padding
        else
            if #config.padding == 1 then
                self.padding.top = config.padding[1] or self.padding.top
                self.padding.right = config.padding[1] or self.padding.right
                self.padding.bottom = config.padding[1] or self.padding.bottom
                self.padding.left = config.padding[1] or self.padding.left
            elseif #config.padding == 2 then
                self.padding.top = config.padding[1] or self.padding.top
                self.padding.right = config.padding[2] or self.padding.right
                self.padding.bottom = config.padding[1] or self.padding.bottom
                self.padding.left = config.padding[2] or self.padding.left
            end
            self.padding.top = config.padding[1] or self.padding.top
            self.padding.left = config.padding[2] or self.padding.left
            self.padding.bottom = config.padding[3] or self.padding.bottom
            self.padding.right = config.padding[4] or self.padding.right
            self.padding.top = field(config.padding, "top", "number", "nil") or self.padding.top
            self.padding.left = field(config.padding, "left", "number", "nil") or self.padding.left
            self.padding.bottom = field(config.padding, "bottom", "number", "nil") or self.padding.bottom
            self.padding.right = field(config.padding, "right", "number", "nil") or self.padding.right
        end
    end

    self.childGap = field(config, "childGap", "number", "nil") or 0
    self.overflow = field(config, "overflow", "number", "nil") or enums.Overflow.VISIBLE

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
    self.childOffset = {x = 0, y = 0}

    self._data = {width=0, height=0, minWidth=0, minHeight=0, x=0, y=0}
    self._eventHandlers = {}
    self._filters = {}
    self.name = field(config, "name", "string", "nil") or "Unnamed UiElement"
    log.debug("Created new UiElement: %s", self.name)

    self.backgroundColor = field(config, "backgroundColor", "number", "nil") or colors.black
    -- log.trace("Created UiElement: %s", util.serialize(self))
    self:addEventHandler(UiElement.handleScroll, enums.EventType.MOUSE_SCROLL)
end

function UiElement:setContext(context)
    expect(1, context, "table")
    self._context = context
    for _, child in ipairs(self.children) do
        child:setContext(context)
    end
end

--- Add children to an UiElement
--- @param ... gui.UiElement children to add
function UiElement:addChildren(...)
    for _, child in ipairs({...}) do
        table.insert(self.children, child)
        child.parent = self
        if self._context then
            child:setContext(self._context)
        end
    end
end

--- This function defines the visual representation of the element
--- To display all element use the `render` function
function UiElement:draw()
    draw.drawRectangle(self._data.x, self._data.y, self._data.width, self._data.height, self.backgroundColor)
end

--- Render the element with its children recursively. Use clipping to ensure we only draw what's visible.
--- To actually draw the element on the screen the `draw` function must be called. 
--- To define the design of the item use this method
function UiElement:render()

    -- When the width or height of the visible area or the element is zero we don't need to render it or its children
    local clip = draw.currentClip()
    if clip and (clip.width <= 0 or clip.height <= 0)
        or self._data.width <= 0 or self._data.height <= 0 then
        return
    end

    if self.overflow == enums.Overflow.HIDDEN or self.overflow == enums.Overflow.SCROLL then
        draw.pushClip(self._data.x, self._data.y, self._data.width, self._data.height)
    end

    self:draw()
    for _, child in ipairs(self.children) do
        child:render()
    end

    if self.overflow == enums.Overflow.HIDDEN then
        draw.popClip()
    end
end

--- This function builds the event dispatch chain for any event that targets this element
--- The default implementations passes every ancestors of the element, starting from the root down to the element itself.
--- @return gui.UiElement[] eventDispatchChain list of elements which will be passed before the event reaches this element
function UiElement:buildEventDispatchChain()
    local chain = {}
    local current = self
    while current do
        table.insert(chain, current)
        current = current.parent
    end
    chain = util.reverse(chain)
    return chain
end


--- Call the filter functions of this element and propagate the event to its descendants until
--- 1. The event is consumed
--- 2. The target is reached
--- 3. There are no more children
---
--- If this is the target or it has no children and the event is not consumed, 
--- it will be handled by the element and bubbled back up to its ancestors until
--- 1. The event is consumed
--- 2. The root element is reached
--- 
--- @param event gui.events.GenericEvent
function UiElement:dispatchEvent(event)
    log.trace("Dispatching event '%s' for element: %s", event.type, self.name)
    if #event.dispatchChain <= 0 then
        log.error("Event dispatch chain is empty! Expected '%s' but got 'nil'", self.name)
        return
    end
    if event.dispatchChain[1] ~= self then
        log.error("Event dispatch chain is corrupted! Expected '%s' but got '%s'", self.name, event.dispatchChain[1] and event.dispatchChain[1].name or "nil")
        return
    end
    table.remove(event.dispatchChain, 1)
    table.insert(event.handleChain, self)

    if self._filters then
        if self._filters[event.type] then
            for _, filter in pairs(self._filters[event.type]) do
                filter(self, event)
                if event.isConsumed then return end
            end
        end
        if self._filters["global"] then
            for _, filter in pairs(self._filters["global"] or {}) do
                filter(self, event)
                if event.isConsumed then return end
            end
        end
    end
    if event.isConsumed then return end

    if event.target == self then
        self:handleEvent(event)
        return
    end

    if #event.dispatchChain <= 0 then
        log.warn("Reached end of event dispatch chain, but event target '%s' was not reached", event.type, event.target.name)
        self:handleEvent(event)
        return
    end

    local nextElement = event.dispatchChain[1]
    event.source = self
    nextElement:dispatchEvent(event)
end

--- Handle an event and bubble it up to its ancestors until
--- 1. The event is consumed
--- 2. The root element is reached
---
--- @param event gui.events.GenericEvent
function UiElement:handleEvent(event)
    log.trace("Handling event '%s' for element: %s", event.type, self.name)
    if #event.handleChain <= 0 then
        log.error("Event handle chain is empty! Expected '%s' but got 'nil'", self.name)
        return
    end
    if event.handleChain[#event.handleChain] ~= self then
        log.error("Event handle chain is corrupted! Expected '%s' but got '%s'", self.name, event.handleChain[#event.handleChain] and event.handleChain[#event.handleChain].name or "nil")
        return
    end
    table.remove(event.handleChain, #event.handleChain)

    if self._eventHandlers then
        if self._eventHandlers[event.type] then
            for _, handler in pairs(self._eventHandlers[event.type]) do
                handler(self, event)
                if event.isConsumed then return end
            end
        end
        if self._eventHandlers["global"] then
            for _, handler in pairs(self._eventHandlers["global"] or {}) do
                handler(self, event)
                if event.isConsumed then return end
            end
        end
    end

    if event.isConsumed or #event.handleChain <= 0 then return end

    local nextElement = event.handleChain[#event.handleChain]
    event.source = self
    nextElement:handleEvent(event)
end

--- Add a filter for a specific event or a global filter
--- If `eventName` is not provided, the filter will be applied globally.
--- Multiple filters for the same event type are allowed.
--- A specific filter can only be added once per event type.
--- A global filter will always be called last after all specific filters.
--- Multiple filters for the same event type are called in the order they were added.
---
---
---@param callback gui.FilterFunction
---@param eventName? string|nil
function UiElement:addFilter(callback, eventName)

    eventName = eventName or "global"
    self._filters[eventName] = self._filters[eventName] or {}
    local filters = self._filters[eventName]
    for _, filter in pairs(filters) do
        if filter == callback then
            errorManager.error("Cannot add the same filter multiple times for the same event", 2)
            return
        end
    end
    table.insert(filters, callback)
    log.debug("Added filter for event '%s': %s", eventName, tostring(callback))
end

--- Remove a filter for a specific event or a global filter
---@param callback gui.FilterFunction
function UiElement:removeFilter(callback)
    for name, filters in pairs(self._filters) do
        for i, filter in ipairs(filters) do
            if filter == callback then
                table.remove(filters, i)
                log.debug("Removed filter for event '%s': %s", name, tostring(callback))
                return
            end
        end
    end
    log.warn("Tried to remove filter that was not found: %s", tostring(callback))
end

--- Add an event handler for a specific event or a global event handler
--- If `eventName` is not provided, the handler will be applied globally.
--- Multiple handlers for a specific event type are allowed.
--- A specific handler can only be added once per event type.
--- A global handler will always be called last after all specific handlers.
--- Multiple handlers for the same event type are called in the order they were added.
---
--- @param callback gui.EventHandler
--- @param eventName string|nil
function UiElement:addEventHandler(callback, eventName)
    eventName = eventName or "global"
    self._eventHandlers[eventName] = self._eventHandlers[eventName] or {}
    local handlers = self._eventHandlers[eventName]
    for _, handler in pairs(handlers) do
        if handler == callback then
            errorManager.error("Cannot add the same event handler multiple times for the same event", 2)
            return
        end
    end
    table.insert(handlers, callback)
    log.debug("Added event handler for event '%s': %s", eventName, tostring(callback))
end

--- Remove an event handler for a specific event or a global event handler
--- @param callback gui.EventHandler
function UiElement:removeEventHandler(callback)
    for name, handlers in pairs(self._eventHandlers) do
        for i, handler in ipairs(handlers) do
            if handler == callback then
                table.remove(handlers, i)
                log.debug("Removed event handler for event '%s': %s", name, tostring(callback))
                return
            end
        end
    end
    log.warn("Tried to remove event handler that was not found: %s", tostring(callback))
end

--- @param event gui.events.MouseScrollEvent
function UiElement:handleScroll(event)
    if self.overflow ~= enums.Overflow.SCROLL then return end
    log.debug("Scroll in direction: " .. event.direction)
    if event.direction == 0 then return end
    self.childOffset.y = self.childOffset.y + event.direction
    if self.childOffset.y > 0 then
        self.childOffset.y = 0
    else
        self._context.needsLayout = true
    end
    log.trace("Updated child offset: " .. util.serialize(self.childOffset) .. " for element: " .. self.name)
    log.trace("Size of targeted element " .. self.name .. ": " .. util.serialize(self._data))
end

return UiElement