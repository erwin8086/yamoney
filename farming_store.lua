local def = {
	{"farming:seed_cotton 8", 1.20},
	{"farming:seed_wheat 8", 0.99},
	{"farming:pumpkin_seed 4", 0.97},
	{"farming:hoe_stone", 0.90},
	{"farming:hoe_bronze", 4.49},
	{"farming:hoe_mese", 85.99},
	{"farming:bread 2", 1.50},
	{"farming:string 4", 2},
}

if minetest.get_modpath("farming_plus") then
	def[#def+1] = {"farming_plus:carrot_seed 8", 1.59}
	def[#def+1] = {"farming_plus:orange_seed 8", 1.75}
	def[#def+1] = {"farming_plus:potato_seed 8", 1.69}
	def[#def+1] = {"farming_plus:rhubarb_seed 8", 1.39}
	def[#def+1] = {"farming_plus:strawberry_seed 8", 1.74}
	def[#def+1] = {"farming_plus:tomato_seed 8", 1.55}
end

if minetest.get_modpath("bushes") then
	def[#def+1] = {"bushes:blackberry 4", 0.89}
	def[#def+1] = {"bushes:blueberry 4", 0.89}
	def[#def+1] = {"bushes:gooseberry 4", 0.89}
	def[#def+1] = {"bushes:raspberry 4", 0.89}
	def[#def+1] = {"bushes:blackberry 4", 0.89}
end

yamoney.register_store("farming", "farming_straw.png^yamoney_5e.png", "Farming Store", def)