local expect = require("cc.expect").expect

local class = require("ccmesystem.lib.class")
local log = require("ccmesystem.lib.log")
local util = require("ccmesystem.lib.util")

--- @class Items
local Items = class.class()

Items.ALLOWED_PERIPHERAL_TYPES = {
    ["inventory"] = true,
    ["item_storage"] = true,
}

local function hashItem(name, nbt)
    if nbt then return name .. "@" .. nbt else return name end
end

--- Converts a hash back into a name and nbt hash.
--- @param hash string hash of an item
--- @return string name name of the item
--- @return string? nbt nbt hash (optional)
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
        local peripheralObject = self.peripherals[peripheralName]
        assert(peripheralObject, "Peripheral listed as source but not present")

        local index
        for i, content in pairs(peripheralObject.content) do
            if content.hash == item.hash then
                index = i
                break
            end
        end

        local details
        if peripheralObject.type["inventory"] then
            details = peripheralObject.remote.getItemDetail(index)
        else -- item_storage
            details = peripheralObject.remote.items()[index]
        end
        if (hashItem(details.name, details.nbt) == item.hash) then
            details.count = nil
            details.name = nil
            details.nbt = nil
            item.details = details
            self._context.mediator:publish("items.item_change", {[item] = true})
        end

        item.requested_details = nil
        log.info("Got details for %s in %.2fs => %s", item.hash, (os.epoch("utc") - start) * 1e-3, item.details ~= false)
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

    local item = self.items[hash]
    if not item then
        item = {hash = hash, count = 0, reserved = 0, details = false, requested_details = false, locations = {}}
        self.items[hash] = item
    end
    if not item.details and not item.requested_details then
        item.requested_details = true
        self._context:spawnPeripheral(function () getItemDetails(self, item) end)
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
    expect(1, item, "table")
    expect(2, peripheralName, "string")
    expect(3, index, "number")
    expect(4, change, "number")
    if change == 0 then return end
    log.debug("Updating item %s in %s[%d] by %d", item.hash, peripheralName, index, change)

    local peripheralObject = self.peripherals[peripheralName]

    peripheralObject.content[index] = peripheralObject.content[index] or {count = 0}
    local slot = peripheralObject.content[index]
    slot.count = slot.count + change

    log.trace("updateItemCount: Item details: %s", util.serialize(item))
    log.trace("updateItemCount: Peripheral details: %s", util.serialize(self.peripherals[peripheralName]))
    log.trace("updateItemCount: Slot details: %s", util.serialize(slot))

    if slot.count == 0 then
        peripheralObject.content[index] = nil
    elseif not slot.hash then
        slot.hash = item.hash
        slot.reserved = 0
    elseif slot.hash ~= item.hash then
        log.error("Hashes have changed (expected: %s, got: %s)", slot.hash, item.hash)
        error("Hashes have changed (expected: " .. slot.hash .. ", got: " .. item.hash .. ")")
    end

    item.count = item.count + change
    item.locations[peripheralName] = (item.locations[peripheralName] or 0) + change
    if item.locations[peripheralName] == 0 then
        item.locations[peripheralName] = nil
    end

    log.trace("updateItemCount: Item details after update: %s", util.serialize(item))
    log.trace("updateItemCount: Peripheral details after update: %s", util.serialize(self.peripherals[peripheralName]))
    log.trace("updateItemCount: Slot details after update: %s", util.serialize(slot))
end

--- Load a new peripheral into the system or update an existing one.
--- 
--- Function is called in a background thread by @Items:loadPeripheral
--- Uses `list()` or `items()` to get the content of the peripheral and update all internal item counts.
--- 
--- @param self Items The current items instance
--- @param peripheralName string The name of the peripheral
local function indexInventory(self, peripheralName)
    expect(1, peripheralName, "string")
    log.debug("Start indexing peripheral %s", peripheralName)

    local start = os.epoch("utc")
    local peripheralObject = self.peripherals[peripheralName]
    local existingItems = peripheralObject.content
    local newItems
    if peripheralObject.type["inventory"] then
        newItems = peripheralObject.remote.list()
    elseif peripheralObject.type["item_storage"] then
        newItems = peripheralObject.remote.items()
    else
        log.error("Opps. Peripheral has an unsupported type: %s", util.serialize(peripheralName.type))
        error("Unsupported peripheral type")
    end
    local union = util.union(existingItems, newItems)
    log.trace("indexInventory: Existing items: %s", util.serialize(existingItems))
    log.trace("indexInventory: New items: %s", util.serialize(newItems))
    log.trace("indexInventory: Union of existing and new items: %s", util.serialize(union))
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
                        log.trace("indexInventory: Item %s count changed from %d to %d", existingItem.hash, existingItem.count, newItem.count)
                        updateItemCount(self, item, peripheralName, i, change)
                        dirty[item] = true
                    end
                -- item changed
                else
                    log.trace("indexInventory: Item %s changed to %s", existingItem.hash, hash)
                    local it = self:getItem(existingItem.hash)
                    updateItemCount(self, it, peripheralName, i, -existingItem.count)
                    dirty[it] = true
                    updateItemCount(self, item, peripheralName, i, newItem.count)
                    dirty[item] = true
                end
            -- add new item
            else
                log.trace("indexInventory: Adding new item %s", hash)
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
    log.debug("Loading peripheral %s", peripheralName)

    if not self.peripherals[peripheralName] then
        local wrapped = peripheral.wrap(peripheralName)
        if not wrapped then
            log.error("Peripheral not found: %s", wrapped)
            return false, "Peripheral not found"
        end
        local peripheralTypes = util.lookup({peripheral.getType(wrapped)})
        local isAllowed = false
        for type, _ in pairs(peripheralTypes) do
            if Items.ALLOWED_PERIPHERAL_TYPES[type] then
                isAllowed = true
                break
            end
        end
        if not isAllowed then
            log.error("The provied peripheral has no supported type (%s)." ..
                "The system only supports the inventory and item_storage type!", util.serialize(peripheralTypes))
            error(string.format("The provied peripheral has no supported type (%s). " ..
                "The system only supports the inventory and item_storage type!", util.serialize(peripheralTypes)), 2)
        end
        local size
        if wrapped.size then
            size = wrapped.size()
        end
        self.peripherals[peripheralName] = {
            name = peripheralName,
            type = peripheralTypes,
            priority = 0,
            size = size,
            remote = wrapped,
            content = {},
            itemTypes = false,
            modifciationSeq = 0,
            lastScan = 0,
        }
    end
    self._context:spawnPeripheral(function () indexInventory(self, peripheralName) end)
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
    local peri = self.peripherals[peripheralName]
    -- If the inventory was never loaded, abort
    if not peri then return end

    local dirty = {}
    for i, content in pairs(peri.content) do
        local item = self:getItem(content.hash)
        updateItemCount(self, item, peripheralName, i, -content.count)
        dirty[item] = true
    end
    self.peripherals[peripheralName] = nil
    self._context.mediator:publish("items.peripheral_change", peripheralName)
    self._context.mediator:publish("items.item_change", dirty)
    log.info("Unloaded peripheral %s in %.2fs", peripheralName, (os.epoch("utc") - start) * 1e-3)
end

--- Method to convert a list of locations to a list of peripherals.
--- 
--- @param self Items The current items instance
--- @param locations table The locations to convert
--- @return table peripherals The list of peripherals
local function locationToPeripheralList(self, locations)
    expect(1, locations, "table")

    local peripherals = {}
    for name, _ in pairs(locations) do
        peripherals[name] = self.peripherals[name]
    end
    return peripherals
end

--- Method to sort the locations by there priority.
---
--- @param self Items The current items instance
--- @param peripherals table The locations to sort
local function sortPeripherals(self, peripherals)
    expect(1, peripherals, "table")
    local sorted = {}
    for name, _ in pairs(peripherals) do
        table.insert(sorted, self.peripherals[name])
    end
    table.sort(sorted, function (a, b) return a.priority > b.priority end)
    return sorted
end

--- Method to insert an item into a peripheral.
---
--- @param self Items The current items instance
--- @param from string The name of the peripheral to insert the item from
--- @param fromSlot number The slot of the item in the peripheral
--- @param limit number The max number of items to insert
--- @param peripheralObject table The name of the peripheral to insert the item to
--- @param hash string The hash of the item to insert
local function insertInto(self, from, fromSlot, limit, peripheralObject, hash)

    if peripheralObject.itemTypes and (not hash or peripheralObject.itemTypes[hash]) then
        log.debug("Peripheral %s does not support item %s", peripheralObject.name, hash)
        return 0
    end

    peripheralObject.modifciationSeq = peripheralObject.modifciationSeq + 1
    local success, count
    if peripheralObject.type["inventory"] then
        success, count = pcall(peripheralObject.remote.pullItems, from, fromSlot, limit)
    elseif hash then -- item_storage
        success, count = pcall(peripheralObject.remote.pullItem, from, unhashItem(hash), limit)
    end
    if not success then
        log.error("Failed to insert %d x %s into %s: %s", limit, hash, peripheralObject.name, count)
        return 0
    end
    if count > 0 and peripheralObject.lastScan < peripheralObject.modifciationSeq then
        peripheralObject.lastScan = peripheralObject.modifciationSeq
        self._context:spawnPeripheral(function () indexInventory(self, peripheralObject.name) end)
    end
    return count
end

local function insertInternal(self, from, fromSlot, hash, limit)
    if limit <= 0 then return end

    log.debug("Inserting %d x %s from %s (slot %s)", limit, hash, from, fromSlot)
    local start, tried = os.epoch("utc"), 0
    local remaining = limit
    -- If the hash is known, try to place it into an existing stack
    if hash then
        local item = self:getItem(hash)
        for _, peripheralObject in ipairs(sortPeripherals(self, locationToPeripheralList(self,item.locations))) do
            if remaining <= 0 then break end
            remaining = remaining - insertInto(self, from, fromSlot, remaining, peripheralObject, hash)
        end
    end
    -- If the hash is unknown, just put it anywhere
    for _, peripheralObject in ipairs(sortPeripherals(self, self.peripherals)) do
        if remaining <= 0 then break end
        remaining = remaining - insertInto(self, from, fromSlot, remaining, peripheralObject, hash)
    end
    if remaining > 0 then
        log.warn("Storage may be full, could not insert %d x %s", remaining, hash)
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
function Items:insert(from, fromSlot, item)
    expect(1, from, "string")
    expect(2, fromSlot, "number")
    expect(3, item, "table", "number")

    local hash, limit
    if type(item) == "table" then
        hash = hashItem(item.name, item.nbt)
        limit = item.count
    else
        limit = item
    end

    self._context:spawnPeripheral(function () insertInternal(self, from, fromSlot, hash, limit) end)
end

-- Check the peripheral and the slot is the same. Might happen if we detach and attach a peripheral.
local function checkExtract(self, hash, name, peripheralObject, slot, slot_idx, detail)
    expect(2, hash, "string")
    expect(3, name, "string")
    expect(4, peripheralObject, "table")
    expect(5, slot, "table")
    expect(6, slot_idx, "number")
    expect(7, detail, "string")

    local newPeripheral = self.peripherals[name]
    if newPeripheral ~= peripheralObject then
      log.warn("Peripheral %s changed during transfer %s from slot #%d. %s", name, hash, slot_idx, detail)
      return false
    end

    assert(peripheralObject.content[slot_idx] == slot, "Peripheral slots have changed unknowingly")

    if slot.hash ~= hash then
      log.warn("Slot %s[%d] has changed for unknown reasons (did something external change the peripheral?). %s", name, slot_idx, detail)
      return false
    end

    return true
  end


--- This method will extract an item from the system.
---
--- The system will find the desired item amount and move it to the peripheral.
--- The items will be removed from the system item list.
---
--- @param toPeripheral string The peripheral to push to
--- @param hash string The hash of the item we're pushing
--- @param count number The number of items to push
function Items:extract(toPeripheral, hash, count, done)
    expect(1, toPeripheral, "string")
    expect(2, hash, "string")
    expect(3, count, "number")
    done = done or function () end;

    log.info("Extracting %d x %s to %s", count, hash, toPeripheral)

    local item = self:getItem(hash)
    if count <= 0 or not item or item.count == 0 then
        log.debug("No items to extract %s", hash)
        return done(0)
    end

    local tasks, transferred = 0, 0
    local function finishedJob(val)
        tasks = tasks - 1;
        transferred = transferred + val
        if tasks == 0 then done(transferred) end
    end
    log.trace("Item to extract: %s", util.serialize(item))
    log.trace("Peripherals to search for item: %s", util.serialize(sortPeripherals(self, locationToPeripheralList(self,item.locations))))
    for _, peripheralObject in ipairs(sortPeripherals(self, locationToPeripheralList(self,item.locations))) do
        log.debug("Check locations %s for %q", peripheralObject.name, hash)
        for i, slot in pairs(peripheralObject.content) do
            if slot.hash == hash and slot.count > slot.reserved then
                while slot.count - slot.reserved > 0 do
                    local toExtract = math.min(count, slot.count - slot.reserved, 128)
                    slot.reserved = slot.reserved + toExtract
                    count = count - toExtract
                    tasks = tasks + 1
                    log.debug("Extracting %d x %s from %s[%d] to %s", toExtract, hash, peripheralObject.name, i, toPeripheral)
                    self._context:spawnPeripheral(function ()
                        if not checkExtract(self, hash, peripheralObject.name, peripheralObject, slot, i,
                        "Skipping extract.") then
                            return finishedJob(0)
                        end
                        local success, extracted
                        if peripheralObject.type["inventory"] then
                            log.debug("Try to push %d x %s to %s[%d]", toExtract, hash, peripheralObject.name, i)
                            success, extracted = pcall(peripheralObject.remote.pushItems, toPeripheral, i, toExtract)
                        else -- item_storage
                            log.debug("Try to push %d x %s to %s[%d]", toExtract, hash, peripheralObject.name, i)
                            success, extracted = pcall(peripheralObject.remote.pushItem, toPeripheral, unhashItem(hash), toExtract)
                        end
                        if not checkExtract(self, hash, peripheralObject.name, peripheralObject, slot, i,
                        "Extract has happened, but not clear how to handle this!") then
                            return finishedJob(0)
                        end

                        slot.reserved = slot.reserved - toExtract

                        if not success then
                            log.error("%s.pushItems(...): %s", peripheralObject.name, extracted)
                            return finishedJob(0)
                        elseif extracted == nil then
                            return finishedJob(0)
                        end

                        if extracted ~= 0 then
                            updateItemCount(self, item, peripheralObject.name, i, -extracted)
                            self._context.mediator:publish("items.item_change", {[item] = true})
                        end

                        finishedJob(extracted)
                    end)
                    if count <= 0 then break end
                end
            end
        end
        if count <= 0 then break end
    end
    if tasks == 0 then
        if count ~= 0 then
            log.warn("Item stock is empty, but %d x %s could not be extracted", count, hash)
        end
        return done(0)
    end
end


--- @param context Context
function Items:constructor(context)
    self.items = {}
    self.peripherals = {}

    self._context = context

end

log.info("Loaded items module")
return Items