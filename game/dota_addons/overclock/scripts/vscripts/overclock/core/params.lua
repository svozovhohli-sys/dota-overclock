--[[
	OVERCLOCK :: core/params.lua
	Runtime tunable-parameter registry. The heart of the "change values on the
	fly" UI: any subsystem registers a parameter here (with metadata + get/set
	closures) and the Panorama panel renders a control for it automatically.

	Parameter definition:
		{
			id      = "time_scale",           -- stable string id
			label   = "Скорость времени",
			section = "Время",                -- grouping in the UI
			type    = "number"|"bool"|"enum"|"action"|"text",
			min, max, step,                   -- number
			options = { {"0.5","x0.5"}, ... },-- enum: {value, label}
			unit    = "x",                    -- optional suffix for display
			get     = function(ctx) ... end,  -- number/bool/enum/text
			set     = function(value, ctx) ... end,
			run     = function(ctx) ... end,  -- action
		}

	ctx is { pid = <PlayerID> } and is threaded through so per-player params
	(e.g. hero stats) resolve against the caller.
--]]
local Log = require("overclock.core.logger")

local M = {}

M.defs = {}
M.order = {}

local VALID_TYPES = {
	number = true, bool = true, enum = true, action = true, text = true,
}

function M.register(def)
	assert(type(def) == "table" and def.id, "param needs an id")
	assert(type(def) == "table" and def.label, "param " .. tostring(def.id) .. " needs a label")
	local t = def.type or "number"
	assert(VALID_TYPES[t], "param " .. def.id .. " bad type " .. tostring(t))
	if not M.defs[def.id] then
		table.insert(M.order, def.id)
	end
	def.type = t
	M.defs[def.id] = def
	return def
end

function M.exists(id)
	return M.defs[id] ~= nil
end

local function coerce(def, raw)
	if def.type == "number" then
		local n = tonumber(raw)
		if n == nil then return nil end
		if def.min then n = math.max(def.min, n) end
		if def.max then n = math.min(def.max, n) end
		if def.step and def.step > 0 then
			n = math.floor(n / def.step + 0.5) * def.step
		end
		return n
	elseif def.type == "bool" then
		if type(raw) == "boolean" then return raw end
		if raw == 1 or raw == "1" then return true end
		if raw == 0 or raw == "0" then return false end
		return raw == true or raw == "true"
	end
	return raw
end

function M.value(id, ctx)
	local def = M.defs[id]
	if not def then return nil end
	if def.get then
		local ok, v = pcall(def.get, ctx or {})
		if ok then return v end
		Log.warn("param '%s' get failed: %s", id, tostring(v))
		return nil
	end
	return def.value
end

function M.set(id, raw, ctx)
	local def = M.defs[id]
	if not def then return false, "unknown param" end
	if def.type == "action" then
		return M.invoke(id, ctx)
	end
	local v = coerce(def, raw)
	if v == nil and def.type == "number" then
		return false, "not a number"
	end
	local ok, err
	if def.set then
		ok, err = pcall(def.set, v, ctx or {})
	else
		def.value = v
		ok = true
	end
	if not ok then
		Log.error("param '%s' set failed: %s", id, tostring(err))
		return false, tostring(err)
	end
	return true, v
end

function M.invoke(id, ctx)
	local def = M.defs[id]
	if not def then return false, "unknown param" end
	if def.run then
		local ok, err = pcall(def.run, ctx or {})
		if not ok then
			Log.error("param '%s' action failed: %s", id, tostring(err))
			return false, tostring(err)
		end
	end
	return true
end

-- Serialisable listing for the UI. ctx threads through to get().
function M.list(ctx)
	ctx = ctx or {}
	local out = {}
	for _, id in ipairs(M.order) do
		local def = M.defs[id]
		out[#out + 1] = {
			id = id,
			label = def.label,
			section = def.section or "Прочее",
			type = def.type,
			min = def.min,
			max = def.max,
			step = def.step,
			options = def.options,
			unit = def.unit,
			value = (def.type ~= "action") and M.value(id, ctx) or nil,
		}
	end
	return out
end

function M.sections()
	local seen, out = {}, {}
	for _, id in ipairs(M.order) do
		local s = M.defs[id].section or "Прочее"
		if not seen[s] then seen[s] = true; out[#out + 1] = s end
	end
	return out
end

function M.count()
	local n = 0
	for _ in pairs(M.defs) do n = n + 1 end
	return n
end

return M
