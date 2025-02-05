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

local function getItemDetails(self, hash)
    local item = self._items[hash]
    if not item or item.details then return end
    for location, _ in pairs(item.locations) do
        local peripheral = self._inventories[location]
        for i, content in pairs(peripheral.content) do
            if content.name == hash then
                local details
                if peripheral.type == "inventory" then
                    details = peripheral.getItemDetail(i)
                else -- item_storage
                    details = peripheral.items()[i]
                end
                details.count = nil
                details.name = nil
                details.nbt = nil
                item.details = details
                return
            end
        end
    end
end

--- @param self Items
--- @param peripheralName string
local function indexInventory(self, peripheralName)
    local peripheral = self._inventories[peripheralName]
    local items
    if peripheral.type == "inventory" then
        items = peripheral.list()
    elseif peripheral.type == "item_storage" then
        items = peripheral.items()
    else
        log.error("Opps. Peripheral has an unsupported type: %s", peripheralName.type)
        error("Unsupported peripheral type")
    end

    for slot, item in pairs(items) do
        local hash = hashItem(item.name, item.nbt)
        local savedItem = self._items[hash]
        if not savedItem then
            savedItem = {count = 0, locations = {}, reservedCount = 0}
            if peripheral.type == "item_storage" then
                local details = util.copy(item)
                details.count = nil
                details.name = nil
                details.nbt = nil
                savedItem.details = details
            else
                self._taskPool.spawn(function () getItemDetails(self, hash) end)
            end
        end
        savedItem.count = savedItem.count + item.count
        savedItem.locations[peripheralName] = savedItem.locations[peripheralName] or {}
        savedItem.locations[peripheralName][slot] = item.count
    end
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