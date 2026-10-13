--[[
	OVERCLOCK :: core/timers.lua
	Thin wrapper around Dota's global `Timers` object that adds:
	  * named timers (so a system can restart/cancel "its" timer)
	  * safe callbacks (pcall, logged)
	  * pause-awareness stub (time control module can freeze scheduling)
--]]
local M = {}

M.named = {}          -- name -> handle
M.paused = false
M.deferred = {}       -- functions queued while paused

function M.after(delay, fn, label)
	local handle
	handle = Timers:CreateTimer(delay, function()
		if M.paused then
			-- re-check later; keeps ordering once unpaused
			return 0.1
		end
		local ok, err = pcall(fn)
		if not ok then
			print(string.format("[OVERCLOCK][ERROR] timer '%s': %s",
				tostring(label or "?"), tostring(err)))
		end
		return nil
	end)
	return handle
end

-- Repeating timer; fn returns false to stop early.
function M.every(period, fn, label)
	local handle
	local function tick()
		if M.paused then return 0.1 end
		local ok, stop = pcall(fn)
		if not ok then
			print(string.format("[OVERCLOCK][ERROR] every '%s': %s",
				tostring(label or "?"), tostring(stop)))
			return nil
		end
		if stop == false then return nil end
		return period
	end
	handle = Timers:CreateTimer(period, tick)
	return handle
end

function M.after_named(name, delay, fn)
	M.cancel_named(name)
	M.named[name] = M.after(delay, function()
		M.named[name] = nil
		fn()
	end, name)
	return M.named[name]
end

function M.every_named(name, period, fn)
	M.cancel_named(name)
	M.named[name] = M.every(period, fn, name)
	return M.named[name]
end

function M.cancel(handle)
	if handle then Timers:RemoveTimer(handle) end
end

function M.cancel_named(name)
	if M.named[name] then
		Timers:RemoveTimer(M.named[name])
		M.named[name] = nil
	end
end

function M.cancel_all()
	for name in pairs(M.named) do
		M.cancel_named(name)
	end
end

-- ---------------------------------------------------------------------------
-- pause support (used by the time-control sandbox module)
-- ---------------------------------------------------------------------------

function M.set_paused(paused)
	M.paused = paused and true or false
end

function M.is_paused()
	return M.paused
end

return M
