improved_chests = {}

function improved_chests.take_items(from, to) --InvRef
	for i = 0, from:get_size("main"), 1 do
		current_stack = from:get_stack("main", i)
		left_stack = to:add_item("main", current_stack)
		from:set_stack("main", i, left_stack)
	end
end

function improved_chests.sort_inventory(inv, key_type) --InvRef, int
	function default_stack_name(stack)
		--sort with the default stack name (eg. default:stone < farming:cotton)
		return stack:get_name()
	end
	function modless_stack_name(stack)
		--sort with the stack name, regardless the mod name (eg. cotton < stone)
		return string.match( stack:get_name(), "%a*:([%a_]*)" ) or ""
	end
	methods_functions = {[1]=default_stack_name, [2]=modless_stack_name}

	local key = methods_functions[key_type] or methods_functions[1]

	--using insertion sort
	for i = 1, inv:get_size("main"), 1 do
		local j = i
		while j > 0 and key(inv:get_stack("main", j-1)) > key(inv:get_stack("main", j)) do
			--swap
			local st0 = inv:get_stack("main", j-1)
			local st1 = inv:get_stack("main", j  )
			inv:set_stack("main", j,   st0)
			inv:set_stack("main", j-1, st1)
			--!swap
			j = j - 1
		end
	end
end

function improved_chests.swap_inventories(from, to) --InvRef
	stacks_to_swap = math.min(from:get_size("main"), to:get_size("main"))
	for i = 0, stacks_to_swap, 1 do
		stack_a = from:get_stack("main", i)
		stack_b = to:get_stack("main", i)
		from:set_stack("main", i, stack_b)
		to:set_stack("main", i, stack_a)
	end
end

function improved_chests.get_chest_formspec()
	local formspec =
		"size[8,10]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
--chest inventory
		"list[current_name;main;0,0.3;8,4;]"..
--Sort button + key choice
		"image_button[0,4.6;1,1;chest_sort.png;sort;]"..
		"label[1,4.3;Method]"..
		"textlist[1,4.9;1.3,0.7;sort_key;default,modless;2;false]"..
--Chest name
		"field[3.3,5.1;3,1;chestname;Chest name;${infotext}]"..
--Take, put and swap buttons
		"image_button[6,4.6;1,0.5;chest_put.png;put;]"..
		"image_button[6,5.1;1,0.5;chest_take.png;take;]"..
		"image_button[7,4.6;1,1;chest_swap.png;swap;]"..
--player inventory
		"list[current_player;main;0,5.85;8,1;]"..
		"list[current_player;main;0,7.08;8,3;8]"..
		default.get_hotbar_bg(0,5.85)
	return formspec
end

function improved_chests.get_locked_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," ..pos.z
	local formspec =
		"size[8,10]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[nodemeta:".. spos .. ";main;0,0.3;8,4;]"..
		"image_button[0,4.6;1,1;chest_sort.png;sort;]"..
		"image_button[3,4.6;1,1;chest_put.png;put;]"..
		"image_button[4,4.6;1,1;chest_take.png;take;]"..
		"image_button[7,4.6;1,1;chest_swap.png;swap;]"..
		"list[current_player;main;0,5.85;8,1;]"..
		"list[current_player;main;0,7.08;8,3;8]"..
		default.get_hotbar_bg(0,5.85)
	return formspec
end

minetest.register_node("improved_chests:chest", {
	description = "Improved Chest",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", improved_chests.get_chest_formspec())
		meta:set_string("infotext", "Improved chest")
		meta:set_int("sort_key", 2) --@see improved_chests.sort_inventory()
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from chest at "..minetest.pos_to_string(pos))
	end,
	on_receive_fields = function(pos, formname, fields, sender)
for k,v in pairs(fields) do print(k,v) end

		if sender == nil then
			return
		end


		if fields["sort_key"] then
			local event = minetest.explode_textlist_event(fields["sort_key"])
			minetest.get_meta(pos):set_int("sort_key", event.index)
			--TODO: If event.index != 1 && != 2, may crash
			return
		end

		chest_inv  = minetest.get_meta(pos):get_inventory()
		player_inv = sender:get_inventory()

		if fields["put"] then
			improved_chests.take_items(player_inv, chest_inv)
			return
		end
		if fields["take"] then
			improved_chests.take_items(chest_inv, player_inv)
			return
		end
		if fields["sort"] then
			improved_chests.sort_inventory(chest_inv, minetest.get_meta(pos):get_int("sort_key"))
			return
		end
		if fields["swap"] then
			improved_chests.swap_inventories(chest_inv, player_inv)
			return
		end

		if fields["chestname"] then
			minetest.get_meta(pos):set_string("infotext", fields["chestname"])
			return
		end
	end
})

--[[
local function has_locked_chest_privilege(meta, player)
	return player:get_player_name() == meta:get_string("owner")
end

minetest.register_node("improved_chests:chest_locked", {
	description = "Improved Locked Chest",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_lock.png"},
	paramtype2 = "facedir",
	groups = {choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Improved Locked Chest (owned by "..
				meta:get_string("owner")..")")
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Improved Locked Chest")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main") and has_locked_chest_privilege(meta, player)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player) then
			return 0
		end
		return count
	end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player) then
			return 0
		end
		return stack:get_count()
	end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player) then
			return 0
		end
		return stack:get_count()
	end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to improved locked chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from improved locked chest at "..minetest.pos_to_string(pos))
	end,
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		if has_locked_chest_privilege(meta, clicker) then
			minetest.show_formspec(
				clicker:get_player_name(),
				"improved_chests:chest_locked",
				improved_chests.get_locked_chest_formspec(pos)
			)
		end
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if sender == nil then
			return
		end

		chest_inv  = minetest.get_meta(pos):get_inventory()
		player_inv = sender:get_inventory()

		if fields["put"] then
			improved_chests.take_items(player_inv, chest_inv)
			return
		end
		if fields["take"] then
			improved_chests.take_items(chest_inv, player_inv)
			return
		end
		if fields["sort"] then
			improved_chests.sort_inventory(chest_inv, minetest.get_meta(pos):get_int("sortmethod"))
			return
		end
		if fields["swap"] then
			improved_chests.swap_inventories(chest_inv, player_inv)
			return
		end
	end
})
]]
