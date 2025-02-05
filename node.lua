
local has_default = minetest.get_modpath("default")
local has_pipeworks = minetest.get_modpath("pipeworks")
local has_vizlib = minetest.get_modpath("vizlib")

local formspec = "size[8,9.2;]" ..
	"list[context;main;0,0;8,4;]" ..
	"field[1.3,4.6;4.25,1;channel;Digiline Channel;${channel}]" ..
	"button_exit[5,4.28;2,1;set_channel;Set]" ..
	"list[current_player;main;0,5.4;8,4;]" ..
	"listring[]"

minetest.register_node("digibuilder:digibuilder", {
	description = "Digibuilder",

	tiles = {"digibuilder.png"},

	tube = {
		insert_object = function(pos, _, stack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, _, stack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			stack = stack:peek_item(1)

			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = {
			left = 1, back = 1, top = 1,
			right = 1, front = 1, bottom = 1
		}
	},

	light_source = 13,
	groups = {
		cracky = 3,
		oddly_breakable_by_hand = 3,
		tubedevice = 1,
		tubedevice_receiver = 1
	},

	sounds = has_default and default.node_sound_glass_defaults(),

	digiline = {
		receptor = {
			rules = digibuilder.digiline_rules,
			action = function() end
		},
		effector = {
			rules = digibuilder.digiline_rules,
			action = digibuilder.digiline_effector
		}
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)

		-- set owner
		local owner = placer:get_player_name() or ""
		meta:set_string("owner", owner)

		if has_pipeworks then
			pipeworks.after_place(pos)
		end
	end,

	on_construct = function(pos)
		-- inventory
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)

		-- metadata
		meta:set_string("formspec", formspec)
		meta:set_string("channel", "digibuilder")
		meta:set_string("infotext", "Digibuilder")
	end,

	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local name = player:get_player_name()

		return inv:is_empty("main") and not minetest.is_protected(pos, name)
	end,

	after_dig_node = has_pipeworks and pipeworks.after_dig or nil,

	on_receive_fields = function(pos, _, fields, sender)
		if not sender or minetest.is_protected(pos, sender:get_player_name()) then
			return
		end

		if fields.set_channel then
			local meta = minetest.get_meta(pos)
			meta:set_string("channel", fields.channel)
		end

		if fields.digiline_channel then
			-- Update old formspec
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", formspec)
		end
	end,

	-- inventory protection
	allow_metadata_inventory_take = function(pos, _, _, stack, player)
		if player and player:is_player() and minetest.is_protected(pos, player:get_player_name()) then
			-- protected
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_put = function(pos, _, _, stack, player)
		if player and player:is_player() and minetest.is_protected(pos, player:get_player_name()) then
			-- protected
			return 0
		end

		return stack:get_count()
	end,

	on_punch = has_vizlib and function(pos, _, player)
		if not player or player:get_wielded_item():get_name() ~= "" then
			-- Only show area when using an empty hand
			return
		end
		vizlib.draw_cube(pos, digibuilder.max_radius + 0.5, {player = player})
	end or nil,
})
