--[[
	OVERCLOCK :: metrics/dps.lua
	Rolling DPS meter. Consumes `damage:dealt` events and keeps a sliding
	window per attacker (and per attacker→victim pair). Also tracks burst
	peak and totals for the stats dashboard.
--]]
local Config = require("overclock.core.config")
local State = require("overclock.core.state")
local Events = require("overclock.core.events")
local Util = require("overclock.core.util")
local DamageLog = require("overclock.metrics.damage_log")

local M = {}

M.window = Config.tuning.metrics_window
M.series = {}   -- attacker_index -> { events = { {t, amount} } }
M.peak = {}     -- attacker_index -> peak dps
M.total = {}    -- attacker_index -> total damage
M.last_tick = 0

local function push(index, entry)
	local s = M.series[index]
	if not s then
		s = { events = {} }
		M.series[index] = s
	end
	table.insert(s.events, { t = entry.t, amount = entry.amount })
	M.total[index] = (M.total[index] or 0) + entry.amount
end

local function prune(s, now)
	local cutoff = now - M.window
	while #s.events > 0 and s.events[1].t < cutoff do
		table.remove(s.events, 1)
	end
end

function M.install()
	if not State.metrics.dps_enabled then return end
	Events.subscribe("damage:dealt", function(entry)
		if entry.attacker_index and entry.attacker_index >= 0 then
			push(entry.attacker_index, entry)
		end
	end)
	Events.subscribe("damage:reset", function()
		M.series = {}
		M.peak = {}
		M.total = {}
	end)
end

function M.current(index)
	local s = M.series[index]
	if not s then return 0 end
	local now = GameRules:GetGameTime()
	prune(s, now)
	local sum = 0
	for _, e in ipairs(s.events) do sum = sum + e.amount end
	return sum / M.window
end

-- Called periodically by the stats system to update peaks.
function M.tick()
	local now = GameRules:GetGameTime()
	for index, s in pairs(M.series) do
		prune(s, now)
		local sum = 0
		for _, e in ipairs(s.events) do sum = sum + e.amount end
		local dps = sum / M.window
		if dps > (M.peak[index] or 0) then
			M.peak[index] = dps
		end
	end
	M.last_tick = now
end

function M.snapshot()
	local now = GameRules:GetGameTime()
	local out = {}
	for index, s in pairs(M.series) do
		prune(s, now)
		local sum = 0
		for _, e in ipairs(s.events) do sum = sum + e.amount end
		local ent = EntIndexToHScript and EntIndexToHScript(index) or nil
		local name = (ent and IsValidEntity(ent)) and ent:GetUnitName() or "?"
		table.insert(out, {
			index = index,
			name = name,
			dps = sum / M.window,
			peak = M.peak[index] or 0,
			total = M.total[index] or 0,
		})
	end
	table.sort(out, function(a, b) return a.dps > b.dps end)
	return out
end

function M.reset()
	M.series = {}
	M.peak = {}
	M.total = {}
	DamageLog.reset()
end

return M
