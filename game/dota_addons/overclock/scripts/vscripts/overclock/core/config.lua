--[[
	OVERCLOCK :: core/config.lua
	Static configuration + feature flags + tuning constants.
	Kept separate from mutable runtime state (see core/state.lua).
--]]
local Util = require("overclock.core.util")

local M = {}

M.VERSION = "1.0.0"
M.ADDON_NAME = "overclock"

-- Gameplay modes the hub can switch between.
M.MODE = {
	SANDBOX = "sandbox",
	ROGUELIKE = "roguelike",
	LAB = "lab",
}

-- Default mode on load.
M.default_mode = M.MODE.SANDBOX

-- Feature flags (turn heavy subsystems on/off without deleting code).
M.features = {
	metrics = true,
	modifiers = true,
	patch_lab = true,
	roguelike = true,
	free_camera = true,
	time_control = true,
	debug_overlay = true,
}

-- Teams used by the sandbox.
M.TEAM = {
	PLAYERS = DOTA_TEAM_GOODGUYS or 2,
	ENEMIES = DOTA_TEAM_BADGUYS or 3,
	NEUTRALS = DOTA_TEAM_NEUTRALS or 4,
}

-- The dummy target unit used by metrics/patch lab.
M.DUMMY_UNIT = "npc_oc_dummy"

-- Tuning defaults (infra only; gameplay tuning lives in data/ tables).
M.tuning = {
	metrics_window = 6.0,        -- seconds for rolling DPS
	damage_log_cap = 2000,       -- max stored damage events
	tick_interval = 0.25,        -- general system think period
	auto_save_interval = 30.0,   -- meta save cadence (seconds)
	combo_gap = 0.6,             -- default gap between queued abilities

	-- Roguelike difficulty scaling multipliers (live-tunable via params panel).
	rogue_hp_scale = 1.0,
	rogue_dmg_scale = 1.0,
	rogue_count_scale = 1.0,
}

-- Meta progression schema version (bump to migrate saves).
M.SAVE_VERSION = 1

function M.is_feature(name)
	return M.features[name] == true
end

-- Deep copy so callers cannot mutate the master defaults.
function M.defaults()
	return Util.deep_copy(M.tuning)
end

return M
