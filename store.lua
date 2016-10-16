--[[
	A store from this mod itself
	and a custom store configurable ingame
]]

-- Register a static store(definied in lua)
-- See default_store.lua
function yamoney.register_store(name, text, desc, def)
	local function get_formspec(mode, money)
		local f = "size[8,9]"..
			"list[current_player;main;0,5;8,4;]"..
			"list[context;pay;5,4;1,1;]"..
			"label[3,4;PayIn: "..money.."]"
		local cost
		-- Modes buy and sell
		-- If you sell an item you get price*0.55 Euro
		if mode == "buy" then
			cost = 1
			f=f.."button[6,4;2,1;mode;Buy]"
		else
			cost = 0.55
			f=f.."button[6,4;2,1;mode;Sell]"
		end
		local x = 0
		local y = 0
		for c, item in ipairs(def) do
			f=f.."item_image_button["..x..","..y..";1,1;"..item[1]..";"..c..";"..yamoney.round(item[2]*cost).."E]"
			x=x+1
			if x > 7 then
				x = 0
				y=y+1
			end
		end
		return f
	end
	
	-- The definition for the Node
	local ndef = {
		description = desc,
		tiles = {text},
		groups = {choppy=3, oddly_breakable_by_hand=1},
		
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("mode", "buy")
			meta:set_string("formspec", get_formspec("buy", 0))
			meta:get_inventory():set_size("pay", 1)
			meta:set_string("infotext", desc)
		end,
		
		allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
			return 0
		end,
		
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if stack:get_name() == "yamoney:card" then return stack:get_count() end
			return 0
		end,
		
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			local meta = minetest.get_meta(pos)
			if (stack:get_definition().money and meta:get_string("mode") == "buy") or (stack:get_name() == "yamoney:card"  and meta:get_int("money") == 0) then
				return stack:get_count()
			else
				return 0
			end
		end,
		
		-- Pay in money and accepts cards
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			local meta = minetest.get_meta(pos)
			if stack and stack:get_name() == "yamoney:card" then
				local c = yamoney.get_card(stack)
				if not c then return end
				meta:set_string("formspec", get_formspec(meta:get_string("mode"), c:get_count()))
				return
			end
			local money = stack:get_count() * stack:get_definition().money + meta:get_int("money")/100
			
			meta:get_inventory():set_stack("pay", 1, nil)
			
			meta:set_string("formspec", get_formspec(meta:get_string("mode"), money))
			
			meta:set_int("money", money*100)
		end,
		
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			if stack and stack:get_name() == "yamoney:card" then
				local meta = minetest.get_meta(pos)
				meta:set_string("formspec", get_formspec(meta:get_string("mode"), 0))
			end
		end,
		
		-- Buy or Sell items
		on_receive_fields = function(pos, formname, fields, sender)
			-- Load money and card
			local meta = minetest.get_meta(pos)
			local money = meta:get_int("money")/100
			
			local minv = meta:get_inventory()
			local scard = minv:get_stack("pay", 1)
			local card = yamoney.get_card(scard)
			
			-- Pay out money if ESC
			if fields.quit then
				yamoney.payout(money, sender)
				meta:set_int("money", 0)
				meta:set_string("mode", "buy")
				if card then
					local pinv = sender:get_inventory()
					if pinv:room_for_item("main", card) then
						pinv:add_item("main", scard)
					else
						minetest.item_drop(scard, sender, sender:get_pos())
					end
					minv:set_stack("pay", 1, nil)
				end
				meta:set_string("formspec", get_formspec("buy", 0))
				return
			end
			
			-- Switch mode between buy or sell
			if fields.mode then
				if meta:get_string("mode") == "buy" then
					yamoney.payout(money, sender)
					meta:set_int("money", 0)
					if card then
						meta:set_string("formspec", get_formspec("sell", card:get_count()))
					else
						meta:set_string("formspec", get_formspec("sell", 0))
					end
					meta:set_string("mode", "sell")
				else
					meta:set_int("money", 0)
					if card then
						meta:set_string("formspec", get_formspec("buy", card:get_count()))
					else
						meta:set_string("formspec", get_formspec("buy", 0))
					end
					meta:set_string("mode", "buy")
				end
				return nil
			end
			
			-- Process Orders
			for i, _ in pairs(fields) do
				i = tonumber(i)
				if i and def[i] then
					-- def[i][1] = item string, def[i][2] = cost
					local item = def[i]
					if meta:get_string("mode") == "buy" and (money >= item[2] or (card and card:get_count() >= item[2])) then
						local inv = sender:get_inventory()
						local stack = ItemStack(item[1])
						if inv:room_for_item("main", stack) then
							inv:add_item("main", stack)
							if card and card:rm_money(item[2], "Buy'd "..item[1]) then
								meta:set_string("formspec", get_formspec("buy", card:get_count()))
							else
								money = money - item[2]
								meta:set_string("formspec", get_formspec("buy", money))
							end
						end
					elseif meta:get_string("mode") == "sell" then
						-- Sell items to this store at price*0.55
						local inv = sender:get_inventory()
						local stack = ItemStack(item[1])
						if inv:contains_item("main", stack) then
							inv:remove_item("main", stack)
							if card then
								card:add_money(yamoney.round(item[2]*0.55), "Sell't "..item[1])
								meta:set_string("formspec", get_formspec("sell", card:get_count()))
							else
								yamoney.payout(yamoney.round(item[2]*0.55), sender)
							end
						end
					end
				end
			end
			
			-- Save Money and Card
			if card then
				scard = card:save(scard)
				minv:set_stack("pay", 1, scard)
			end
			
			meta:set_int("money", money*100)
		end,
	}
	minetest.register_node("yamoney:"..name, ndef)
end

-- Formspec for the ingame definied store
--[[
	inv1, inv2, inv3 = view page of inventory(for store items to sell and item buy'd)
	config = The Configuration of stack to sell or buy and price
	sell = Buy item from player (sell for the view of the player)
	buy = Sell item to player
]]
local function get_formspec(mode, money, cfg, inv)
	if mode == "inv1" then
		return "size[8,9]"..
			"list[context;main;0,0;8,3;]"..
			"list[current_player;main;0,5;8,4;]"..
			"button[6,4;2,1;inv2;Next]"..
			"button[3,4;2,1;config;Config]"
	elseif mode == "inv2" then
		return "size[8,9]"..
			"list[context;main;0,0;8,3;24]"..
			"list[current_player;main;0,5;8,4;]"..
			"button[6,4;2,1;inv3;Next]"..
			"button[3,4;2,1;config;Config]"..
			"button[0,4;2,1;inv1;Prev]"
	elseif mode == "inv3" then
		return "size[8,9]"..
			"list[context;main;0,0;8,3;48]"..
			"list[current_player;main;0,5;8,4;]"..
			"button[0,4;2,1;inv2;Prev]"..
			"button[3,4;2,1;config;Config]"
	elseif mode == "config" then
		return "size[8,10]"..
			"button[0,9;2,1;mode;Exit]"..
			"button[3,9;2,1;inv1;Inventory]"..
			"button[6,9;2,1;admin;Set Admin]"..
			"label[0,0;Buy:]"..
			"label[4,0;Sell]"..
			"list[context;buy;0,1;1,4;]"..
			"list[context;sell;4,1;1,4]"..
			"field[2,1.3;1,1;buy1;for:;"..cfg.buy[1].."]"..
			"field[2,2.3;1,1;buy2;for:;"..cfg.buy[2].."]"..
			"field[2,3.3;1,1;buy3;for:;"..cfg.buy[3].."]"..
			"field[2,4.3;1,1;buy4;for:;"..cfg.buy[4].."]"..
			"field[6,1.3;1,1;sell1;for:;"..cfg.sell[1].."]"..
			"field[6,2.3;1,1;sell2;for:;"..cfg.sell[2].."]"..
			"field[6,3.3;1,1;sell3;for:;"..cfg.sell[3].."]"..
			"field[6,4.3;1,1;sell4;for:;"..cfg.sell[4].."]"..
			"list[current_player;main;0,5;8,4;]"..
			"label[7,0;Save: "..money.."]"..
			"list[context;pay;7,1;1,1;]"..
			"button[7,2;1,1;save;E]"
	elseif mode == "buy" then
		local f = "size[8,9]"..
			"list[current_player;main;0,5;8,4;]"..
			"list[context;pay;5,4;1,1;]"..
			"label[3,4;PayIn: "..money.."]"..
			"button[0,4;1,1;config;C]"..
			"button[6,4;2,1;mode;Buy]"
		
		-- Draw item icons
		for i, stack in ipairs(inv:get_list("buy")) do
			if not stack:is_empty() then
				local stack = stack:get_name() .. " " .. stack:get_count()
				local cost = cfg.buy[i] or 0
				if cost > 0 then
					f=f.."item_image_button["..i..",0;1,1;"..stack..";1;"..cost.."]"
				end
			end
		end
			
		return f
	
	elseif mode == "sell" then
		local f = "size[8,9]"..
			"list[current_player;main;0,5;8,4;]"..
			"button[0,4;1,1;config;C]"..
			"button[6,4;2,1;mode;Sell]"..
			"list[context;pay;5,4;1,1;]"..
			"label[3,4;PayIn: "..money.."]"
		
		-- Draw item icons
		for i, stack in ipairs(inv:get_list("sell")) do
			if not stack:is_empty() then
				local stack = stack:get_name() .. " " .. stack:get_count()
				local cost = cfg.sell[i] or 0
				if cost > 0 then
					f=f.."item_image_button["..i..",0;1,1;"..stack..";1;"..cost.."]"
				end
			end
		end
		return f
	end
end

-- The Store node itself
minetest.register_node("yamoney:store", {
	tiles = {"default_wood.png^yamoney_1e.png"},
	description = "Custom Store",
	groups = {choppy=3, oddly_breakable_by_hand=1},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		
		meta:set_int("money", 0)
		meta:set_string("mode", "config")
		meta:set_int("admin", 0)
		meta:set_int("money_save")
		
		inv:set_size("main", 8*9)
		inv:set_size("pay", 1)
		inv:set_size("sell", 4)
		inv:set_size("buy", 4)
		
		local cfg = {["buy"] = {0,0,0,0}, ["sell"] = {0,0,0,0}}
		meta:set_string("cfg", minetest.serialize(cfg))
		meta:set_string("formspec", get_formspec("config", 0, cfg))
	end,
	
	-- Set Owner
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
	end,
	
	-- Process actions
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		
		-- Save config
		if meta:get_string("mode") == "config" and not fields.quit then
			local cfg = {}
			cfg.buy = {}
			cfg.buy[1] = yamoney.round(tonumber(fields.buy1 or "0")) or 0
			cfg.buy[2] = yamoney.round(tonumber(fields.buy2 or "0")) or 0
			cfg.buy[3] = yamoney.round(tonumber(fields.buy3 or "0")) or 0
			cfg.buy[4] = yamoney.round(tonumber(fields.buy4 or "0")) or 0
			cfg.sell = {}
			cfg.sell[1] = yamoney.round(tonumber(fields.sell1 or "0")) or 0
			cfg.sell[2] = yamoney.round(tonumber(fields.sell2 or "0")) or 0
			cfg.sell[3] = yamoney.round(tonumber(fields.sell3 or "0")) or 0
			cfg.sell[4] = yamoney.round(tonumber(fields.sell4 or "0")) or 0
			meta:set_string("cfg", minetest.serialize(cfg))
		end
		
		-- Show formspec
		if fields.inv1 then
			meta:set_string("mode", "inv1");
			meta:set_string("formspec", get_formspec("inv1", 0))
		elseif fields.inv2 then
			meta:set_string("mode", "inv2");
			meta:set_string("formspec", get_formspec("inv2", 0))
		elseif fields.inv3 then
			meta:set_string("mode", "inv3");
			meta:set_string("formspec", get_formspec("inv3", 0))
		elseif fields.config then
			if owner and owner ~= "" and owner ~= sender:get_player_name() then return end
			meta:set_string("mode", "config");
			meta:set_string("formspec", get_formspec("config", meta:get_int("money_save")/100, minetest.deserialize(meta:get_string("cfg"))))
			local inv = meta:get_inventory()
			local card = inv:get_stack("pay", 1)
			if card and card:get_name() == "yamoney:card" then
				local pinv = sender:get_inventory()
				if pinv:room_for_item("main", card) then
					pinv:add_item("main", card)
				else
					minetest.item_drop(card, sender, sender:get_pos())
				end
				inv:set_stack("pay", 1, nil)
			end
		-- Switch mode (buy or sell)
		elseif fields.mode then
			local inv = meta:get_inventory()
			local scard = inv:get_stack("pay", 1)
			local card = yamoney.get_card(scard)
			if meta:get_string("mode") == "buy" then
				meta:set_string("mode", "sell");
				if card then
					meta:set_string("formspec", get_formspec("sell", card:get_count(), minetest.deserialize(meta:get_string("cfg")), inv))
				else
					meta:set_string("formspec", get_formspec("sell", 0, minetest.deserialize(meta:get_string("cfg")), inv))
					yamoney.payout(meta:get_int("money")/100, sender)
					meta:set_int("money", 0)
				end
			else
				meta:set_string("mode", "buy");
				if card then
					meta:set_string("formspec", get_formspec("buy", card:get_count(), minetest.deserialize(meta:get_string("cfg")), inv))
				else
					meta:set_string("formspec", get_formspec("buy", meta:get_int("money")/100, minetest.deserialize(meta:get_string("cfg")), inv))
				end
			end
		-- Close the store eject card or money
		elseif fields.quit then
			local inv = meta:get_inventory()
			local card = inv:get_stack("pay", 1)
			if card and not card:is_empty() then
				local pinv = sender:get_inventory()
				if pinv:room_for_item("main", card) then
					pinv:add_item("main", card)
				else
					minetest.item_drop(card, sender, sender:get_player_name())
				end
				inv:set_stack("pay", 1, nil)
			else
				yamoney.payout(meta:get_int("money")/100, sender)
				meta:set_int("money", 0)
				meta:set_string("mode", "buy")
			end
			meta:set_string("formspec", get_formspec("buy", 0, minetest.deserialize(meta:get_string("cfg")), meta:get_inventory()))
		elseif fields.admin then
			-- Set Admin
			-- If admin this store runs for ever without maintaince
			if minetest.get_player_privs(sender:get_player_name()) then
				meta:set_int("admin", 1)
			end
		-- Eject card or money from the save(the money from the owner)
		elseif fields.save then
			if owner and owner ~= "" and owner ~= sender:get_player_name() then return end
			local inv = meta:get_inventory()
			local card = inv:get_stack("card", 1)
			if card and not card:is_empty() then
				local pinv = sender:get_inventory()
				if pinv:room_for_item("main", card) then
					pinv:add_item("main", card)
				else
					minetest.item_drop(card, sender, sender:get_pos())
				end
				inv:set_stack("card", 1, nil)
				meta:set_string("formspec", get_formspec("config", 0, minetest.deserialize(meta:get_string("cfg"))))
			else
				yamoney.payout(meta:get_int("money_save")/100, sender)
				meta:set_int("money_save",0)
				meta:set_string("formspec", get_formspec("config", 0, minetest.deserialize(meta:get_string("cfg"))))
			end
		-- Process buy or sell
		else
			local cfg = minetest.deserialize(meta:get_string("cfg"))
			local inv = meta:get_inventory()
			local money = meta:get_int("money")/100
			local pinv = sender:get_inventory()
			-- The Card in the save
			local scard = inv:get_stack("card", 1)
			local card = yamoney.get_card(scard)
			-- The Card in the pay slot(from user of the machine)
			local bscard = inv:get_stack("pay", 1)
			local bcard = yamoney.get_card(bscard)
			
			-- Sell item to Player
			if meta:get_string("mode") == "buy" then
				for i, _ in pairs(fields) do
					i = tonumber(i) or 0
					local stack = inv:get_stack("buy", i)
					if cfg.buy[i] and not stack:is_empty() then
						if (money >= cfg.buy[i] or (bcard and bcard:get_count() >= cfg.buy[i])) and pinv:room_for_item("main", stack) then
							if meta:get_int("admin") > 0 or inv:contains_item("main", stack) then
								if bcard and bcard:rm_money(cfg.buy[i], "Buy'd "..stack:to_string()) then
								
								else
									money = money - cfg.buy[i]
								end
								pinv:add_item("main", stack)
								if meta:get_int("admin") <= 0 then
									if card then
										card:add_money(cfg.buy[i], sender:get_player_name().." has buy'd "..stack:to_string())
									else
										meta:set_int("money_save", meta:get_int("money_save") + cfg.buy[i]*100)
									end
									inv:remove_item("main", stack)
								end
							end
						end
					end
				end
				if bcard then
					meta:set_string("formspec", get_formspec("buy", bcard:get_count(), cfg, inv))
				else
					meta:set_string("formspec", get_formspec("buy", money, cfg, inv))
				end
			-- Buy item from Player
			else
				for i, _ in pairs(fields) do
					i = tonumber(i) or 0
					local stack = inv:get_stack("sell", i)
					if cfg.sell[i] and not stack:is_empty() then
						if pinv:contains_item("main", stack) then
							local save = meta:get_int("money_save")/100
							if meta:get_int("admin") > 0 or ((save >= cfg.sell[i] or (card and card:get_count() >= cfg.sell[i])) and inv:room_for_item("main", stack)) then
								pinv:remove_item("main", stack)
								if bcard then
									bcard:add_money(cfg.sell[i], "Sell'd "..stack:to_string())
								else
									yamoney.payout(cfg.sell[i], sender)
								end
								
								if meta:get_int("admin") <= 0 then
									inv:add_item("main", stack)
									if card and card:rm_money(cfg.sell[i], "You have buy'd "..stack:to_string().." from "..sender:get_player_name()) then
									
									else
										save = save - cfg.sell[i]
										meta:set_int("money_save", save*100)
									end
								end
							end
						end
					end
					
				end
				
				if bcard then
					meta:set_string("formspec", get_formspec("sell", bcard:get_count(), cfg, inv))
				end
			end
			-- Save all data
			meta:set_int("money", money*100)
			
			if card then
				scard = card:save(scard)
				inv:set_stack("card", 1, scard)
			end
			
			if bcard then
				bscard = bcard:save(bscard)
				inv:set_stack("pay", 1, bscard)
			end
		end
	end,
	
	-- Allow no move in pay
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if from_list == "pay" or to_list == "pay" then
			return 0
		else
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner and owner ~= "" and owner ~= player:get_player_name() then
				return 0
			else
				return count
			end
		end
	end,
	
	--[[
		Allow only put card or money in the pay slot
	]]
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "pay" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local card = inv:get_stack("card", 1)
			if stack:get_definition().money and not (meta:get_string("mode") == "config" and (card and card:get_name() == "yamoney:card")) then
				return stack:get_count()
			elseif stack:get_name() == "yamoney:card" and meta:get_int("money") == 0 then
				if meta:get_string("mode") == "config" then
					if card and card:get_name() == "yamoney:card" then
						return 0
					else
						return 1
					end
				else
					return 1
				end
			else
				return 0
			end
		else
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner and owner ~= "" and owner ~= player:get_player_name() then
				return 0
			else
				return stack:get_count()
			end
		end
	end,
	
	-- Not take in pay(except for card) and only owner can take from main
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "pay" then
			if stack:get_name() == "yamoney:card" then return stack:get_count() end
			return 0
		else
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner and owner ~= "" and owner ~= player:get_player_name() then
				return 0
			else
				return stack:get_count()
			end
		end
	end,
	
	-- Add Money and process cards for buy, sell and config
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "pay" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local card = yamoney.get_card(stack)
			if card then
				if meta:get_string("mode") == "config" then
					inv:set_size("card", 1)
					inv:set_stack("card", 1, stack)
					inv:set_stack("pay", 1, nil)
					meta:set_string("formspec", get_formspec("config", card:get_count(), minetest.deserialize(meta:get_string("cfg"))))
				else
					meta:set_string("formspec", get_formspec("buy", card:get_count(), minetest.deserialize(meta:get_string("cfg")), inv))
				end
				return
			end
			if meta:get_string("mode") == "buy" then
				local money = stack:get_count() * stack:get_definition().money + meta:get_int("money")/100
				inv:set_stack("pay", 1, nil)
				meta:set_int("money", money*100)
				meta:set_string("formspec", get_formspec("buy", money, minetest.deserialize(meta:get_string("cfg")), inv))
			else
				local money = stack:get_count() * stack:get_definition().money + meta:get_int("money_save")/100
				inv:set_stack("pay", 1, nil)
				meta:set_int("money_save", money*100)
				meta:set_string("formspec", get_formspec("config", money, minetest.deserialize(meta:get_string("cfg"))))
			end
		end
	end,
	
	-- Handle take cards
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "pay" and stack and stack:get_name() == "yamoney:card" then
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", get_formspec(meta:get_string("mode"), 0, minetest.deserialize(meta:get_string("cfg")), meta:get_inventory() ))
		end
	end,
})
