--[[
	OVERCLOCK :: core/commands.lua
	A small command framework shared by the chat parser, the UI bridge and the
	dev console. Every subsystem registers its commands here; the UI gets the
	list via OC.Commands.describe().

	Command signature:
		run(ctx) -> ok, payload
	where ctx = { pid, args = {...}, raw = "...", source = "chat"|"ui"|"console" }
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")

local M = {}

M.registry = {}   -- name -> { name, help, usage, section, run }

function M.register(name, opts)
	assert(type(name) == "string" and name ~= "", "command needs a name")
	assert(type(opts) == "table" and type(opts.run) == "function",
		"command '" .. name .. "' needs run()")
	M.registry[name] = {
		name = name,
		help = opts.help or "",
		usage = opts.usage or name,
		section = opts.section or "general",
		run = opts.run,
	}
end

function M.exists(name)
	return M.registry[name] ~= nil
end

-- Parse and run a raw command string. Returns ok, payload.
function M.execute(ctx)
	local parts = {}
	for token in string.gmatch(ctx.raw or "", "%S+") do
		table.insert(parts, token)
	end
	if #parts == 0 then return false, "пустая команда" end
	local name = parts[1]
	local cmd = M.registry[name]
	if not cmd then
		return false, "нет команды: " .. name
	end
	ctx.args = {}
	for i = 2, #parts do ctx.args[i - 1] = parts[i] end
	ctx.name = name
	local ok, res = pcall(cmd.run, ctx)
	if not ok then
		Log.error("command '%s' failed: %s", name, tostring(res))
		return false, tostring(res)
	end
	return true, res
end

-- Convenience: run and ignore result (used by chat handler).
function M.run_from(pid, raw, source)
	local ctx = { pid = pid, raw = raw, source = source or "chat" }
	local ok, res = M.execute(ctx)
	if not ok then
		Log.warn("player %d command '%s' -> %s", pid, tostring(raw), tostring(res))
	end
	return ok, res
end

-- For the UI: list all commands grouped by section.
function M.describe()
	local out = {}
	for _, cmd in pairs(M.registry) do
		table.insert(out, {
			name = cmd.name,
			help = cmd.help,
			usage = cmd.usage,
			section = cmd.section,
		})
	end
	table.sort(out, function(a, b)
		if a.section == b.section then return a.name < b.name end
		return a.section < b.section
	end)
	return out
end

function M.sections()
	local set = {}
	for _, cmd in pairs(M.registry) do
		set[cmd.section] = (set[cmd.section] or 0) + 1
	end
	return set
end

function M.count()
	return Util.count(M.registry)
end

return M
