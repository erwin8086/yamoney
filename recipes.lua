local ic
if minetest.get_modpath("technic") then
	ic = "technic:control_logic_unit"
elseif minetest.get_modpath("homedecor") then
	ic = "homedecor:ic"
else
	minetest.register_craftitem("yamoney:ic", {
		description = "Integrated Circuit",
		inventory_image = "yamoney_ic.png",
	})
	
	minetest.register_craft({
		output = "yamoney:ic 2",
		
		recipe = {
			{"default:copper_ingot", "default:copper_ingot", "default:copper_ingot"},
			{"default:paper", "default:steel_ingot", "default:paper"},
			{"default:copper_ingot", "default:copper_ingot", "default:copper_ingot"},
		}
	})
	ic = "yamoney:ic"
end

minetest.register_craft({
	output = "yamoney:changing",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:stone", ic, "group:stone"},
		{"group:wood", "default:mese_crystal_fragment", "group:wood"}
	}
})

minetest.register_craft({
	output = "yamoney:bankomat",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", ic, "default:steel_ingot"},
		{"default:steel_ingot", "yamoney:changing", "default:steel_ingot"}
	}
})

minetest.register_craftitem("yamoney:bankomat_function",{
	description = "Bankomat function",
	inventory_image = "yamoney_bankomat.png",
})

minetest.register_craft({
	output = "yamoney:bankomat_function 8",
	recipe = {{"yamoney:bankomat"}}
})

minetest.register_craft({
	output = "yamoney:wallet",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "", ""},
		{"default:paper", "default:paper", "default:paper"}
	}
})

minetest.register_craft({
	output = "yamoney:card",
	recipe = {
		{"default:paper", "default:paper", "default:gold_ingot"},
		{"default:paper", "default:paper", ic}
	}
})

minetest.register_craft({
	output = "yamoney:store",
	recipe = {
		{"default:stone", "yamoney:bankomat_function", "default:stone"},
		{"default:stone", ic, "default:stone"},
		{"default:stone", "yamoney:changing", "default:stone"}
	}
})

minetest.register_craft({
	output = "yamoney:default",
	recipe = {{"yamoney:store"}}
})

minetest.register_craft({
	output = "yamoney:misc",
	recipe = {{"yamoney:default"}}
})

local last = "yamoney:default"

if minetest.get_modpath("farming") then
	minetest.register_craft({
		output = "yamoney:farming",
		recipe = {{last}}
	})
	last = "yamoney:farming"
end

if minetest.get_modpath("technic") or minetest.get_modpath("mesecons") then
	minetest.register_craft({
		output = "yamoney:technic",
		recipe = {{last}}
	})
	last = "yamoney:technic"
end

if minetest.get_modpath("homedecor") then
	minetest.register_craft({
		output = "yamoney:homedecor",
		recipe = {{last}}
	})
	last = "yamoney:homedecor"
end