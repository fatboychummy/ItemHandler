local funcs = {}
local erString = "Bad argument #%d: %s"
local tpString = "Bad argumend #%d: Expected %s, got %s."

local ok, utils = pcall(require, "utils")


local inventoryTypes = {
  "chest",
  "shulker_box",
  --"cache",
  --"strongbox"
}
inventoryTypes.n = #inventoryTypes

local function checkUtil()
  if type(utils) ~= "table" then
    print()
    printError("Module 'utils' failed to load.")
    error("Please manually pass the loaded module to 'setup'", 2)
  end
end

function funcs.setup(uts)
  if type(uts) == "table" then
    if uts.dCopy then
      utils = uts
      return
    end
    error(string.format(erString, 1, "Utils table missing deep-copy method 'dCopy'."))
  end
  error(string.format(tpString, 1, "table", type(uts)))
end

function funcs.getInventoryTypes()
  return inventoryTypes
end

function funcs.addInventoryType(tp)
  inventoryTypes.n = inventoryTypes.n + 1
  inventoryTypes[inventoryTypes.n] = tp
end

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

function funcs.listItems()
  checkUtil()
  local invNames = funcs.listInventories()

  local items = {n = 0}
  local function insert(x)
    items.n = items.n + 1
    items[items.n] = utils.dCopy(x)
  end

  for i = 1, invNames.n do
    local cInv = invNames[i]
    local sz = peripheral.call(cInv, "size")
    local cInvItems = peripheral.call(cInv, "list")
    for j = 1, sz do
      if cInvItems[j] then
        insert(cInvItems[j])
      end
    end
  end

  return items
end

function funcs.getAllMetadata()
  checkUtil()
  local invNames = funcs.listInventories()

  local items = {n = 0}
  local function insert(x)
    items.n = items.n + 1
    items[items.n] = utils.dCopy(x)
  end

  for i = 1, invNames.n do
    local cInv = invNames[i]
    local sz = peripheral.call(cInv, "size")
    for j = 1, sz do
      local itm = peripheral.call(cInv, "getItemMeta", j)
      if itm then
        insert(itm)
      end
    end
  end

  return items
end

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
