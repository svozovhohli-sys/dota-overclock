--[[
	OVERCLOCK :: sandbox/hero_control.lua
	Per-hero knobs: level, ability points, stat bonuses, talents, aghs/shard,
	respawn, and "infinite" toggles. Works on any hero (all heroes).
--]]
local State = require("overclock.core.state")
local Log = require("overclock.core.logger")

local M = {}

M.MAX_LEVEL = 30

function M.for_pid(pid)
	local rec = State.players[pid]
	if rec and rec.hero and IsValidEntity(rec.hero) then return rec.hero end
	return nil
end

function M.set_level(hero, level)
	if not hero then return false end
	level = math.max(1, math.min(M.MAX_LEVEL, tonumber(level) or 1))
	hero:SetLevel(level, true)
	Log.debug("hero %s -> level %d", hero:GetUnitName(), level)
	return true
end

function M.add_ability_points(hero, n)
	if not hero then return false end
	for _ = 1, (n or 1) do
		hero:AddAbilityPoints(1)
	end
	return true
end

function M.max_level_everything(hero)
	if not hero then return false end
	M.set_level(hero, M.MAX_LEVEL)
	hero:SetAbilityPoints(M.MAX_LEVEL)
	-- max every ability it currently has
	for i = 0, hero:GetAbilityCount() - 1 do
		local ab = hero:GetAbilityByIndex(i)
		if ab then
			hero:SetAbilityLevel(ab, 10)
		end
	end
	return true
end

function M.set_talent(hero, tier, branch)
	if not hero then return false end
	local ability = hero:GetAbilityByIndex(15 + tier) -- talents occupy the tail
	if ability and ability:GetName() then
		hero:SetAbilityLevel(ability, 1)
		return true
	end
	return false
end

function M.set_aghs(hero, on)
	if not hero then return false end
	hero:SetHasAghanimsScepter(on and true or false)
	return true
end

function M.set_shard(hero, on)
	if not hero then return false end
	hero:SetHasAghanimsShard(on and true or false)
	return true
end

function M.set_invulnerable(hero, on)
	if not hero then return false end
	hero:SetInvuln(on and true or false)
	return true
end

function M.set_infinite_mana(hero, on)
	if not hero then return false end
	hero:SetMana(hero:GetMaxMana())
	hero:SetBaseManaRegen(hero:GetMaxMana() / 2)
	return true
end

function M.set_attack_speed(hero, bonus)
	if not hero then return false end
	hero:SetAttackSpeed(bonus or 0)
	return true
end

function M.set_move_speed(hero, speed)
	if not hero then return false end
	hero:SetBaseMoveSpeed(speed or 300)
	return true
end

function M.respawn(hero)
	if not hero then return false end
	hero:RespawnHero(false, false)
	return true
end

function M.kill(hero)
	if not hero then return false end
	hero:Kill(nil, nil)
	return true
end

function M.stack_bonus(hero, stat, value)
	-- Apply a permanent-ish stat via the modifier engine rather than raw
	-- stat points, so it can be shown/removed from the UI.
	local ModEngine = require("overclock.modifiers.engine")
	if not hero then return false end
	return ModEngine.apply(hero, hero, "modifier_oc_stat_bonus", {
		stat = stat,
		value = value,
	})
end

return M
