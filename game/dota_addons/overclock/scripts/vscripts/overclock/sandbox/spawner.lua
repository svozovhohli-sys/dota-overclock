--[[
	OVERCLOCK :: sandbox/spawner.lua
	Create / track / remove units, heroes and metric dummies.

	All spawned entities are registered in State.spawned so the UI can list,
	remove or teleport them, and so a map reset can wipe everything.
--]]
local State = require("overclock.core.state")
local Log = require("overclock.core.logger")
local Config = require("overclock.core.config")
local Events = require("overclock.core.events")
local Util = require("overclock.core.util")

local M = {}

-- A curated, precache-able list; users can spawn anything, but these are the
-- common ones offered in the UI dropdown.
M.COMMON_UNITS = {
	"npc_dota_creep_badguys_melee",
	"npc_dota_creep_goodguys_melee",
	"npc_dota_neutral_centaur_khan",
	"npc_dota_neutral_prowler_shaman",
	"npc_dota_roshan",
	"npc_dota_creep_badguys_ranged",
	"npc_dota_creep_goodguys_ranged",
	"npc_dota_neutral_dark_troll_warlord",
}

M.COMMON_HEROES = {
	"npc_dota_hero_axe",
	"npc_dota_hero_invoker",
	"npc_dota_hero_queenofpain",
	"npc_dota_hero_lina",
	"npc_dota_hero_sniper",
	"npc_dota_hero_pudge",
	"npc_dota_hero_juggernaut",
	"npc_dota_hero_crystal_maiden",
}

local function register(unit, kind, extra)
	local rec = {
		entity = unit,
		index = unit:entindex(),
		kind = kind,
		name = unit:GetUnitName(),
		team = unit:GetTeamNumber(),
		spawned_at = GameRules:GetGameTime(),
	}
	if extra then
		for k, v in pairs(extra) do rec[k] = v end
	end
	State.spawned[unit:entindex()] = rec
	Events.emit("spawner:spawned", rec)
	return rec
end

function M.precache()
	for _, u in ipairs(M.COMMON_UNITS) do
		PrecacheUnitByNameAsync(u, function() end)
	end
	for _, h in ipairs(M.COMMON_HEROES) do
		PrecacheUnitByNameAsync(h, function() end)
	end
	PrecacheUnitByNameAsync(Config.DUMMY_UNIT, function() end)
end

-- Spawn a non-hero unit. opts = { team, face_angle, owner }
function M.spawn_unit(name, pos, opts)
	opts = opts or {}
	local team = opts.team or Config.TEAM.ENEMIES
	local ok, unit = pcall(CreateUnitByName, name, pos, true,
		opts.owner, opts.owner, team)
	if not ok or not unit then
		Log.error("spawn_unit failed: %s (%s)", tostring(name), tostring(unit))
		return nil
	end
	if opts.face_angle then
		unit:SetForwardVector(Vector(math.cos(opts.face_angle), math.sin(opts.face_angle), 0))
	end
	register(unit, "unit", opts)
	return unit
end

-- Spawn a hero for a player (replaces their current hero if any).
function M.spawn_hero(name, pid, pos)
	local ok, hero = pcall(CreateHeroForPlayer, name, pid)
	if not ok or not hero then
		Log.error("spawn_hero failed: %s p%s (%s)", tostring(name), tostring(pid), tostring(hero))
		return nil
	end
	if pos then
		hero:SetAbsOrigin(pos)
	end
	register(hero, "hero", { pid = pid })
	State.heroes[hero:entindex()] = hero
	return hero
end

-- Create a stationary, invulnerable-but-damageable dummy for measurements.
function M.spawn_dummy(pos, opts)
	opts = opts or {}
	local team = opts.team or Config.TEAM.ENEMIES
	local dummy = M.spawn_unit(Config.DUMMY_UNIT, pos, { team = team })
	if not dummy then return nil end
	dummy:AddNewModifier(dummy, nil, "modifier_oc_dummy", {})
	if opts.hp then
		dummy:SetMaxHealth(opts.hp)
		dummy:SetHealth(opts.hp)
	end
	if opts.armor then
		dummy:SetPhysicalArmorBaseValue(opts.armor)
	end
	State.dummies[dummy:entindex()] = true
	Events.emit("spawner:dummy", dummy)
	return dummy
end

function M.remove(entity)
	if not entity or not IsValidEntity(entity) then return false end
	State.spawned[entity:entindex()] = nil
	State.dummies[entity:entindex()] = nil
	State.heroes[entity:entindex()] = nil
	UTIL_Remove(entity)
	Events.emit("spawner:removed", entity)
	return true
end

function M.remove_by_index(index)
	local rec = State.spawned[index]
	if rec then return M.remove(rec.entity) end
	return false
end

-- Remove everything the sandbox created (not the players' own heroes unless
-- flag set).
function M.clear(include_heroes)
	local removed = 0
	for index, rec in pairs(State.spawned) do
		if rec.kind ~= "hero" or include_heroes then
			if rec.entity and IsValidEntity(rec.entity) then
				UTIL_Remove(rec.entity)
				removed = removed + 1
			end
		end
	end
	State.reset_round_state()
	Events.emit("spawner:cleared", removed)
	Log.info("cleared %d spawned entities", removed)
	return removed
end

function M.list()
	local out = {}
	for index, rec in pairs(State.spawned) do
		table.insert(out, {
			index = index,
			name = rec.name,
			kind = rec.kind,
			team = rec.team,
			hp = (rec.entity and IsValidEntity(rec.entity))
				and math.floor(rec.entity:GetHealth()) or 0,
		})
	end
	table.sort(out, function(a, b) return a.index < b.index end)
	return out
end

function M.count()
	return Util.count(State.spawned)
end

return M
