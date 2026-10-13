--[[
	OVERCLOCK :: metrics/damage_log.lua
	Central damage capture. Installs the engine damage filter and records every
	damage instance into a ring buffer + running aggregates. Other metric
	modules (dps, ttk) subscribe to `damage:dealt` instead of re-hooking.
--]]
local Log = require("overclock.core.logger")
local Config = require("overclock.core.config")
local State = require("overclock.core.state")
local Events = require("overclock.core.events")
local Util = require("overclock.core.util")

local M = {}

M.entries = {}          -- ring buffer
M.seq = 0
M.installed = false

-- aggregates keyed by attacker entindex
M.by_attacker = {}
-- aggregates keyed by victim entindex
M.by_victim = {}

M.DAMAGE_TYPE_NAME = {
	[DAMAGE_TYPE_PHYSICAL] = "physical",
	[DAMAGE_TYPE_MAGICAL] = "magical",
	[DAMAGE_TYPE_PURE] = "pure",
}

local function bump(store, index, dtype, amount)
	local rec = store[index]
	if not rec then
		rec = { total = 0, by_type = {}, hits = 0 }
		store[index] = rec
	end
	rec.total = rec.total + amount
	rec.hits = rec.hits + 1
	rec.by_type[dtype] = (rec.by_type[dtype] or 0) + amount
end

function M.on_damage(info)
	if not State.metrics.damage_log_enabled then return true end
	local dtype = M.DAMAGE_TYPE_NAME[info.damage_type] or "unknown"
	local amount = math.max(0, tonumber(info.damage) or 0)
	M.seq = M.seq + 1

	local entry = {
		seq = M.seq,
		t = GameRules:GetGameTime(),
		amount = amount,
		type = dtype,
		victim = info.victim,
		victim_index = info.victim and info.victim:entindex() or -1,
		attacker = info.attacker,
		attacker_index = info.attacker and info.attacker:entindex() or -1,
		ability = info.inflictor and info.inflictor:GetName() or nil,
	}
	table.insert(M.entries, entry)
	if #M.entries > Config.tuning.damage_log_cap then
		table.remove(M.entries, 1)
	end

	if info.attacker then
		bump(M.by_attacker, entry.attacker_index, dtype, amount)
	end
	if info.victim then
		bump(M.by_victim, entry.victim_index, dtype, amount)
	end

	Events.emit("damage:dealt", entry)
	return true
end

function M.install()
	if M.installed then return end
	local ok, err = pcall(function()
		local gm = GameRules:GetGameModeEntity()
		gm:SetDamageFilter(function(info)
			local good, res = pcall(M.on_damage, info)
			if not good then
				Log.error("damage filter: %s", tostring(res))
				return true
			end
			return res
		end)
	end)
	if ok then
		M.installed = true
		Log.info("damage log installed")
	else
		Log.warn("SetDamageFilter unavailable: %s", tostring(err))
	end
end

function M.recent(n)
	n = n or 20
	local out = {}
	local start = math.max(1, #M.entries - n + 1)
	for i = start, #M.entries do
		table.insert(out, M.entries[i])
	end
	return out
end

function M.attacker_summary()
	local out = {}
	for index, rec in pairs(M.by_attacker) do
		local name = "?"
		local ent = EntIndexToHScript and EntIndexToHScript(index) or nil
		if ent and IsValidEntity(ent) then name = ent:GetUnitName() end
		table.insert(out, {
			index = index,
			name = name,
			total = rec.total,
			hits = rec.hits,
			by_type = rec.by_type,
		})
	end
	table.sort(out, function(a, b) return a.total > b.total end)
	return out
end

function M.victim_summary()
	local out = {}
	for index, rec in pairs(M.by_victim) do
		local name = "?"
		local ent = EntIndexToHScript and EntIndexToHScript(index) or nil
		if ent and IsValidEntity(ent) then name = ent:GetUnitName() end
		table.insert(out, {
			index = index,
			name = name,
			total = rec.total,
			hits = rec.hits,
			by_type = rec.by_type,
		})
	end
	table.sort(out, function(a, b) return a.total > b.total end)
	return out
end

function M.reset()
	M.entries = {}
	M.by_attacker = {}
	M.by_victim = {}
	M.seq = 0
	Events.emit("damage:reset")
end

function M.stats()
	return {
		count = M.seq,
		buffer = #M.entries,
		attackers = Util.count(M.by_attacker),
		victims = Util.count(M.by_victim),
	}
end

return M
