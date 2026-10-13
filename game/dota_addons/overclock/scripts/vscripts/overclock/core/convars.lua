--[[
	OVERCLOCK :: core/convars.lua
	Thin, safe wrapper around the engine ConVar store + server console.

	This is the universal escape hatch: anything the engine exposes as a
	`dota_*` / `sv_*` / `cl_*` variable can be read and written from here,
	including variables that have no dedicated Lua API. When a ConVar is not
	registered (or is server-only) we fall back to SendToServerConsole, which
	runs the equivalent `name value` command in the server console.

	None of this touches the base game installation - it only changes runtime
	values inside the running custom game.
--]]
local Log = require("overclock.core.logger")

local M = {}

local function has_convars()
	return Convars ~= nil
end

-- Read a ConVar as string. Returns nil if unavailable.
function M.get(name)
	if not has_convars() or type(name) ~= "string" or name == "" then return nil end
	local ok, v = pcall(function() return Convars:GetStr(name) end)
	if ok then return v end
	return nil
end

function M.get_number(name, default)
	local v = M.get(name)
	if v == nil then return default end
	return tonumber(v) or default
end

-- Set an integer ConVar. Falls back to console if needed.
function M.set_int(name, value)
	value = math.floor(tonumber(value) or 0)
	if has_convars() then
		local ok = pcall(function() Convars:SetInt(name, value) end)
		if ok then return true end
	end
	return M.exec(string.format("%s %d", tostring(name), value))
end

-- Set a float ConVar.
function M.set_float(name, value)
	value = tonumber(value) or 0
	if has_convars() then
		local ok = pcall(function() Convars:SetFloat(name, value) end)
		if ok then return true end
	end
	return M.exec(string.format("%s %s", tostring(name), tostring(value)))
end

-- Set a string ConVar.
function M.set_str(name, value)
	value = tostring(value or "")
	if has_convars() then
		local ok = pcall(function() Convars:SetStr(name, tostring(name), value) end)
		if ok then return true end
		local ok2 = pcall(function() Convars:SetStr(name, value) end)
		if ok2 then return true end
	end
	return M.exec(string.format("%s %s", tostring(name), value))
end

-- Smart setter: picks int/float/str based on the value's shape.
function M.set_auto(name, value)
	if type(value) == "number" then
		if value == math.floor(value) then
			return M.set_int(name, value)
		end
		return M.set_float(name, value)
	end
	local n = tonumber(value)
	if n ~= nil and tostring(n) == tostring(value) then
		if n == math.floor(n) then return M.set_int(name, n) end
		return M.set_float(name, n)
	end
	return M.set_str(name, value)
end

-- Run a raw server console command (also the migration path for ConVars the
-- Convar API refuses to touch).
function M.exec(cmd)
	if type(cmd) ~= "string" or cmd == "" then return false end
	if SendToServerConsole then
		local ok, err = pcall(SendToServerConsole, cmd)
		if not ok then
			Log.warn("console exec failed for '%s': %s", cmd, tostring(err))
			return false
		end
		Log.info("console: %s", cmd)
		return true
	end
	Log.warn("SendToServerConsole unavailable; cannot run '%s'", cmd)
	return false
end

return M
