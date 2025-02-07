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
    for i, _ in pairs(item.locations) do
        local peripheral = self._inventories[i]
        assert(peripheral, "Peripheral listed as source but not present")

        local index
        for j, content in pairs(peripheral.content) do
            if content.hash == item.hash then
                index = j
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
    local peripheral = self.inventory[peripheralName]
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
--- @param self Items
--- @param peripheralName string
local function indexInventory(self, peripheralName)
    local start = os.epoch("utc")
    local peripheral = self._inventories[peripheralName]
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
                    -- remove old item
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
    self._context.mediator:publish("items.inventory_change", peripheralName)
    self._context.mediator:publish("items.item_change", dirty)
    log.info("Indexed Peripheral %s in %.2fs", peripheralName, (os.epoch("utc") - start) * 1e-3)
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

    if not self._inventories[peripheralName] then
        local peripheral = peripheral.wrap(peripheralName)
        if not peripheral then
            log.error("Peripheral not found: %s", peripheralName)
            return false, "Peripheral not found"
        end
        local peripheralType = peripheral.getType(peripheralName)
        if peripheralType ~= "inventory" and peripheralType ~= "item_storage" then
            log.error("The provied peripheral has a unkown type. The system only supports the inventory and item_storage type!")
        end
        local size
        if peripheral.size then
            size = peripheral.size()
        end
        self._inventories[peripheralName] = {
            type = peripheralType,
            priority = 0,
            size = size,
            remote = peripheral,
        }
    end
    self._context.mediator:publish("peripheral_loaded", peripheralName)
    self._taskPool.spawn(function () indexInventory(self, peripheralName) end)
end

--- Method to unload a peripheral from the system.
---
--- You should unload a peripheral properly before disconnecting it from the system.
--- This will remove all items from the system item list and stop all queued tasks for that peripheral.
function Items:unloadPeripheral(peripheralName)
    expect(1, peripheralName, "string")

    local peripheral = self._inventories[peripheralName]
    if not peripheral then return end

    for _, item in pairs(peripheral.content) do
        local savedItem = self._items[item.name]
        savedItem.count = savedItem.count - item.count
        savedItem.locations[peripheralName] = nil
    end
    self._inventories[peripheralName] = nil
end

--- This method will insert an item into the system.
---
--- The system will determine the best inventory and move the item to that inventory.
--- The item will also be added to the system item list.
---
---@param peripheralName string The name of the peripheral
---@param slot number The slot containing the item
---@param count number Number of items to insert
function Items:insertItem(peripheralName, slot, count)

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
    self.inventories = {}

    self._context = context
    self._taskPool = context._peripheralPool

end