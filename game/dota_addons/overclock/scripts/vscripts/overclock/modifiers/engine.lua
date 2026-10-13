--[[
	OVERCLOCK :: modifiers/engine.lua
	Apply / query / remove modifiers, including data-driven ones (by id) and
	stacking policy handling.

	Stacking policy lives in the registry definition and is interpreted here so
	individual Lua modifiers stay dumb.
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")
local Registry = require("overclock.modifiers.registry")
local Events = require("overclock.core.events")

local M = {}

local function find_mod(target, mod_name)
	if not target or not IsValidEntity(target) then return nil end
	return target:FindModifierByName(mod_name)
end

-- Low-level: add a modifier class directly.
function M.apply(target, caster, mod_name, kv, duration)
	if not target or not IsValidEntity(target) then return false end
	local ok, mod = pcall(target.AddNewModifier, target, caster, nil, mod_name, kv or {})
	if not ok or not mod then
		Log.warn("apply %s failed: %s", tostring(mod_name), tostring(mod))
		return false
	end
	if duration then
		mod:SetDuration(duration, true)
	end
	Events.emit("modifier:applied", { target = target, name = mod_name, kv = kv })
	return mod
end

function M.remove(target, mod_name)
	if not target or not IsValidEntity(target) then return false end
	target:RemoveModifierByName(mod_name)
	return true
end

function M.remove_all(target)
	if not target or not IsValidEntity(target) then return false end
	local n = 0
	for _, def in pairs(Registry.all()) do
		if target:HasModifier(def.modifier) then
			target:RemoveModifierByName(def.modifier)
			n = n + 1
		end
	end
	return n
end

function M.has(target, mod_name)
	if not target or not IsValidEntity(target) then return false end
	return target:HasModifier(mod_name) == true
end

-- Apply a registered modifier by id, honoring its stacking policy.
-- overrides is a table merged into the def.kv and may carry a "duration".
function M.apply_id(target, caster, id, overrides)
	local def = Registry.get(id)
	if not def then
		Log.warn("unknown modifier id: %s", tostring(id))
		return false
	end
	overrides = overrides or {}
	local kv = Util.deep_copy(def.kv or {})
	for k, v in pairs(overrides) do kv[k] = v end

	local policy = def.stacks or "refresh"
	local existing = find_mod(target, def.modifier)

	if existing and policy == "refresh" then
		existing:ForceRefresh()
		if overrides.duration ~= nil then
			existing:SetDuration(overrides.duration, true)
		elseif def.duration then
			existing:SetDuration(def.duration, true)
		end
		Events.emit("modifier:refreshed", { target = target, id = id })
		return existing
	end

	if existing and policy == "stack" then
		existing:IncrementStackCount()
		existing:SetStackCount(existing:GetStackCount() + 1)
		Events.emit("modifier:stacked", { target = target, id = id })
		return existing
	end

	-- "independent" or no existing -> add a fresh one
	local duration = overrides.duration
	if duration == nil then duration = def.duration end
	local mod = M.apply(target, caster, def.modifier, kv, duration)
	if mod and def.stacks == "independent" and mod.SetStackCount then
		mod:SetStackCount(1)
	end
	Events.emit("modifier:applied_id", { target = target, id = id })
	return mod
end

function M.get_stacks(target, id)
	local def = Registry.get(id)
	if not def then return 0 end
	local mod = find_mod(target, def.modifier)
	return mod and mod:GetStackCount() or 0
end

-- Return a summary of OC modifiers currently on a unit (for the UI).
function M.list_on(target)
	local out = {}
	if not target or not IsValidEntity(target) then return out end
	for _, def in pairs(Registry.all()) do
		local mod = find_mod(target, def.modifier)
		if mod then
			table.insert(out, {
				id = def.id,
				label = def.label,
				category = def.category,
				stacks = (mod.GetStackCount and mod:GetStackCount()) or 1,
				remaining = (mod.GetRemainingTime and mod:GetRemainingTime()) or -1,
			})
		end
	end
	return out
end

function M.reset()
	Events.emit("modifier:reset")
end

return M
