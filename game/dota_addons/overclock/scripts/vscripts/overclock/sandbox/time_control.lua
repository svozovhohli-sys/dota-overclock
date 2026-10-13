--[[
	OVERCLOCK :: sandbox/time_control.lua
	Pause / speed / freeze-abilities control for the sandbox and lab.

	Uses the game mode entity: SetGameTimeScale (engine timescale) plus a soft
	pause implemented by freezing all heroes' abilities, because a true server
	pause is not exposed to custom games on live builds.
--]]
local State = require("overclock.core.state")
local Players = require("overclock.core.players")
local Timers = require("overclock.core.timers")
local Events = require("overclock.core.events")
local Log = require("overclock.core.logger")

local M = {}

local VALID_SCALES = { 0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0 }

function M.set_scale(scale)
	scale = tonumber(scale) or 1.0
	scale = math.max(0.05, math.min(10.0, scale))
	State.time.scale = scale
	local ent = GameRules:GetGameModeEntity()
	if ent and ent.SetGameTimeScale then
		ent:SetGameTimeScale(scale)
	end
	Log.info("time scale = %.2f", scale)
	Events.emit("time:scale", scale)
	return scale
end

function M.next_scale()
	local cur = State.time.scale
	for _, s in ipairs(VALID_SCALES) do
		if s > cur + 0.001 then return M.set_scale(s) end
	end
	return M.set_scale(VALID_SCALES[1])
end

-- Soft pause: stop abilities + (visual) notify. Game time keeps running so
-- the player can still look around; true freeze is done by scale=0 too.
function M.set_paused(paused)
	paused = paused and true or false
	if paused and not State.time.paused then
		M._prev_scale = State.time.scale ~= 0 and State.time.scale or 1.0
	end
	State.time.paused = paused
	M.freeze_abilities(paused)
	if paused then
		M.set_scale(0.0)
	else
		M.set_scale(M._prev_scale or 1.0)
		M._prev_scale = nil
	end
	Events.emit("time:paused", State.time.paused)
	Log.info("paused = %s", tostring(State.time.paused))
	return State.time.paused
end

function M.toggle_pause()
	return M.set_paused(not State.time.paused)
end

function M.freeze_abilities(freeze)
	State.time.frozen_abilities = freeze and true or false
	for _, hero in ipairs(Players.all_heroes()) do
		for i = 0, hero:GetAbilityCount() - 1 do
			local ab = hero:GetAbilityByIndex(i)
			if ab then
				ab:SetActivated(not freeze)
			end
		end
	end
	return freeze
end

-- Re-evaluate freeze when new heroes appear (spawner calls this).
function M.reapply()
	if State.time.frozen_abilities then
		M.freeze_abilities(true)
	end
end

function M.step(dt)
	-- Step forward while paused: briefly unpause for dt seconds.
	if not State.time.paused then return false end
	M.freeze_abilities(false)
	M.set_scale(1.0)
	Timers.after(dt or 0.5, function()
		M.freeze_abilities(true)
		M.set_scale(0.0)
	end, "time:step")
	return true
end

function M.status()
	return {
		paused = State.time.paused,
		scale = State.time.scale,
		frozen_abilities = State.time.frozen_abilities,
		valid_scales = VALID_SCALES,
	}
end

function M.reset()
	M.freeze_abilities(false)
	State.time.paused = false
	return M.set_scale(1.0)
end

return M
