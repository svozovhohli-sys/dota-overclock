--[[
	OVERCLOCK :: patch/patch_sets.lua
	Named "balance patches". Because a custom game cannot rewrite the base
	ability files at runtime, a patch here is a runtime bundle of modifier
	applications that emulate the intent of a balance change (and, for the
	static part, ships alongside npc_abilities_override.txt).

	Patch set schema:
		{
			id = "hardcore",
			name = "Хардкор",
			author = "OVERCLOCK",
			desc = "−20% HP всем, −5 брони",
			rules = {
				{ modifier = "curse_armor_5", target = "all_heroes" },
				{ hp_mult = 0.8, target = "all_heroes" },
			},
		}
--]]
return {
	{
		id = "vanilla",
		name = "Ванилла (без правок)",
		author = "OVERCLOCK",
		desc = "Контрольный набор — ничего не меняем.",
		rules = {},
	},
	{
		id = "hardcore",
		name = "Хардкор",
		author = "OVERCLOCK",
		desc = "−20% HP и −5 брони всем героям.",
		rules = {
			{ hp_mult = 0.8, target = "all_heroes" },
			{ modifier = "curse_armor_5", target = "all_heroes" },
		},
	},
	{
		id = "glass_cannon",
		name = "Стеклянная пушка",
		author = "OVERCLOCK",
		desc = "+100 урона и −40% HP всем героям.",
		rules = {
			{ modifier = "stat_damage_100", target = "all_heroes" },
			{ hp_mult = 0.6, target = "all_heroes" },
		},
	},
	{
		id = "tank_meta",
		name = "Танк-мета",
		author = "OVERCLOCK",
		desc = "+1000 HP и +20 брони всем героям.",
		rules = {
			{ modifier = "stat_hp_1000", target = "all_heroes" },
			{ modifier = "stat_armor_20", target = "all_heroes" },
		},
	},
	{
		id = "no_sustain",
		name = "Без сустейна",
		author = "OVERCLOCK",
		desc = "Все герои теряют 20 маны в секунду.",
		rules = {
			{ modifier = "curse_mana_20", target = "all_heroes" },
		},
	},
	{
		id = "hyper",
		name = "Гипер",
		author = "OVERCLOCK",
		desc = "+100 скорости атаки и +100 движения всем.",
		rules = {
			{ modifier = "stat_as_100", target = "all_heroes" },
			{ modifier = "stat_ms_100", target = "all_heroes" },
		},
	},
}
