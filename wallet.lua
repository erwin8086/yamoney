--[[
	The wallet for store money and other items
]]
-- The store for other items
local dinv
-- To add money to the wallet
local sinv
local uid = 1

-- Convert item list to table
-- Exec :to_table() on every stack
local function list2table(list)
	local t = {}
	for p, stack in ipairs(list) do
		if stack and not stack:is_empty() then
			t[p] = stack:to_table()
		end
	end
	return t
end

-- Check if the wallet is the same with the list
local function is_same(wallet, list)
	local data = minetest.deserialize(wallet:get_metadata())
	if not data then return false end
	if minetest.serialize(data.inv) == minetest.serialize(list2table(list)) then
		return true
	else
		return false
	end
end

-- Save list to wallet's stack metadata
local function save_list(inv, list, player)
	local list = list2table(inv:get_list(list))
	local wallet = player:get_wielded_item()
	local data = minetest.deserialize(wallet:get_metadata())
	if not data then return end
	data.inv = list
	wallet:set_metadata(minetest.serialize(data))
	player:set_wielded_item(wallet)
end

-- Show the wallet form on LMB
local function update_form(itemstack, placer, pt)
	local data = minetest.deserialize(itemstack:get_metadata())
	if not data or data == "" or not data.inv then
		data = {}
		data.inv = {}
		for _, c in ipairs(yamoney.counts) do
			data[c] = 0
		end
	end
	
	dinv:set_size("main"..uid, 4)
	dinv:set_list("main"..uid, data.inv)
	
	local f = "size[8,9]"..
	"list[detached:yamoney_wallet;main"..uid..";7,0;1,4;]"..
	"list[current_player;main;0,5;8,4;]"..
	"list[detached:yamoney_wallet_store;pay;2,0;1,1;]"..
	"label[0,0;PayIn:]"
	
	local y=1
	local x=0
	
	for _, c in ipairs(yamoney.counts) do
		if not data[c] then break end
		f=f.."item_image_button["..x..","..y..";1,1;yamoney:"..(c*100).." "..data[c]..";"..(c*100)..";]"
		x=x+1
		if x>6 then
			x=0
			y=y+1
		end
	end
	
	minetest.show_formspec(placer:get_player_name(), "yamoney:wallet", f)
	uid=uid+1
	itemstack:set_metadata(minetest.serialize(data))
	return itemstack
end

dinv = minetest.create_detached_inventory("yamoney_wallet", {
	allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
		local wallet = player:get_wielded_item()
		
		if wallet and not wallet:is_empty() and wallet:get_name() == "yamoney:wallet" and is_same(wallet, inv:get_list(to_list)) then
			return count
		end
		
		return 0
	end,
	
	allow_put = function(inv, listname, index, stack, player)
		local wallet = player:get_wielded_item()
		
		if stack and not stack:is_empty() and stack:get_name() == "yamoney:wallet" then return 0 end
		
		if wallet and not wallet:is_empty() and wallet:get_name() == "yamoney:wallet" and is_same(wallet, inv:get_list(listname)) then
			return stack:get_count()
		end
		
		return 0
	end,
	
	allow_take = function(inv, listname, index, stack, player)
		local wallet = player:get_wielded_item()
		
		if wallet and not wallet:is_empty() and wallet:get_name() == "yamoney:wallet" and is_same(wallet, inv:get_list(listname)) then
			return stack:get_count()
		end
		
		return 0
	end,
	
	on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		save_list(inv, to_list, player)
	end,
	
	on_put = function(inv, listname, index, stack, player)
		save_list(inv, listname, player)
	end,
	
	on_take = function(inv, listname, index, stack, player)
		save_list(inv, listname, player)
	end,
})

sinv = minetest.create_detached_inventory("yamoney_wallet_store", {
	allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	allow_take = function(inv, listname, index, stack, player)
		return 0
	end,
	
	allow_put = function(inv, listname, index, stack, player)
		local wallet = player:get_wielded_item()
		if wallet and not wallet:is_empty() and stack:get_definition().money then
			return stack:get_count()
		end
		return 0
	end,
	
	-- Add money to wallet
	on_put = function(inv, listname, index, stack, player)
		local wallet = player:get_wielded_item()
		local data = minetest.deserialize(wallet:get_metadata())
		local m = stack:get_definition().money
		data[m] = data[m] + stack:get_count()
		wallet:set_metadata(minetest.serialize(data))
		
		wallet = update_form(wallet, player, nil)
		player:set_wielded_item(wallet)
		
		inv:set_stack("pay", 1, nil)
	end,
	
})

sinv:set_size("pay", 1)

minetest.register_craftitem("yamoney:wallet", {
	description = "Wallet",
	inventory_image = "yamoney_wallet.png",
	stack_max = 1,
	on_secondary_use = update_form,
	on_place = update_form,
})

-- Pay out money from wallet
minetest.register_on_player_receive_fields(function(player, form, fields)
	if form ~= "yamoney:wallet" then return end
	if fields.quit then return end
	local wallet = player:get_wielded_item()
	if not wallet or wallet:is_empty() or wallet:get_name() ~= "yamoney:wallet" then return end
	local data = minetest.deserialize(wallet:get_metadata())
	if not data then return end
	
	local inv = player:get_inventory()
	
	for c, _ in pairs(fields) do
		c = tonumber(c)/100 or 0
		if c > 0 and data[c] > 0 then
			local stack = ItemStack("yamoney:"..c*100)
			if inv:room_for_item("main", stack) then
				inv:add_item("main", stack)
				data[c] = data[c] - 1
			end
		end
	end
	
	wallet:set_metadata(minetest.serialize(data))
	wallet = update_form(wallet, player, nil)
	
	player:set_wielded_item(wallet)
end)