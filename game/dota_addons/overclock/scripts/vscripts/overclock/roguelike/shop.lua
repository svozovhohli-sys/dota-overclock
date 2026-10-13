--[[
	OVERCLOCK :: roguelike/shop.lua
	Spend run gold between waves on gear and cleanup. Purchases are run-scoped.
--]]
local Log = require("overclock.core.logger")
local Events = require("overclock.core.events")
local Engine = require("overclock.modifiers.engine")

local M = {}

M.CATALOG = {
	{
		id = "buy_damage",
		name = "Клинок наёмника",
		desc = "+100 урона навсегда (забег).",
		cost = 25, repeatable = true,
		apply = function(run) Engine.apply_id(run.hero, run.hero, "stat_damage_100", nil) end,
	},
	{
		id = "buy_hp",
		name = "Камень здоровья",
		desc = "+1000 HP навсегда (забег).",
		cost = 25, repeatable = true,
		apply = function(run) Engine.apply_id(run.hero, run.hero, "stat_hp_1000", nil) end,
	},
	{
		id = "buy_armor",
		name = "Латы",
		desc = "+20 брони навсегда (забег).",
		cost = 20, repeatable = true,
		apply = function(run) Engine.apply_id(run.hero, run.hero, "stat_armor_20", nil) end,
	},
	{
		id = "buy_as",
		name = "Перчатки берсерка",
		desc = "+100 скорости атаки навсегда (забег).",
		cost = 30, repeatable = true,
		apply = function(run) Engine.apply_id(run.hero, run.hero, "stat_as_100", nil) end,
	},
	{
		id = "buy_ms",
		name = "Сапоги ветра",
		desc = "+100 скорости навсегда (забег).",
		cost = 20, repeatable = true,
		apply = function(run) Engine.apply_id(run.hero, run.hero, "stat_ms_100", nil) end,
	},
	{
		id = "cleanse",
		name = "Очищение",
		desc = "Снимает одну случайную хворь (1 стак).",
		cost = 40, repeatable = false,
		apply = function(run)
			-- remove the most stacked curse
			local worst, wid
			for id, e in pairs(run.curses) do
				if e.stacks > 0 and (not worst or e.stacks > worst) then
					worst, wid = e.stacks, id
				end
			end
			if wid then
				local Curse = require("overclock.roguelike.curses")
				local def
				for _, c in ipairs(Curse.CATALOG) do if c.id == wid then def = c end end
				if def and run.hero then
					Engine.remove(run.hero, def.modifier)
					run.curses[wid].stacks = run.curses[wid].stacks - 1
					if run.curses[wid].stacks <= 0 then run.curses[wid] = nil end
					-- re-apply remaining stacks
					for _ = 1, (run.curses[wid] and run.curses[wid].stacks or 0) do
						Engine.apply_id(run.hero, run.hero, def.modifier, nil)
					end
				end
			end
		end,
	},
}

function M.list(run)
	local out = {}
	for _, item in ipairs(M.CATALOG) do
		out[#out + 1] = {
			id = item.id,
			name = item.name,
			desc = item.desc,
			cost = item.cost,
			affordable = (run.gold or 0) >= item.cost,
		}
	end
	return out
end

function M.buy(run, item_id)
	for _, item in ipairs(M.CATALOG) do
		if item.id == item_id then
			if (run.gold or 0) < item.cost then
				return false, "no_gold"
			end
			run.gold = run.gold - item.cost
			local ok, err = pcall(item.apply, run)
			if not ok then
				run.gold = run.gold + item.cost
				Log.error("purchase '%s' failed: %s", item_id, tostring(err))
				return false, "apply_failed"
			end
			Events.emit("roguelike:purchased", { run = run, item = item })
			return true
		end
	end
	return false, "unknown_item"
end

function M.open(run)
	run.status = "shop"
	Events.emit("roguelike:shop_opened", { run = run })
end

function M.close(run)
	if run.status == "shop" then
		run.status = "prep"
	end
	Events.emit("roguelike:shop_closed", { run = run })
end

return M
