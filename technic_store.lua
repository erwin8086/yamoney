local def
if minetest.get_modpath("technic") then
	def = {
		{"technic:lv_generator", 30},
		{"technic:lv_cable 6", 6.90},
		{"technic:switching_station", 55},
		{"technic:lv_electric_furnace", 19.99},
		{"technic:lv_grinder", 64.99},
		{"technic:lv_battery_box0", 24.99},
		{"technic:uranium_fuel", 1000},
		{"technic:water_can", 8},
		{"technic:lava_can", 16},
	}
else
	def = {}
end

if minetest.get_modpath("mesecons") then
	def[#def+1] = {"mesecons:wire_00000000_off 8", 19.99}
	def[#def+1] = {"mesecons_pistons:piston_normal_off 1", 1.25}
	def[#def+1] = {"mesecons_walllever:wall_lever_off", 2.99}
	def[#def+1] = {"mesecons_lightstone:lightstone_blue_off", 2.99}
	def[#def+1] = {"mesecons_lamp:lamp_off", 3.99}
end

if minetest.get_modpath("digilines") then
	def[#def+1] = {"digilines:wire_std_00000000 4", 45}
	def[#def+1] = {"digilines:lcd 2", 7.99}
	def[#def+1] = {"digilines:lightsensor 2", 100}
	def[#def+1] = {"digilines:rtc 2", 100}
	def[#def+1] = {"digilines:chest", 21.99}
end

yamoney.register_store("technic", "default_steel_block.png^yamoney_500e.png", "Technic Store", def)