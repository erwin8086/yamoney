-- A Machine for changing money

local formspec = "size[8,9]"..
	"list[context;pay;0,1;1,1;]"..
	"list[current_player;main;0,5;8,4;]"..
	"label[0,0;PayIn]"..
	"item_image_button[0,2;1,1;yamoney:1;1;]"..
	"item_image_button[1,2;1,1;yamoney:2;2;]"..
	"item_image_button[2,2;1,1;yamoney:5;5;]"..
	"item_image_button[3,2;1,1;yamoney:10;10;]"..
	"item_image_button[4,2;1,1;yamoney:20;20;]"..
	"item_image_button[5,2;1,1;yamoney:50;50;]"..
	"item_image_button[6,2;1,1;yamoney:100;100;]"..
	"item_image_button[7,2;1,1;yamoney:200;200;]"..
	"item_image_button[0,3;1,1;yamoney:500;500;]"..
	"item_image_button[1,3;1,1;yamoney:1000;1000;]"..
	"item_image_button[2,3;1,1;yamoney:2000;2000;]"..
	"item_image_button[3,3;1,1;yamoney:5000;5000;]"..
	"item_image_button[4,3;1,1;yamoney:10000;10000;]"..
	"item_image_button[5,3;1,1;yamoney:20000;20000;]"..
	"item_image_button[6,3;1,1;yamoney:50000;50000;]"
minetest.register_node("yamoney:changing", {
	tiles = {"default_wood.png^yamoney_1c.png", "default_wood.png^yamoney_1e.png", "default_wood.png^yamoney_10e.png",
			"default_wood.png^yamoney_50e.png", "default_wood.png^yamoney_100e.png", "default_wood.png^yamoney_200e.png"},
	groups = {choppy=3, oddly_breakable_by_hand=1},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("money", 0)
		local inv = meta:get_inventory()
		inv:set_size("pay", 1)
		
		meta:set_string("formspec", formspec..
			"label[1,0;Money:0.00]")
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return 0
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if stack:get_definition().money then
			return stack:get_count()
		else
			return 0
		end
	end,
	
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local money = stack:get_count() * stack:get_definition().money + meta:get_int("money")/100
		meta:set_int("money", money*100)
		meta:set_string("formspec", formspec..
			"label[1,0;Money:"..money.."]")
		meta:get_inventory():set_stack("pay", 1, nil)
	end,
	
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		local money = meta:get_int("money")
		-- If ESC payout the money
		if fields.quit then
			yamoney.payout(money/100, sender)
			meta:set_int("money", 0)
			meta:set_string("formspec", formspec..
				"label[1,0;Money:"..(money/100).."]")
			return
		end
		for m in pairs(fields) do
			m = tonumber(m)
			if m and money >= m then
				local stack = ItemStack("yamoney:"..m)
				local inv = sender:get_inventory()
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					money = money - m
				end
			end
		end
		meta:set_string("formspec", formspec..
			"label[1,0;Money:"..(money/100).."]")
		meta:set_int("money", money)
	end,
})