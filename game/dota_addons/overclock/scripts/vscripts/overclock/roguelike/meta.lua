--[[
	OVERCLOCK :: roguelike/meta.lua
	Meta progression between runs: best wave, total runs, shards (currency for
	future unlocks). Persistence is best-effort: custom games cannot rely on a
	writable filesystem, so this keeps state in memory for the session and only
	attempts a file write when the host allows it.
--]]
local Log = require("overclock.core.logger")
local Config = require("overclock.core.config")

local M = {}

M.SAVE_FILE = "overclock_meta.txt"

M.data = {
	version = Config.SAVE_VERSION,
	best_wave = 0,
	best_depth = 0,
	runs = 0,
	wins = 0,
	shards = 0,
	unlocks = {},
}

function M.reset()
	M.data = {
		version = Config.SAVE_VERSION,
		best_wave = 0,
		best_depth = 0,
		runs = 0,
		wins = 0,
		shards = 0,
		unlocks = {},
	}
end

function M.record_run(run)
	M.data.runs = M.data.runs + 1
	local wave = run.wave or 0
	if wave > M.data.best_wave then M.data.best_wave = wave end
	local depth = run.depth or 0
	if depth > M.data.best_depth then M.data.best_depth = depth end
	-- shards: 1 per cleared wave, +10 for a "win" (wave 20+)
	local gained = depth
	if depth >= 20 then
		M.data.wins = M.data.wins + 1
		gained = gained + 10
	end
	M.data.shards = M.data.shards + gained
	Log.info("meta: run recorded (wave %d, depth %d, +%d shards)", wave, depth, gained)
	return gained
end

function M.add_shards(n)
	M.data.shards = M.data.shards + (n or 0)
end

function M.unlock(id)
	M.data.unlocks[id] = true
end

function M.has_unlock(id)
	return M.data.unlocks[id] == true
end

function M.spend_shards(n)
	if M.data.shards < (n or 0) then return false end
	M.data.shards = M.data.shards - n
	return true
end

function M.serialize()
	local parts = {
		"version=" .. tostring(M.data.version),
		"best_wave=" .. tostring(M.data.best_wave),
		"best_depth=" .. tostring(M.data.best_depth),
		"runs=" .. tostring(M.data.runs),
		"wins=" .. tostring(M.data.wins),
		"shards=" .. tostring(M.data.shards),
	}
	for id in pairs(M.data.unlocks) do
		parts[#parts + 1] = "unlock=" .. tostring(id)
	end
	return table.concat(parts, "\n")
end

function M.deserialize(text)
	if type(text) ~= "string" then return false end
	for line in text:gmatch("[^\n]+") do
		local k, v = line:match("^([%w_]+)=(.*)$")
		if k == "best_wave" then M.data.best_wave = tonumber(v) or 0
		elseif k == "best_depth" then M.data.best_depth = tonumber(v) or 0
		elseif k == "runs" then M.data.runs = tonumber(v) or 0
		elseif k == "wins" then M.data.wins = tonumber(v) or 0
		elseif k == "shards" then M.data.shards = tonumber(v) or 0
		elseif k == "unlock" then M.data.unlocks[v] = true
		elseif k == "version" then M.data.version = tonumber(v) or Config.SAVE_VERSION
		end
	end
	return true
end

function M.save()
	local ok, err = pcall(function()
		local f = io.open(M.SAVE_FILE, "w")
		if not f then error("cannot open " .. M.SAVE_FILE) end
		f:write(M.serialize())
		f:close()
	end)
	if not ok then
		Log.debug("meta save skipped: %s", tostring(err))
	end
	return ok
end

function M.load()
	local ok, err = pcall(function()
		local f = io.open(M.SAVE_FILE, "r")
		if not f then error("no save file") end
		local text = f:read("*a")
		f:close()
		M.deserialize(text)
	end)
	if not ok then
		Log.debug("meta load skipped: %s", tostring(err))
	end
	return ok
end

function M.summary()
	return {
		best_wave = M.data.best_wave,
		best_depth = M.data.best_depth,
		runs = M.data.runs,
		wins = M.data.wins,
		shards = M.data.shards,
	}
end

return M
