local expect = require("cc.expect").expect

local class = require("ccmesystem.lib.class")
local log = require("ccmesystem.lib.log")
local util = require("ccmesystem.lib.util")

--- @class Items
local Items = class.class()

local function hashItem(name, nbt)
    if nbt then return name .. "@" .. nbt else return name end
end

local function unhashItem(hash)
    local name, nbt = hash:match("^([^@]+)@?(.*)$")
    if name then return name, nbt else return hash end
end

--- Get the details of an item. This is run on a background thread by @Items:getItem
--- 
--- @param self Items The current item instance
--- @param item table The item to get the details for 
local function getItemDetails(self, item)
    expect(1, item, "table")
    if item.details then return end

    local start = os.epoch("utc")
    for peripheralName, _ in pairs(item.locations) do
        local peripheral = self.peripherals[peripheralName]
        assert(peripheral, "Peripheral listed as source but not present")

        local index
        for i, content in pairs(peripheral.content) do
            if content.hash == item.hash then
                index = i
                break
            end
        end

        local details
        if peripheral.type == "inventory" then
            details = peripheral.getItemDetail(index)
        else -- item_storage
            details = peripheral.items()[index]
        end
        if (hashItem(details.name, details.nbt) == item.hash) then
            details.count = nil
            details.name = nil
            details.nbt = nil
            item.details = details
            self._context.mediator:publish("items.item_change", {[item] = true})
        end

        item.requested_details = nil
        log.info("Got details for %s in $.2fs => %s", item.hash, (os.epoch("utc") - start) * 1e-3, item.details ~= false)
    end
end

--- Get a item by its hash.
---
--- If the item is unkown to the system (or its details are not known for another reason), a job is scheduled to gather its details.
--- This assumes the items exists somewhere in the system. If it's not, this job is scheduled again when the items shows up.
---
--- @param self Items The current items instance
--- @param hash string The hash of the item
--- @return table Item The informations about the requested item
function Items:getItem(hash)
    expect(1, hash, "string")

    local item = self._items[hash]
    if not item then
        item = {hash = hash, count = 0, reserved = 0, details = false, requested_details = false, location = {}}
        self._items[hash] = item
    end
    if not item.details and not item.requested_details then
        item.requested_details = true
        self._taskPool.spawn(function () getItemDetails(self, item) end)
    end
    return item
end

--- Update the number of items in an peripheral and the system.
---
--- @param self Items The items instance
--- @param item table The item to update
--- @param peripheralName string Name of the peripheral
--- @param index number The index in the content table from the given peripheral
--- @param change number The value to increase or decrease the count by
local function updateItemCount(self, item, peripheralName, index, change)
    local peripheral = self.peripherals[peripheralName]
    local slot = peripheral.content[index]
    slot.count = slot.count + change

    if slot.count == 0 then
        peripheral.content[index] = nil
    elseif not slot.hash then
        slot.hash = item.hash
        slot.reserved = 0
    elseif slot.hash ~= item.hash then
        error("Hashes have changed (expected: " .. slot.hash .. ", got: " .. item.hash .. ")")
    end

    item.count = item.count + change
    item.locations[peripheralName] = item.locations[peripheralName] + change
    if item.locations[peripheralName] == 0 then
        item.locations[peripheralName] = nil
    end
end

--- Load a new peripheral into the system or update an existing one.
--- 
--- Function is called in a background thread by @Items:loadPeripheral
--- Uses `list()` or `items()` to get the content of the peripheral and update all internal item counts.
--- 
--- @param self Items The current items instance
--- @param peripheralName string The name of the peripheral
local function indexInventory(self, peripheralName)
    local start = os.epoch("utc")
    local peripheral = self.peripherals[peripheralName]
    local existingItems = peripheral.content
    local newItems
    if peripheral.type == "inventory" then
        newItems = peripheral.list()
    elseif peripheral.type == "item_storage" then
        newItems = peripheral.items()
    else
        log.error("Opps. Peripheral has an unsupported type: %s", peripheralName.type)
        error("Unsupported peripheral type")
    end
    local union = util.union(existingItems, newItems)
    local dirty = {}
    for i, _ in pairs(union) do
        local existingItem = existingItems[i]
        local newItem = newItems[i]
        -- item was removed unnoticed
        if not newItem then
            local item = self:getItem(existingItem.hash)
            dirty[item] = true
            updateItemCount(self, item, peripheralName, i, -existingItem.count)
        -- item was added or changed unnoticed
        else
            local hash = hashItem(newItem.name, newItem.nbt)
            local item = self:getItem(hash)
            -- item or count changed unnoticed
            if existingItem then
                -- only count changed
                if existingItem.hash == hash then
                    local change = newItem.count - existingItem.count
                    if change ~= 0 then
                        updateItemCount(self, item, peripheralName, i, change)
                        dirty[item] = true
                    end
                -- item changed
                else
                    local it = self:getItem(existingItem.hash)
                    updateItemCount(self, it, peripheralName, i, -existingItem.count)
                    dirty[it] = true
                    updateItemCount(self, item, peripheralName, i, newItem.count)
                    dirty[item] = true
                end
            -- add new item
            else
                updateItemCount(self, item, peripheralName, i, newItem.count)
                dirty[item] = true
            end
        end
    end
    self._context.mediator:publish("items.peripheral_change", peripheralName)
    self._context.mediator:publish("items.item_change", dirty)
    log.info("Indexed peripheral %s in %.2fs", peripheralName, (os.epoch("utc") - start) * 1e-3)
end

--- Method to load a peripheral into the system.
---
--- The system will index the peripheral and add its contents to the system item list.
--- The system can only access items from loaded peripherals.
--- Supported types:
--- - inventory
--- - item_storage
---
---@param peripheralName string The name of the peripheral
function Items:loadPeripheral(peripheralName)
    expect(1, peripheralName, "string")

    if not self.peripherals[peripheralName] then
        local peripheral = peripheral.wrap(peripheralName)
        if not peripheral then
            log.error("Peripheral not found: %s", peripheralName)
            return false, "Peripheral not found"
        end
        local peripheralType = peripheral.getType(peripheralName)
        if peripheralType ~= "inventory" and peripheralType ~= "item_storage" then
            error("The provied peripheral has a unkown type. The system only supports the inventory and item_storage type!")
        end
        local size
        if peripheral.size then
            size = peripheral.size()
        end
        self.peripherals[peripheralName] = {
            name = peripheralName,
            type = peripheralType,
            priority = 0,
            size = size,
            remote = peripheral,
            content = {},
            itemTypes = false,
            modifciationSeq = 0,
            lastScan = 0,
        }
    end
    self._taskPool.spawn(function () indexInventory(self, peripheralName) end)
end

--- Method to unload a peripheral from the system.
---
--- You should unload a peripheral properly before disconnecting it from the system.
--- This will remove all items from the system item list and stop all queued tasks for that peripheral.
---
---@param peripheralName string The name of the peripheral
function Items:unloadPeripheral(peripheralName)
    expect(1, peripheralName, "string")
    local start = os.epoch("utc")
    local peripheral = self.peripherals[peripheralName]
    -- If the inventory was never loaded, abort
    if not peripheral then return end

    local dirty = {}
    for i, content in pairs(peripheral.content) do
        local item = self:getItem(content.hash)
        updateItemCount(self, item, peripheralName, i, -content.count)
        dirty[item] = true
    end
    self.peripherals[peripheralName] = nil
    self._context.mediator:publish("items.peripheral_change", peripheralName)
    self._context.mediator:publish("items.item_change", dirty)
    log.info("Unloaded peripheral %s in %.2fs", peripheralName, (os.epoch("utc") - start) * 1e-3)
end

--- Method to sort the locations by there priority.
---
--- @param self Items The current items instance
--- @param peripherals table The locations to sort
local function sortPeripherals(self, peripherals)
    local sorted = {}
    for name, _ in pairs(peripherals) do
        table.insert(sorted, self.peripherals[name])
    end
    table.sort(sorted, function (a, b) return a.priority > b.priority end)
    return sorted
end

--- Method to insert an item into a peripheral.
---
--- @self Items The current items instance
--- @from string The name of the peripheral to insert the item from
--- @fromSlot number The slot of the item in the peripheral
--- @limit number The max number of items to insert
--- @peripheral string The name of the peripheral to insert the item to
--- @hash string The hash of the item to insert
local function insert_into(self, from, fromSlot, limit, peripheral, hash)
    if peripheral.itemTypes and not peripheral.itemTypes[hash] then return 0 end

    peripheral.modifciationSeq = peripheral.modifciationSeq + 1
    local success, count
    if peripheral.type == "inventory" then
        success, count = pcall(peripheral.remote.pullItems, from, fromSlot, limit)
    else -- item_storage
        success, count = pcall(peripheral.remote.pullItems, from, fromSlot, unhashItem(hash), limit)
    end
    if not success then
        log.error("Failed to insert %d x %s into %s: %s", limit, hash, peripheral.name, count)
        return 0
    end
    if count > 0 and peripheral.lastScan < peripheral.modifciationSeq then
        peripheral.lastScan = peripheral.modifciationSeq
        self._taskPool.spawn(function () indexInventory(self, peripheral.name) end)
    end
    return count
end

local function insertItemInternal(self, from, fromSlot, hash, limit)
    if limit <= 0 then return end

    log.debug("Inserting %d x %s from %s (slot %s)", limit, hash, from, fromSlot)
    local start, tried = os.epoch("utc"), 0
    local remaining = limit
    -- If the hash is known, try to place it into an existing stack
    if hash then
        local item = self:getItem(hash)
        for _, peripheral in pairs(sortPeripherals(self, item.locations)) do
            if remaining <= 0 then break end
            remaining = remaining - insert_into(self, from, fromSlot, remaining, peripheral, hash)
        end
    end
    -- If the hash is unknown, just put it anywhere
    for _, peripheral in pairs(sortPeripherals(self, self.peripherals)) do
        if remaining <= 0 then break end
        remaining = remaining - insert_into(self, from, fromSlot, remaining, peripheral, hash)
    end
    if remaining > 0 then
        log.warning("Storage full, could not insert %d x %s", remaining, hash)
        self._context.mediator:publish("items.storage_full")
    end
    log.info("Inserted %d x %s in %.2fs", limit - remaining, hash, (os.epoch("utc") - start) * 1e-3)
end

--- This method will insert an item into the system.
---
--- The system will determine the best inventory and move the item to that inventory.
--- The item will also be added to the system item list.
---
---@param from string The name of the peripheral
---@param fromSlot number The slot containing the item
---@param item table|number { name = string, count = number, nbt? = string }|number The item we're pulling. This should either be a slot from `list()` or `getItemDetails()`, or a simple limit if the item is unknown.
function Items:insertItem(from, fromSlot, item)
    expect(1, from, "string")
    expect(2, fromSlot, "number")
    expect(3, item, "table", "number")

    local hash, limit
    if (type(item) == "table") then
        hash = hashItem(item.name, item.nbt)
        limit = item.count
    else
        limit = item
    end

    self._taskPool:spawn(function () insertItemInternal(self, from, fromSlot, hash, limit) end)
end

--- This method will extract an item from the system.
---
--- The system will find the desired item amount and move it to the peripheral.
--- The items will be removed from the system item list.
---
--- @param peripheralName string The name of the peripheral to extract the item to
--- @param slot number The Slot where the item should be extracted to
--- @param count number The number of items to extract
--- @param itemName string The name of the item to extract
function Items:extractItem(peripheralName, slot, count, itemName)
end


--- @param context Context
function Items:constructor(context)
    self.items = {}
    self.peripherals = {}

    self._context = context
    self._taskPool = context._peripheralPool

end