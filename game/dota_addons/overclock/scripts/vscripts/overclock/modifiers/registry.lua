--[[
	OVERCLOCK :: modifiers/registry.lua
	Data-driven modifier catalog. Each definition maps a stable string id to a
	Lua modifier class and default KV, so both the UI and the roguelike/patch
	systems can apply modifiers without hard-coding class names.

	Definition schema (data/modifiers.lua returns a list of these):
		{
			id       = "slow_50",
			modifier = "modifier_oc_slow",
			file     = "overclock/lua_modifiers/modifier_oc_slow",
			motion   = LUA_MODIFIER_MOTION_NONE,  -- optional
			label    = "#OC_mod_slow_50",
			desc     = "#OC_mod_slow_50_desc",
			category = "debuff"|"buff"|"curse"|"aura",
			duration = 5.0,        -- nil = infinite
			stacks   = "refresh"|"stack"|"independent",
			kv       = { slow = 50 },
		}
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")

local M = {}

M.defs = {}
M.by_category = {}
M.linked = {}

function M.register(def)
	assert(type(def) == "table" and def.id, "modifier def needs an id")
	assert(def.modifier, "modifier def " .. tostring(def.id) .. " needs a modifier class")
	M.defs[def.id] = def
	M.by_category[def.category or "misc"] =
		M.by_category[def.category or "misc"] or {}
	table.insert(M.by_category[def.category or "misc"], def)

	if def.file and not M.linked[def.modifier] then
		local ok, err = pcall(LinkLuaModifier, def.modifier, def.file,
			def.motion or LUA_MODIFIER_MOTION_NONE)
		if not ok then
			Log.error("LinkLuaModifier failed for %s: %s", def.id, tostring(err))
		else
			M.linked[def.modifier] = true
		end
	end
	return def
end

function M.get(id)
	return M.defs[id]
end

function M.all()
	return M.defs
end

function M.list(category)
	if category then
		return M.by_category[category] or {}
	end
	local out = {}
	for _, def in pairs(M.defs) do table.insert(out, def) end
	table.sort(out, function(a, b) return a.id < b.id end)
	return out
end

function M.categories()
	return Util.keys(M.by_category)
end

function M.load_all()
	local ok, data = pcall(require, "overclock.data.modifiers")
	if not ok then
		Log.error("cannot load data/modifiers.lua: %s", tostring(data))
		return 0
	end
	local n = 0
	for _, def in ipairs(data) do
		M.register(def)
		n = n + 1
	end
	Log.info("registered %d modifier definitions", n)
	return n
end

return M
