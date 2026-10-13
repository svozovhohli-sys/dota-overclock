--[[
	OVERCLOCK :: roguelike/curses.lua
	Curses are the "tax" of a run: each wave the player must accept one, and it
	is applied permanently (for the run) to their hero via the modifier engine.

	A curse maps onto a modifier id from data/modifiers.lua plus a max stack and
	a tier gating when it can appear (deeper waves unlock harsher tiers).
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")
local Events = require("overclock.core.events")
local Engine = require("overclock.modifiers.engine")

local M = {}

M.CATALOG = {
	{
		id = "frailty",
		name = "Хрупкость",
		desc = "−5 брони за стак",
		modifier = "curse_armor_5",
		tier = 1, weight = 20, max_stacks = 6, gold = 4,
	},
	{
		id = "leak",
		name = "Утечка маны",
		desc = "−20 маны/с за стак",
		modifier = "curse_mana_20",
		tier = 1, weight = 18, max_stacks = 5, gold = 4,
	},
	{
		id = "tar",
		name = "Смола",
		desc = "−50% скорости за стак (5с)",
		modifier = "slow_50",
		tier = 2, weight = 14, max_stacks = 3, gold = 6,
	},
	{
		id = "venom",
		name = "Змеиный яд",
		desc = "20 маг. урона/с за стак (6с)",
		modifier = "dot_magic_20",
		tier = 2, weight = 14, max_stacks = 4, gold = 6,
	},
	{
		id = "purge",
		name = "Порча",
		desc = "10 чистого урона/с за стак (6с)",
		modifier = "dot_pure_10",
		tier = 3, weight = 8, max_stacks = 3, gold = 9,
	},
}

-- Tier available at a given wave depth.
function M.tier_for_depth(depth)
	if depth <= 2 then return 1 end
	if depth <= 5 then return 2 end
	return 3
end

local function stacks_of(run, id)
	local c = run.curses[id]
	return c and c.stacks or 0
end

function M.available(run)
	local tier = M.tier_for_depth(run.depth or 0)
	local out = {}
	for _, c in ipairs(M.CATALOG) do
		if c.tier <= tier and stacks_of(run, c.id) < c.max_stacks then
			out[#out + 1] = c
		end
	end
	return out
end

function M.roll(run, n)
	n = n or 3
	local pool = M.available(run)
	local picks = {}
	local used = {}
	while #picks < n and #pool > 0 do
		local choice = Util.pick_weighted(Util.filter(pool, function(c)
			return not used[c.id]
		end))
		if not choice then break end
		used[choice.id] = true
		picks[#picks + 1] = choice
	end
	return picks
end

-- Apply a curse to the run's hero (and register the stack).
function M.apply(run, curse_id)
	local def
	for _, c in ipairs(M.CATALOG) do
		if c.id == curse_id then def = c; break end
	end
	if not def then
		Log.warn("unknown curse: %s", tostring(curse_id))
		return false
	end
	local hero = run.hero
	if not hero or not IsValidEntity(hero) then return false end

	Engine.apply_id(hero, hero, def.modifier, nil)

	local entry = run.curses[def.id]
	if not entry then
		entry = { id = def.id, name = def.name, stacks = 0 }
		run.curses[def.id] = entry
	end
	entry.stacks = entry.stacks + 1

	if def.gold then
		run.gold = run.gold + def.gold
	end
	Events.emit("roguelike:curse_applied", { run = run, curse = def, stacks = entry.stacks })
	Log.info("curse '%s' x%d on %s", def.id, entry.stacks, hero:GetUnitName())
	return true
end

function M.list(run)
	local out = {}
	for _, entry in pairs(run.curses or {}) do
		table.insert(out, entry)
	end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

return M
