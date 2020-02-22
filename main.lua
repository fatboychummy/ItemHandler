local funcs = {}
local erString = "Bad argument #%d: %s"
local tpString = "Bad argumend #%d: Expected %s, got %s."
local ok, utils = pcall(require, "utils")

-- Things that are recognized as inventories...
-- Add or remove things as needed.
local inventoryTypes = {
  "chest",
  "shulker_box",
  --"cache",
  --"strongbox"
}
inventoryTypes.n = #inventoryTypes

-- Checks if the util module is loaded.
-- if the module fails to load, will not error immediately (until a function
-- which uses a util function is run)
local function checkUtil()
  if type(utils) ~= "table" then
    print()
    printError("Module 'utils' failed to load.")
    error("Please manually pass the loaded module to 'init'", 2)
  end
end

-- If the utils module fails to load, run this in your program with the utils
-- module as an input.
function funcs.init(uts)
  if type(uts) == "table" then
    if uts.dCopy then
      utils = uts
      return
    end
    error(string.format(erString, 1, "Utils table missing deep-copy method 'dCopy'."))
  end
  error(string.format(tpString, 1, "table", type(uts)))
end

-- Returns the inventory types
function funcs.getInventoryTypes()
  return inventoryTypes
end

-- Adds a new type of inventory to check
function funcs.addInventoryType(tp)
  inventoryTypes.n = inventoryTypes.n + 1
  inventoryTypes[inventoryTypes.n] = tp
end

-- gets all inventory names matching those in the inventoryTypes table
-- does not match exact names, just looks for names containing the items in
-- inventoryTypes.
function funcs.listInventories()
  local ret = {n = 0}

  local periphs = peripheral.getNames()
  for i = 1, #periphs do
    local current = periphs[i]
    for j = 1, inventoryTypes.n do
      if peripheral.getType(current):find(inventoryTypes[j]) then
        ret.n = ret.n + 1
        ret[ret.n] = current
      end
    end
  end

  return ret
end

-- Returns a table of tables, where the key for each table is the inventory name
-- and the value is the inventory's contents.
function funcs.listItemsByInventory()
  checkUtil()
  local invNames = funcs.listInventories()

  local invs = {}

  for i = 1, invNames.n do
    local cInv = invNames[i]
    local sz = peripheral.call(cInv, "size")
    local items = peripheral.call(cInv, "list")
    invs[cInv] = {}
    for j = 1, sz do
      if items[j] then
        invs[cInv][j] = utils.dCopy(items[j])
      end
    end
  end
  return invs
end

-- Returns a table containing a list of all items.
-- Items are condensed, so count is the total count of items.
function funcs.listItems()
  checkUtil()
  local invNames = funcs.listInventories()
  local items = {n = 0}

  -- inserts an item into the items table.
  -- if the item exists already, just add to it's count.
  local function insert(x)
    local temp = utils.dCopy(x)
    -- check if the item exists already
    for i = 1, items.n do
      local item = items[i]
      if item.name == temp.name and item.damage == temp.damage then
        item.count = item.count + temp.count
        return
      end
    end
    -- if it doesn't, make it exist.
    items.n = items.n + 1
    items[items.n] = temp
  end

  -- for each inventory...
  for i = 1, invNames.n do
    local cInv = invNames[i]
    local sz = peripheral.call(cInv, "size")
    local cInvItems = peripheral.call(cInv, "list")
    -- for each slot...
    for j = 1, sz do
      -- if there's an item...
      if cInvItems[j] then
        -- insert it
        insert(cInvItems[j])
      end
    end
  end

  return items
end


-- get the full metadata of all items.
function funcs.getAllMetadata()
  checkUtil()
  local invNames = funcs.listInventories()

  local items = {n = 0}
  -- insert the item (if it doesn't already exist)
  local function insert(x)
    -- for each item
    for i = 1, items.n do
      local item = items[i]
      -- if the item exists
      if item.name == x.name and item.damage == x.damage then
        -- don't add it
        return
      end
    end
    items.n = items.n + 1
    items[items.n] = utils.dCopy(x)
  end

  -- for each inventory
  for i = 1, invNames.n do
    local cInv = invNames[i]
    local sz = peripheral.call(cInv, "size")
    -- for each slot in inventory
    for j = 1, sz do
      local itm = peripheral.call(cInv, "getItemMeta", j)
      -- if the slot is used, get the metadata.
      if itm then
        insert(itm)
      end
    end
  end

  return items
end

-- gets the total used slots and total slots
function funcs.getSlots()
  local invNames = funcs.listInventories()
  local used, total = 0, 0

  for i = 1, invNames.n do
    local cInv = invNames[i]
    local sz = peripheral.call(cInv, "size")
    local items = peripheral.call(cInv, "list")

    total = total + sz
    for j = 1, sz do
      if items[j] then
        used = used + 1
      end
    end
  end

  return used, total
end

return funcs
