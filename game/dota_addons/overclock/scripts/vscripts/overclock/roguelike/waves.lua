--[[
	OVERCLOCK :: roguelike/waves.lua
	Builds and spawns enemy waves, then watches for their death to signal a
	cleared wave. Communicates purely through the event bus so it does not need
	to know about run.lua.
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")
local Config = require("overclock.core.config")
local State = require("overclock.core.state")
local Events = require("overclock.core.events")
local Spawner = require("overclock.sandbox.spawner")

local M = {}

M.POOL = {
	"npc_dota_creep_badguys_melee",
	"npc_dota_creep_badguys_ranged",
	"npc_dota_neutral_centaur_khan",
	"npc_dota_neutral_prowler_shaman",
	"npc_dota_neutral_dark_troll_warlord",
}

-- Arena ring around the map center; waves spawn evenly around it.
M.ARENA_RADIUS = 1400
M.CENTER = Vector(0, 0, 0)

function M.difficulty(wave)
	-- HP multiplier grows ~18% per wave, count every other wave, all scaled by
	-- the live tuning factors from the params panel.
	local hp_mult = (1.18 ^ (wave - 1)) * (Config.tuning.rogue_hp_scale or 1.0)
	local dmg_mult = (1.10 ^ (wave - 1)) * (Config.tuning.rogue_dmg_scale or 1.0)
	local count = math.max(1, math.floor((4 + (wave - 1) * 1.5) *
		(Config.tuning.rogue_count_scale or 1.0)))
	return hp_mult, dmg_mult, count
end

function M.build(wave)
	local hp_mult, dmg_mult, count = M.difficulty(wave)
	local units = {}
	for i = 1, count do
		local name = M.POOL[((i - 1) % #M.POOL) + 1]
		units[#units + 1] = {
			name = name,
			hp_mult = hp_mult,
			dmg_mult = dmg_mult,
		}
	end
	return { wave = wave, units = units, hp_mult = hp_mult, dmg_mult = dmg_mult }
end

-- Spawn a prepared wave; wires a death-listener so we can detect completion.
function M.spawn(run, wave)
	local def = M.build(wave)
	local spawned = {}
	local n = #def.units
	for i, u in ipairs(def.units) do
		local angle = (i / n) * 2 * math.pi
		local pos = M.CENTER + Vector(math.cos(angle) * M.ARENA_RADIUS,
			math.sin(angle) * M.ARENA_RADIUS, 128)
		local unit = Spawner.spawn_unit(u.name, pos, { team = Config.TEAM.ENEMIES })
		if unit then
			local base_hp = unit:GetMaxHealth()
			unit:SetMaxHealth(math.floor(base_hp * u.hp_mult))
			unit:SetHealth(unit:GetMaxHealth())
			if unit.SetBaseDamageMin and unit.SetBaseDamageMax then
				unit:SetBaseDamageMin(unit:GetBaseDamageMin() * u.dmg_mult)
				unit:SetBaseDamageMax(unit:GetBaseDamageMax() * u.dmg_mult)
			end
			unit.oc_run = run  -- tag for the kill listener
			spawned[#spawned + 1] = unit
		end
	end
	run.enemies_alive = #spawned
	run.status = "fight"
	Events.emit("roguelike:wave_started", { run = run, wave = wave, count = #spawned })
	Log.info("wave %d: spawned %d enemies (hp x%.2f)", wave, #spawned, def.hp_mult)
	return #spawned
end

-- Wired once by run.lua.
function M.install()
	Events.on("entity_killed", function(data)
		local run = State.run
		if not run or not run.active then return end
		local victim = EntIndexToHScript and EntIndexToHScript(data.entindex_killed) or nil
		if not victim or not victim.oc_run then return end
		run.enemies_alive = math.max(0, (run.enemies_alive or 0) - 1)
		Events.emit("roguelike:enemy_killed", { run = run, victim = victim })
		if run.enemies_alive == 0 and run.status == "fight" then
			Events.emit("roguelike:wave_cleared", { run = run, wave = run.wave })
		end
	end)
end

return M
