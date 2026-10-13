--[[
	OVERCLOCK :: roguelike/run.lua
	The run state machine. Owns State.run and drives the loop:

		curse -> fight -> reward -> shop -> (next wave) curse -> ...

	Only one run may be active at a time. The UI (ui/bridge.lua) calls the
	`choose_*` / `next_wave` methods; everything else reacts through events.
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")
local State = require("overclock.core.state")
local Events = require("overclock.core.events")
local Timers = require("overclock.core.timers")
local Players = require("overclock.core.players")

local Curses = require("overclock.roguelike.curses")
local Waves = require("overclock.roguelike.waves")
local Shop = require("overclock.roguelike.shop")
local Rewards = require("overclock.roguelike.rewards")
local Meta = require("overclock.roguelike.meta")
local Spawner = require("overclock.sandbox.spawner")

local M = {}

M.installed = false

function M.install()
	if M.installed then return end
	M.installed = true

	Events.subscribe("roguelike:wave_cleared", function(payload)
		local run = payload.run
		if run ~= State.run or not run.active then return end
		run.depth = run.depth + 1
		run.gold = run.gold + 15 + run.depth
		run.pending_rewards = Rewards.roll(run, 3)
		run.status = "reward"
		Log.info("wave %d cleared (depth %d, gold %d)", run.wave, run.depth, run.gold)
		Events.emit("roguelike:state_changed", M.view(run))
	end)

	Events.on("entity_killed", function(data)
		local run = State.run
		if not run or not run.active or not run.hero then return end
		local victim = EntIndexToHScript and EntIndexToHScript(data.entindex_killed) or nil
		if victim == run.hero then
			M.finish("death")
		end
	end)
end

function M.active()
	return State.run
end

function M.start(pid, seed)
	if State.run and State.run.active then
		Log.warn("run already active")
		return nil
	end
	local hero = Players.hero_of(pid)
	if not hero then
		Log.warn("cannot start run: no hero for player %d", pid)
		return nil
	end

	seed = seed or os.time()
	Util.set_seed(seed)
	Meta.load()

	local run = {
		active = true,
		pid = pid,
		hero = hero,
		seed = seed,
		wave = 1,
		depth = 0,
		gold = 0,
		curses = {},
		rewards = {},
		enemies_alive = 0,
		status = "curse",
		pending_curses = {},
		pending_rewards = {},
		started_at = GameRules:GetGameTime(),
	}
	State.run = run

	Waves.install()
	run.pending_curses = Curses.roll(run, 3)
	Events.emit("roguelike:started", M.view(run))
	Log.info("run started (pid %d, seed %d)", pid, seed)
	return run
end

function M.choose_curse(run, curse_id)
	if not run or run.status ~= "curse" then return false end
	if not Curses.apply(run, curse_id) then return false end
	Waves.spawn(run, run.wave)
	run.pending_curses = {}
	Events.emit("roguelike:state_changed", M.view(run))
	return true
end

function M.choose_reward(run, reward_id)
	if not run or run.status ~= "reward" then return false end
	Rewards.grant(run, reward_id)
	run.pending_rewards = {}
	Shop.open(run)
	Events.emit("roguelike:state_changed", M.view(run))
	return true
end

function M.buy(run, item_id)
	if not run or run.status ~= "shop" then return false, "not_in_shop" end
	local ok, reason = Shop.buy(run, item_id)
	Events.emit("roguelike:state_changed", M.view(run))
	return ok, reason
end

function M.next_wave(run)
	if not run or not run.active then return false end
	if run.status ~= "shop" and run.status ~= "prep" then return false end
	Shop.close(run)
	run.wave = run.wave + 1
	run.pending_curses = Curses.roll(run, 3)
	run.status = "curse"
	Events.emit("roguelike:state_changed", M.view(run))
	return true
end

function M.finish(reason)
	local run = State.run
	if not run then return false end
	run.active = false
	run.ended_at = GameRules:GetGameTime()
	local gained = Meta.record_run(run)
	Meta.save()
	Events.emit("roguelike:finished", { run = run, reason = reason or "manual", shards = gained })
	Log.info("run finished (%s), +%d shards", tostring(reason), gained)
	State.run = nil
	return true
end

function M.abort()
	return M.finish("abort")
end

-- Serialisable view for the Panorama UI.
function M.view(run)
	run = run or State.run
	if not run then return { active = false } end
	return {
		active = run.active,
		status = run.status,
		wave = run.wave,
		depth = run.depth,
		gold = run.gold,
		enemies_alive = run.enemies_alive,
		hero = run.hero and run.hero:GetUnitName() or "?",
		seed = run.seed,
		curses = Curses.list(run),
		pending_curses = run.pending_curses,
		pending_rewards = run.pending_rewards,
		shop = Shop.list(run),
		meta = Meta.summary(),
	}
end

return M
