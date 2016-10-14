local form = "size[8,9]"..
	"list[current_player;main;0,5;8,4;]"..
	"list[context;pay;7,4;1,1;]"
	
local function chown(area, owner)
	areas.areas[area].owner = owner:get_player_name()
	areas:save()
end

minetest.register_node("yamoney:area", {
	description = "Sell areas",
	tiles = {"yamoney_area.png"},
	groups = {oddly_breakable_by_hand=1},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("pay", 1)
		
		meta:set_string("formspec", "field[area;Area:;0]")
		meta:set_int("money", 0)
		meta:set_int("price", 0)
		meta:set_int("area", 0)
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if meta:get_int("price") == 0 then return end
		if stack and not stack:is_empty() and (stack:get_definition().money or stack:get_name() == "yamoney:card") then
			return stack:get_count()
		end
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if stack and stack:get_name() == "yamoney:card" then
			return stack:get_count()
		end
		return 0
	end,
	
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local card = yamoney.get_card(stack)
		local meta = minetest.get_meta(pos)
		local price = meta:get_int("price")/100
		local area = meta:get_int("area")
		if card then
			meta:set_string("formspec", form.."label[5,4;PayIn: "..card:get_count().."]".."label[1,1;Price: "..(meta:get_int("price")/100 or 25.50).."]")
			if card:rm_money(price, "Buy'd area") and area > 0 then
				chown(area, player)
				local pinv = player:get_inventory()
				if pinv:room_for_item("main", stack) then
					pinv:add_item("main", stack)
				else
					minetest.item_drop(stack, player, player:get_player_name())
				end
				minetest.remove_node(pos)
			end
		else
			local money = meta:get_int("money")/100
			money = money + stack:get_definition().money * stack:get_count()
			if money >= price and area > 0 then
				money = money - price
				chown(area, player)
				yamoney.payout(money, player)
				minetest.remove_node(pos)
			end
			
			meta:set_int("money", money*100)
			meta:set_string("formspec", form.."label[5,4;PayIn: "..price.."]".."label[1,1;Price: "..(meta:get_int("price")/100 or 25.50).."]")
		end
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		if fields.price then
			if minetest.get_player_privs(sender:get_player_name()).areas then
				local meta = minetest.get_meta(pos)
				meta:set_int("price", tonumber(fields.price)*100 or 2550)
				meta:set_string("formspec", form.."label[5,4;PayIn: 0]".."label[1,1;Price: "..(tonumber(fields.price) or 25.50).."]")
				meta:set_string("infotext", "Punch to show area, LMB to Buy")
			else
				minetest.chat_send_player(sender:get_player_name(), "You have not the areas privilege!")
			end
		elseif fields.area then
			local meta = minetest.get_meta(pos)
			if fields.area == "0" then return end
			meta:set_string("formspec", "field[price;Price:;25.50]")
			meta:set_int("area", tonumber(fields.area) or 0)
		end
	end,
	
	can_dig = function(pos, player)
		if minetest.get_player_privs(player:get_player_name()).give then
			return true
		else
			return false
		end
	end,
	
	on_punch = function(pos, node, player, pointed_thing)
		local meta = minetest.get_meta(pos)
		local area = meta:get_int("area")
		local name = player:get_player_name()
		if area > 0 then
			areas:setPos1(name, areas.areas[area].pos1)
			areas:setPos2(name, areas.areas[area].pos2)
		end
	end,
	
	
	
	
})