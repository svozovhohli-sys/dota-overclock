--[[
	OVERCLOCK :: metrics/ttk.lua
	Time-to-kill: both *predicted* (EHP / damage rate) and *measured* (from the
	first hit on a dummy until it dies). Measurement is armed per victim.
--]]
local Events = require("overclock.core.events")
local DamageLog = require("overclock.metrics.damage_log")
local Ehp = require("overclock.metrics.ehp")
local Dps = require("overclock.metrics.dps")
local State = require("overclock.core.state")

local M = {}

-- measured[attacker_index][victim_index] = { start_t, last_t, damage, dead=false }
M.active = {}
M.results = {}

function M.install()
	if not State.metrics.ttk_enabled then return end
	Events.subscribe("damage:dealt", function(entry)
		if entry.victim_index == nil or entry.attacker_index == nil then return end
		local per_attacker = M.active[entry.attacker_index]
		if not per_attacker then
			per_attacker = {}
			M.active[entry.attacker_index] = per_attacker
		end
		local rec = per_attacker[entry.victim_index]
		if not rec then
			rec = { start_t = entry.t, damage = 0 }
			per_attacker[entry.victim_index] = rec
		end
		rec.last_t = entry.t
		rec.damage = rec.damage + entry.amount
	end)
	Events.on("entity_killed", function(data)
		local victim = EntIndexToHScript and EntIndexToHScript(data.entindex_killed) or nil
		if not victim then return end
		M.finalize(victim)
	end)
end

local function record(attacker_index, victim_index, ttk, damage)
	table.insert(M.results, {
		attacker_index = attacker_index,
		victim_index = victim_index,
		ttk = ttk,
		damage = damage,
	})
	if #M.results > 200 then table.remove(M.results, 1) end
end

function M.finalize(victim)
	local vi = victim:entindex()
	for ai, per in pairs(M.active) do
		local rec = per[vi]
		if rec and rec.last_t then
			record(ai, vi, rec.last_t - rec.start_t, rec.damage)
			per[vi] = nil
		end
	end
	Events.emit("ttk:measured", { victim = victim })
end

-- Predicted secs for `attacker` to kill `victim` at current DPS.
function M.predict(attacker, victim)
	local ehp = Ehp.of_unit(victim)
	if not ehp or not attacker then return nil end
	local dps = Dps.current(attacker:entindex())
	if dps <= 0 then return nil end
	return ehp.average / dps, ehp
end

function M.reset()
	M.active = {}
	M.results = {}
end

function M.snapshot()
	local out = {}
	for _, r in ipairs(M.results) do
		local v = EntIndexToHScript and EntIndexToHScript(r.victim_index) or nil
		table.insert(out, {
			victim = (v and IsValidEntity(v)) and v:GetUnitName() or "?",
			ttk = r.ttk,
			damage = r.damage,
		})
	end
	return out
end

return M
