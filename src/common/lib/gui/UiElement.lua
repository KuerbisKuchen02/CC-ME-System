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
--- @class (exact) gui.UiElement
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
--- @field _data gui.UiElementClacData
--- @field _context gui.UiContext
--- @field _filters {[string]: gui.FilterFunction}|gui.FilterFunction
--- @field _eventHandlers {[string]: gui.EventHandler} | gui.EventHandler
--- @field name string
--- @field backgroundColor number
local UiElement = class.class()

--- @alias gui.FilterFunction fun(e: gui.Event)
--- @alias gui.EventHandler fun(e: gui.Event)

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
            self.padding.left = config.padding[2] or self.padding.right
            self.padding.bottom = config.padding[3] or self.padding.bottom
            self.padding.right = config.padding[4] or self.padding.left
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

    if self.overflow == enums.Overflow.HIDDEN then
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
--- @param event gui.Event
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
        if type(self._filters) == "function" then
            self._filters(event)
        elseif self._filters[event.type] then
            self._filters[event.type](event)
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
--- @param event gui.Event
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
        if type(self._eventHandlers) == "function" then
            self._eventHandlers(event)
        elseif self._eventHandlers[event.type] then
            self._eventHandlers[event.type](event)
        end
    end

    if event.isConsumed or #event.handleChain <= 0 then return end

    local nextElement = event.handleChain[#event.handleChain]
    event.source = self
    nextElement:handleEvent(event)
end

--- Add a filter for a specific event or a global filter
--- If `eventName` is not provided, the filter will be applied globally.
--- Only one global filter is allowed per element, if a global filter is already set you first have to remove it
--- You can add multiple filters for specific events, but only if no global filter is set.
--- You can only add one filter per event type
---
---@param callback gui.FilterFunction
---@param eventName? string|nil
function UiElement:addFilter(callback, eventName)
    if type(self._filters) == "function" then
        if eventName then
            errorManager.error("Cannot add filter for specific event to element with global filter", 2)
        end
        if self._filters ~= callback then
            errorManager.error("Cannot add multiple global filters to the same element", 2)
        end
        return
    end
    if not eventName then
       self._filters = callback
       log.debug("Added global filter: %s", tostring(callback))
       return
    end
    if self._filters[eventName] and not self._filters[eventName] == callback then
        errorManager.error("Cannot add multiple filters for the same event", 2)
    end
    self._filters[eventName] = callback
    log.debug("Added filter for event '%s': %s", eventName, tostring(callback))
end

--- Remove a filter for a specific event or a global filter
---@param callback gui.FilterFunction
function UiElement:removeFilter(callback)
    if type(self._filters) == "function" then
        if self._filters == callback then
            self._filters = {}
        end
        return
    end
---@diagnostic disable-next-line: param-type-mismatch
    for name, filter in pairs(self._filters) do
        if filter == callback then
            self._filters[name] = nil
            log.debug("Removed filter: %s", tostring(callback))
            return
        end
    end
    log.warn("Tried to remove filter that was not found: %s", tostring(callback))
end

--- Add an event handler for a specific event or a global event handler
--- If `eventName` is not provided, the handler will be applied globally.
--- Only one global handler is allowed per element, if a global handler is already set you first have to remove it
--- You can add multiple handlers for specific events, but only if no global handler is set.
--- You can only add one handler per event type
--- 
--- @param callback gui.EventHandler
--- @param eventName string|nil
function UiElement:addEventHandler(callback, eventName)
    if type(self._eventHandlers) == "function" then
        if eventName then
            errorManager.error("Cannot add event handler for specific event to element with global event handler", 2)
        end
        if self._eventHandlers ~= callback then
            errorManager.error("Cannot add multiple global event handlers to the same element", 2)
        end
        return
    end
    if not eventName then
        self._eventHandlers = callback
        log.debug("Added global event handler: %s", tostring(callback))
        return
    end
    if self._eventHandlers[eventName] and not util.contains(self._eventHandlers[eventName], callback) then
        errorManager.error("Cannot add multiple event handlers for the same event", 2)
    end
    self._eventHandlers[eventName] = callback
    log.debug("Added event handler for event '%s': %s", eventName, tostring(callback))
end

--- Remove an event handler for a specific event or a global event handler
--- @param callback gui.EventHandler
function UiElement:removeEventHandler(callback)
    if type(self._eventHandlers) == "function" then
        if self._eventHandlers == callback then
            self._eventHandlers = {}
            log.debug("Removed global event handler: %s", tostring(callback))
        else
            log.warn("Tried to remove event handler that was not found: %s", tostring(callback))
        end
        return
    end
---@diagnostic disable-next-line: param-type-mismatch
    for eventName, handler in pairs(self._eventHandlers) do
        if handler == callback then
            self._eventHandlers[eventName] = nil
            log.debug("Removed event handler for event '%s': %s", eventName, tostring(callback))
            return
        end
    end
    log.warn("Tried to remove event handler that was not found: %s", tostring(callback))
end

return UiElement