--[[
	OVERCLOCK :: core/state.lua
	Single mutable runtime-state store. Everything that changes while the
	game runs lives here (mode, players, registries, run, metrics controls).
--]]
local Config = require("overclock.core.config")

local M = {}

-- Current top-level mode.
M.mode = Config.default_mode

-- Per-player info keyed by PlayerID.
--   [pid] = { pid, hero, name, ready, team, sandbox = {...} }
M.players = {}

-- Entity registries maintained by the sandbox spawner.
M.spawned = {}          -- entity index -> record
M.dummies = {}          -- entity index -> true (metric targets)
M.heroes = {}           -- entity index -> hero

-- Time control.
M.time = {
	paused = false,
	scale = 1.0,
	frozen_abilities = false,
}

-- Roguelike run (nil unless a run is active). Owned by roguelike/run.lua.
M.run = nil

-- Metrics toggles.
M.metrics = {
	dps_enabled = true,
	damage_log_enabled = true,
	ttk_enabled = true,
	ehp_enabled = true,
}

-- Free-camera / debug.
M.debug = {
	free_camera = false,
	show_bounds = false,
}

-- Active patch set id (patch lab).
M.active_patch = nil

function M.get_player(pid)
	return M.players[pid]
end

function M.each_player(fn)
	for pid, rec in pairs(M.players) do
		fn(rec, pid)
	end
end

function M.set_mode(mode)
	M.mode = mode
end

function M.reset_round_state()
	M.spawned = {}
	M.dummies = {}
end

function M.snapshot()
	-- Lightweight summary for the UI status bar.
	return {
		mode = M.mode,
		paused = M.time.paused,
		scale = M.time.scale,
		players = (function()
			local n = 0
			for _ in pairs(M.players) do n = n + 1 end
			return n
		end)(),
		spawned = (function()
			local n = 0
			for _ in pairs(M.spawned) do n = n + 1 end
			return n
		end)(),
		run = M.run and {
			active = true,
			wave = M.run.wave,
			seed = M.run.seed,
		} or { active = false },
	}
end

return M
