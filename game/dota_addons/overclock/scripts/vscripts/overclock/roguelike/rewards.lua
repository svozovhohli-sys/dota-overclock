--[[
	OVERCLOCK :: roguelike/rewards.lua
	Post-wave rewards: gold, heals, or permanent-ish stat buffs bought with the
	run's momentum. Rewards are offered as a choice and applied on pick.
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")
local Events = require("overclock.core.events")
local Engine = require("overclock.modifiers.engine")

local M = {}

M.CATALOG = {
	{
		id = "heal_full",
		name = "Полное исцеление",
		desc = "Восстанавливает 100% HP.",
		weight = 20,
		apply = function(run)
			local h = run.hero
			if h and IsValidEntity(h) then h:SetHealth(h:GetMaxHealth()) end
		end,
	},
	{
		id = "gold_pouch",
		name = "Кошель золота",
		desc = "+30 золота.",
		weight = 20,
		apply = function(run) run.gold = run.gold + 30 end,
	},
	{
		id = "damage_up",
		name = "+100 урона",
		desc = "Постоянно +100 урона до конца забега.",
		weight = 14,
		apply = function(run)
			if run.hero and IsValidEntity(run.hero) then
				Engine.apply_id(run.hero, run.hero, "stat_damage_100", nil)
			end
		end,
	},
	{
		id = "hp_up",
		name = "+1000 HP",
		desc = "Постоянно +1000 HP до конца забега.",
		weight = 14,
		apply = function(run)
			if run.hero and IsValidEntity(run.hero) then
				Engine.apply_id(run.hero, run.hero, "stat_hp_1000", nil)
			end
		end,
	},
	{
		id = "as_up",
		name = "+100 скорости атаки",
		desc = "Постоянно +100 AS до конца забега.",
		weight = 12,
		apply = function(run)
			if run.hero and IsValidEntity(run.hero) then
				Engine.apply_id(run.hero, run.hero, "stat_as_100", nil)
			end
		end,
	},
	{
		id = "shield_now",
		name = "Щит 200",
		desc = "Мгновенный щит на 10 секунд.",
		weight = 10,
		apply = function(run)
			if run.hero and IsValidEntity(run.hero) then
				Engine.apply_id(run.hero, run.hero, "buff_shield_200", nil)
			end
		end,
	},
}

function M.roll(run, n)
	n = n or 3
	local picks = {}
	local pool = Util.shallow_copy(M.CATALOG)
	while #picks < n and #pool > 0 do
		local choice = Util.pick_weighted(pool)
		if not choice then break end
		picks[#picks + 1] = choice
		local idx = Util.index_of(pool, choice)
		if idx then table.remove(pool, idx) end
	end
	return picks
end

function M.grant(run, reward_id)
	for _, r in ipairs(M.CATALOG) do
		if r.id == reward_id then
			local ok, err = pcall(r.apply, run)
			if not ok then
				Log.error("reward '%s' failed: %s", reward_id, tostring(err))
				return false
			end
			run.rewards = run.rewards or {}
			table.insert(run.rewards, { id = r.id, wave = run.wave })
			Events.emit("roguelike:reward_granted", { run = run, reward = r })
			Log.info("reward '%s' granted", reward_id)
			return true
		end
	end
	Log.warn("unknown reward: %s", tostring(reward_id))
	return false
end

return M
