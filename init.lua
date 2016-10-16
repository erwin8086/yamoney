--[[
	Yet another money by erwin8086
]]

yamoney = {}

-- Round number to 2 decimals
function yamoney.round(i)
	return math.floor(i*100)*0.01
end

-- All money values from biggest to smallest
yamoney.counts = {500, 200, 100, 50, 20, 10, 5, 2, 1, 0.50, 0.20, 0.10, 0.05, 0.02, 0.01}

local function add_or_drop(money, inv, player)
	if not money then return end
	local stack = ItemStack("yamoney:"..money*100)
	if inv:room_for_item("main", stack) then
		inv:add_item("main", stack)
	else
		minetest.item_drop(stack, player, player:get_pos())
	end
end

-- Pay Money to player
function yamoney.payout(count, player)
	local inv = player:get_inventory()
	for _, c in ipairs(yamoney.counts) do
		if count < 0.01 then break end
		while count >= c do
			add_or_drop(c, inv, player)
			count=count-c
		end
	end
end

-- Load all Components
local path = minetest.get_modpath("yamoney")
dofile(path.."/money.lua")
dofile(path.."/changing.lua")
dofile(path.."/store.lua")
dofile(path.."/default_store.lua")
dofile(path.."/wallet.lua")
dofile(path.."/card.lua")

-- areas support
if areas then
	dofile(path.."/areas.lua")
end

dofile(path.."/misc_store.lua")

if minetest.get_modpath("farming") then
	dofile(path.."/farming_store.lua")
end

if minetest.get_modpath("technic") or minetest.get_modpath("mesecons") then
	dofile(path.."/technic_store.lua")
end

if minetest.get_modpath("homedecor") then
	dofile(path.."/homedecor_store.lua")
end

dofile(path.."/recipes.lua")