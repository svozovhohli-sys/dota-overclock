--[[
	OVERCLOCK :: patch/patch_lab.lua
	Apply / clear named balance patches and run A/B comparisons.

	Rules supported in a patch set:
		{ modifier = "<modifier id>", target = "all_heroes"|"dummies"|"players" }
		{ hp_mult = 0.8, target = ... }        -- scale max HP
		{ mana_mult = 0.5, target = ... }       -- scale max mana

	Base values are snapshotted on apply so clear() restores them exactly.
--]]
local Log = require("overclock.core.logger")
local Events = require("overclock.core.events")
local State = require("overclock.core.state")
local Players = require("overclock.core.players")
local Engine = require("overclock.modifiers.engine")

local M = {}

M.sets = {}
M.active_id = nil
M.snapshots = {}   -- entity index -> { hp, mana }

function M.load_all()
	local ok, data = pcall(require, "overclock.patch.patch_sets")
	if not ok then
		Log.error("cannot load patch_sets: %s", tostring(data))
		return 0
	end
	for _, set in ipairs(data) do
		M.sets[set.id] = set
	end
	Log.info("loaded %d patch sets", #data)
	return #data
end

function M.list()
	local out = {}
	for _, set in pairs(M.sets) do table.insert(out, set) end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

local function targets(kind)
	if kind == "dummies" then
		local out = {}
		for index in pairs(State.dummies) do
			local ent = EntIndexToHScript and EntIndexToHScript(index) or nil
			if ent and IsValidEntity(ent) then table.insert(out, ent) end
		end
		return out
	end
	if kind == "players" then
		return Players.all_heroes()
	end
	return Players.all_heroes()
end

local function snapshot(unit)
	if not M.snapshots[unit:entindex()] then
		M.snapshots[unit:entindex()] = {
			hp = unit:GetMaxHealth(),
			mana = unit:GetMaxMana(),
		}
	end
end

function M.apply_set(id, caster)
	local set = M.sets[id]
	if not set then
		Log.warn("unknown patch set: %s", tostring(id))
		return false
	end
	M.clear()
	local applied = 0
	for _, rule in ipairs(set.rules or {}) do
		local units = targets(rule.target or "all_heroes")
		for _, unit in ipairs(units) do
			snapshot(unit)
			if rule.modifier then
				Engine.apply_id(unit, caster or unit, rule.modifier, rule.kv)
				applied = applied + 1
			elseif rule.hp_mult then
				local base = M.snapshots[unit:entindex()].hp
				local newmax = math.max(1, math.floor(base * rule.hp_mult))
				unit:SetMaxHealth(newmax)
				unit:SetHealth(math.min(unit:GetHealth(), newmax))
				applied = applied + 1
			elseif rule.mana_mult then
				local base = M.snapshots[unit:entindex()].mana
				local newmax = math.max(0, math.floor(base * rule.mana_mult))
				unit:SetMaxMana(newmax)
				applied = applied + 1
			end
		end
	end
	M.active_id = id
	State.active_patch = id
	Events.emit("patch:applied", { id = id, applied = applied })
	Log.info("patch '%s' applied (%d effects)", id, applied)
	return true, applied
end

function M.clear()
	-- remove modifiers + restore base values
	for index in pairs(M.snapshots) do
		local unit = EntIndexToHScript and EntIndexToHScript(index) or nil
		if unit and IsValidEntity(unit) then
			Engine.remove_all(unit)
			local snap = M.snapshots[index]
			unit:SetMaxHealth(snap.hp)
			unit:SetHealth(math.min(unit:GetHealth(), snap.hp))
			if snap.mana then
				unit:SetMaxMana(snap.mana)
			end
		end
	end
	M.snapshots = {}
	M.active_id = nil
	State.active_patch = nil
	Events.emit("patch:cleared")
	return true
end

function M.active()
	return M.active_id
end

-- Remember the metrics snapshot we saw while a patch was active.
M.benchmark = {}

function M.mark_benchmark(label)
	local dps = require("overclock.metrics.dps").snapshot()
	M.benchmark[label or (M.active_id or "none")] = { t = GameRules:GetGameTime(), dps = dps }
	Events.emit("patch:benchmark", { label = label, dps = dps })
	return true
end

-- Simple A/B report from the two most recent benchmarks.
function M.compare(label_a, label_b)
	local a = M.benchmark[label_a]
	local b = M.benchmark[label_b]
	if not a or not b then
		return { ok = false, reason = "нет бенчмарков для " .. tostring(label_a) .. " и " .. tostring(label_b) }
	end
	local function top(entry)
		return entry.dps[1] and entry.dps[1].dps or 0
	end
	local da, db = top(a), top(b)
	return {
		ok = true,
		label_a = label_a,
		label_b = label_b,
		dps_a = da,
		dps_b = db,
		delta = db - da,
		delta_pct = da > 0 and ((db - da) / da * 100) or 0,
	}
end

return M
