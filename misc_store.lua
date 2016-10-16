local def = {}
if minetest.get_modpath("asphalt") then
	def[#def+1] = {"streets:asphalt 99", 1}
end

if minetest.get_modpath("plasticbox") then
	def[#def+1] = {"plasticbox:plasticbox 16", 0.95}
end

if minetest.get_modpath("protector") then
	def[#def+1] = {"protector:protect", 0.60}
	def[#def+1] = {"protector:protect2", 0.85}
	def[#def+1] = {"protector:door_wood", 0.75}
end

if minetest.get_modpath("unified_inventory") then
	def[#def+1] = {"unified_inventory:bag_small", 1.25}
	def[#def+1] = {"unified_inventory:bag_medium", 2.60}
	def[#def+1] = {"unified_inventory:bag_large", 5.30}
end

if minetest.get_modpath("vessels") then
	def[#def+1] = {"vessels:drinking_glass 7", 0.35}
	def[#def+1] = {"vessels:glass_bottle 4", 0.10}
end

if minetest.get_modpath("moreblocks") then
	def[#def+1] = {"moreblocks:cactus_brick 12", 0.55}
	def[#def+1] = {"moreblocks:iron_stone 8", 2.50}
	def[#def+1] = {"moreblocks:cactus_checker 8", 0.35}
	def[#def+1] = {"moreblocks:clean_glass 2", 0.19}
end

if minetest.get_modpath("flowers") then
	def[#def+1] = {"flowers:dandelion_white 2", 2.19}
	def[#def+1] = {"flowers:dandelion_yellow 2", 2.19}
	def[#def+1] = {"flowers:geranium 2", 2.19}
	def[#def+1] = {"flowers:rose 2", 2.19}
	def[#def+1] = {"flowers:sunflower 2", 2.25}
	def[#def+1] = {"flowers:tulip 2", 2.19}
	def[#def+1] = {"flowers:viola 2", 2.19}
	def[#def+1] = {"flowers:dandelion_white 2", 2.19}
end

yamoney.register_store("misc", "default_stone_brick.png^yamoney_50c.png", "Misc Store", def)
