--[[
	OVERCLOCK :: core/logger.lua
	Tiny leveled logger. Writes to the server console with a coloured tag and
	keeps a rolling in-memory buffer so the Panorama "console" panel can show
	recent lines.
--]]
local M = {}

M.LEVELS = { TRACE = 1, DEBUG = 2, INFO = 3, WARN = 4, ERROR = 5, OFF = 6 }

M.level = M.LEVELS.DEBUG
M.buffer = {}
M.max_buffer = 300
M.listeners = {}

local COLOR = {
	TRACE = "\228\188\148", -- will be plain text; colour codes vary by build
}

function M.set_level(level)
	if type(level) == "string" then
		level = M.LEVELS[string.upper(level)] or M.level
	end
	M.level = level
end

function M.on_line(fn)
	table.insert(M.listeners, fn)
end

local function emit(level_name, msg)
	local line = string.format("[OVERCLOCK][%s] %s", level_name, msg)
	print(line)
	table.insert(M.buffer, line)
	if #M.buffer > M.max_buffer then
		table.remove(M.buffer, 1)
	end
	for _, fn in ipairs(M.listeners) do
		pcall(fn, line)
	end
end

local function visible(level)
	return level >= M.level
end

function M.trace(msg, ...)
	if visible(M.LEVELS.TRACE) then
		emit("TRACE", string.format(msg, ...))
	end
end

function M.debug(msg, ...)
	if visible(M.LEVELS.DEBUG) then
		emit("DEBUG", string.format(msg, ...))
	end
end

function M.info(msg, ...)
	if visible(M.LEVELS.INFO) then
		emit("INFO", string.format(msg, ...))
	end
end

function M.warn(msg, ...)
	if visible(M.LEVELS.WARN) then
		emit("WARN", string.format(msg, ...))
	end
end

function M.error(msg, ...)
	if visible(M.LEVELS.ERROR) then
		emit("ERROR", string.format(msg, ...))
	end
end

-- fn, ... -> returns ok, result_or_err. Logs failures instead of crashing.
function M.guard(label, fn, ...)
	local ok, res = pcall(fn, ...)
	if not ok then
		M.error("guard(%s): %s", tostring(label), tostring(res))
	end
	return ok, res
end

function M.dump(value, depth)
	local seen = {}
	local function ser(v, d)
		d = d or 0
		if d > (depth or 4) then return "..." end
		local t = type(v)
		if t == "table" then
			if seen[v] then return "<cycle>" end
			seen[v] = true
			local parts = {}
			for k, val in pairs(v) do
				table.insert(parts, tostring(k) .. "=" .. ser(val, d + 1))
			end
			seen[v] = nil
			return "{" .. table.concat(parts, ", ") .. "}"
		elseif t == "string" then
			return string.format("%q", v)
		end
		return tostring(v)
	end
	return ser(value, 0)
end

return M
