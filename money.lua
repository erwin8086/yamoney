-- The money items itself

local money = {
	[0.01] = "yamoney_1c.png",
	[0.02] = "yamoney_2c.png",
	[0.05] = "yamoney_5c.png",
	[0.1] = "yamoney_10c.png",
	[0.2] = "yamoney_20c.png",
	[0.5] = "yamoney_50c.png",
	[1] = "yamoney_1e.png",
	[2] = "yamoney_2e.png",
	[5] = "yamoney_5e.png",
	[10] = "yamoney_10e.png",
	[20] = "yamoney_20e.png",
	[50] = "yamoney_50e.png",
	[100] = "yamoney_100e.png",
	[200] = "yamoney_200e.png",
	[500] = "yamoney_500e.png",
}

local function register_money(value, image)
	local def = {
		description = value.."Euro",
		inventory_image=image,
		money = value,
		groups = {money=1},
	}
	minetest.register_craftitem("yamoney:"..(value*100), def)
end

for v, i in pairs(money) do
	register_money(v,i)
end