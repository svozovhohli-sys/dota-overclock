--[[
	OVERCLOCK :: data/modifiers.lua
	Catalog of applyable modifiers. Loaded by modifiers/registry.lua.

	This is DATA: add new entries here (and a matching `lua_modifiers` file for
	new classes) without touching the engine. The roguelike "curses", the patch
	lab and the sandbox modifier console all read from this table.
--]]
local LUA_MODIFIER_MOTION_NONE = LUA_MODIFIER_MOTION_NONE or 0

return {
	-- buffs ------------------------------------------------------------------
	{
		id = "buff_attack_50",
		modifier = "modifier_oc_buff_attack",
		file = "overclock/lua_modifiers/modifier_oc_buff_attack",
		label = "Атака +50 скорострельности",
		category = "buff",
		duration = 8.0,
		stacks = "refresh",
		kv = { as = 50, damage = 20 },
	},
	{
		id = "buff_shield_200",
		modifier = "modifier_oc_buff_shield",
		file = "overclock/lua_modifiers/modifier_oc_buff_shield",
		label = "Щит 200 + 10% магрезист",
		category = "buff",
		duration = 10.0,
		stacks = "refresh",
		kv = { absorb = 200, resist = 10 },
	},
	-- debuffs ----------------------------------------------------------------
	{
		id = "slow_25",
		modifier = "modifier_oc_slow",
		file = "overclock/lua_modifiers/modifier_oc_slow",
		label = "Замедление 25%",
		category = "debuff",
		duration = 5.0,
		stacks = "independent",
		kv = { slow = 25 },
	},
	{
		id = "slow_50",
		modifier = "modifier_oc_slow",
		file = "overclock/lua_modifiers/modifier_oc_slow",
		label = "Замедление 50%",
		category = "debuff",
		duration = 5.0,
		stacks = "independent",
		kv = { slow = 50 },
	},
	{
		id = "dot_magic_20",
		modifier = "modifier_oc_dot",
		file = "overclock/lua_modifiers/modifier_oc_dot",
		label = "Маг. урон 20/с",
		category = "debuff",
		duration = 6.0,
		stacks = "independent",
		kv = { dps = 20, type = "magic", interval = 1.0 },
	},
	{
		id = "dot_pure_10",
		modifier = "modifier_oc_dot",
		file = "overclock/lua_modifiers/modifier_oc_dot",
		label = "Чистый урон 10/с",
		category = "debuff",
		duration = 6.0,
		stacks = "independent",
		kv = { dps = 10, type = "pure", interval = 1.0 },
	},
	-- curses (roguelike) -----------------------------------------------------
	{
		id = "curse_armor_5",
		modifier = "modifier_oc_curse_armor",
		file = "overclock/lua_modifiers/modifier_oc_curse_armor",
		label = "Проклятие: −5 брони",
		category = "curse",
		duration = nil,
		stacks = "stack",
		kv = { armor = 5 },
	},
	{
		id = "curse_mana_20",
		modifier = "modifier_oc_curse_mana_drain",
		file = "overclock/lua_modifiers/modifier_oc_curse_mana_drain",
		label = "Проклятие: −20 маны/с",
		category = "curse",
		duration = nil,
		stacks = "stack",
		kv = { burn = 20 },
	},
	-- stat bonuses (sandbox console) -----------------------------------------
	{
		id = "stat_damage_100",
		modifier = "modifier_oc_stat_bonus",
		file = "overclock/lua_modifiers/modifier_oc_stat_bonus",
		label = "+100 урона",
		category = "stat",
		duration = nil,
		stacks = "stack",
		kv = { stat = "damage", value = 100 },
	},
	{
		id = "stat_hp_1000",
		modifier = "modifier_oc_stat_bonus",
		file = "overclock/lua_modifiers/modifier_oc_stat_bonus",
		label = "+1000 HP",
		category = "stat",
		duration = nil,
		stacks = "stack",
		kv = { stat = "hp", value = 1000 },
	},
	{
		id = "stat_as_100",
		modifier = "modifier_oc_stat_bonus",
		file = "overclock/lua_modifiers/modifier_oc_stat_bonus",
		label = "+100 скорости атаки",
		category = "stat",
		duration = nil,
		stacks = "stack",
		kv = { stat = "attack_speed", value = 100 },
	},
	{
		id = "stat_armor_20",
		modifier = "modifier_oc_stat_bonus",
		file = "overclock/lua_modifiers/modifier_oc_stat_bonus",
		label = "+20 брони",
		category = "stat",
		duration = nil,
		stacks = "stack",
		kv = { stat = "armor", value = 20 },
	},
	{
		id = "stat_ms_100",
		modifier = "modifier_oc_stat_bonus",
		file = "overclock/lua_modifiers/modifier_oc_stat_bonus",
		label = "+100 скорости",
		category = "stat",
		duration = nil,
		stacks = "stack",
		kv = { stat = "move_speed", value = 100 },
	},
}
