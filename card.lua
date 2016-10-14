--[[
	The Bankcard
	a card with transaction history
]]
local function show_form(stack, player)
	local data = minetest.deserialize(stack:get_metadata())
	if not data then
		data = {}
		data.money = 0
		data.transactions = {}
	end
	
	local f = "size[8,9]"..
		"label[0,0;Money: "..data.money.."]"..
		"textlist[0,1;8,8;transactions;"
	
	-- Show the last 30 transations
	for _, t in ipairs(data.transactions) do
		f=f..t..","
	end
	
	f=f.."]"
	
	minetest.show_formspec(player:get_player_name(), "yamoney:card", f)
	
	stack:set_metadata(minetest.serialize(data))
	return stack
end

-- The meta table for cards
local card = {
	save = function(self, stack)
		stack:set_metadata(minetest.serialize(self.data))
		return stack
	end,
	
	-- Add a transaction to the list do not change any money
	add_transaction = function(self, text)
		local i = #self.data.transactions
		
		while i > 0 do
			if i < 30 then
				self.data.transactions[i+1] = self.data.transactions[i]
			end
			i=i-1
		end
		
		self.data.transactions[1] = text
	end,
	
	-- Add money to card and create transaction for that
	add_money = function(self, amount, text)
		text = text..": "..amount
		self.data.money = self.data.money + amount
		
		self:add_transaction(text)
		
		return true
	end,
	
	-- Remove money from card and add transaction returns false if not enough money else true
	rm_money = function(self, amount, text)
		text = text..": -"..amount
		if self.data.money >= amount then
			self.data.money = self.data.money - amount
			self:add_transaction(text)
			return true
		end
		return false
	end,
	
	-- Get the money on card
	get_count = function(self)
		return self.data.money
	end,
	
}

-- Get a card object for that stack, nil if this stack is not a card
function yamoney.get_card(stack)
	if not stack or stack:is_empty() or stack:get_name() ~= "yamoney:card" then return nil end
	local t = {
		["data"] = minetest.deserialize(stack:get_metadata())
	}
	if not t.data then
		t.data = {}
		t.data.money = 0
		t.data.transactions = {}
	end
	setmetatable(t, {["__index"]=card})
	
	return t
end

-- The card
minetest.register_craftitem("yamoney:card", {
	description = "Bank Card",
	inventory_image = "yamoney_card.png",
	stack_max = 1,
	on_place = show_form,
	on_secondary_use = show_form,
})

local bankomat_form = "size[8,9]"..
	"list[current_player;main;0,5;8,4;]"..
	"list[context;card;7,4;1,1;]"..
	"list[context;pay;4,4;1,1;]"..
	"label[3,4;PayIn:]"

-- Add buttons for the money items in the bankomat_form
local x = 0
local y = 0
for _, c in ipairs(yamoney.counts) do
	bankomat_form=bankomat_form.."item_image_button["..x..","..y..";1,1;yamoney:"..(c*100)..";"..(c*100)..";]"
	x=x+1
	if x>7 then
		y=y+1
		x=0
	end
end

-- A bankomat for tranfer cash to/from cards
minetest.register_node("yamoney:bankomat", {
	tiles = {"yamoney_bankomat_top.png", "yamoney_bankomat_top.png", "yamoney_bankomat.png", "yamoney_bankomat.png", "yamoney_bankomat.png", "yamoney_bankomat.png" },
	description = "Bankomat",
	groups = {choppy=3, oddly_breakable_by_hand=1},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		
		inv:set_size("pay", 1)
		inv:set_size("card", 1)
		
		meta:set_string("formspec", bankomat_form.."label[5,4;Card: 0]")
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	-- Only cards and cash
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not stack or stack:is_empty() then return 0 end
		
		if listname == "card" then
			if stack:get_name() == "yamoney:card" then
				return 1
			end
		elseif listname == "pay" then
			local inv = minetest.get_meta(pos):get_inventory()
			if stack:get_definition().money and inv:contains_item("card", "yamoney:card") then
				return stack:get_count()
			end
		end
		return 0
	end,
	
	-- Only take cards
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if not stack or stack:is_empty() then return 0 end
		
		if listname == "card" then return stack:get_count() end
		return 0
	end,
	
	-- Process cards and cash
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if listname == "card" then
			local c = yamoney.get_card(stack)
			if c then
				meta:set_string("formspec", bankomat_form.."label[5,4;Card: "..c:get_count().."]")
			end
		-- Add money to card
		elseif listname == "pay" then
			local inv = meta:get_inventory()
			local card = inv:get_stack("card", 1)
			local c = yamoney.get_card(card)
			if c then
				c:add_money(stack:get_definition().money * stack:get_count(), "Transfer Money on Bankomat")
				meta:set_string("formspec", bankomat_form.."label[5,4;Card: "..c:get_count().."]")
				inv:set_stack("card", 1, c:save(card))
				inv:set_stack("pay", 1, nil)
			end
		end
	end,
	
	-- Take the card
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "card" then
			local meta = minetest.get_meta(pos)
			
			meta:set_string("formspec", bankomat_form.."label[5,4;Card: 0]")
		end
	end,
	
	-- Payout money from card
	on_receive_fields = function(pos, formname, fields, sender)
		if fields.quit then return end
		local pinv = sender:get_inventory()
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local card = inv:get_stack("card", 1)
		local c = yamoney.get_card(card)
		if not c then return end
		
		-- Process cash to pay out
		for m, _ in pairs(fields) do
			m = tonumber(m)/100 or 0
			local stack = ItemStack("yamoney:"..(m*100))
			if pinv:room_for_item("main", stack) and c:rm_money(m, "Transfer Money on Bankomat") then
				pinv:add_item("main", stack)
			end
		end
		meta:set_string("formspec", bankomat_form.."label[5,4;Card: "..c:get_count().."]")
		card = c:save(card)
		inv:set_stack("card", 1, card)
	end,
	
	
	
})


--[[
	a command for manage cards
	/yacard get -- Get money on card
	/yacard add <money> -- Add money to card
	/yacard rm <money> -- Remove money from card
]]
minetest.register_chatcommand("yacard", {
	params = "yacard <conmmand> [parameter]",
	description = "Works with Band Cards",
	privs = {["give"]=true},
	func = function(name, param)
		local command, amount = param:match("(%a+)%s(%d+)")
		if not command then command = param end

		local player = minetest.get_player_by_name(name)
		if not player then return end
		
		if command == "add" then
			local stack = player:get_wielded_item()
			local c = yamoney.get_card(stack)
			if not c then return false, "Cold not get Card" end
			c:add_money(tonumber(amount) or 0, "Admin has Added Money")
			player:set_wielded_item(c:save(stack))
			return true, "Added "..(tonumber(amount) or 0).."Euro"
		elseif command == "rm" then
			local stack = player:get_wielded_item()
			local c = yamoney.get_card(stack)
			if not c then return false, "Cold not get Card" end
			if not c:rm_money(tonumber(amount) or 0, "Admin has Removed Money") then
				return false, "Not enough Money on this Card"
			end
			player:set_wielded_item(c:save(stack))
			return true, "Removed "..(tonumber(amount) or 0).."Euro"
		elseif command == "get" then
			local stack = player:get_wielded_item()
			local c = yamoney.get_card(stack)
			if not c then return false, "Cold not get Card" end
			return true, c:get_count().."Euro on this Card"
		end
		
	end,
})