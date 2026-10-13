--[[
	OVERCLOCK :: init.lua
	Loads every subsystem in dependency order and exposes them on the global
	`OC` table. addon_game_mode.lua only needs to require("overclock").

	Layout:
		OC.Core.*        - infrastructure
		OC.Sandbox.*     - spawn / control
		OC.Modifiers.*   - modifier engine + registry
		OC.Metrics.*     - dps, damage log, ttk, ehp
		OC.Patch.*       - patch lab
		OC.Roguelike.*   - run, curses, waves, shop, meta
		OC.UI.*          - bridge to Panorama
--]]

OC = OC or {}

local function req(path)
	local ok, mod = pcall(require, path)
	if not ok then
		print(string.format("[OVERCLOCK][FATAL] failed to load %s: %s",
			path, tostring(mod)))
		return nil
	end
	return mod
end

-- infrastructure -------------------------------------------------------------
OC.Core = OC.Core or {}
OC.Core.Util = req("overclock.core.util")
OC.Core.Logger = req("overclock.core.logger")
OC.Core.Config = req("overclock.core.config")
OC.Core.State = req("overclock.core.state")
OC.Core.Events = req("overclock.core.events")
OC.Core.Timers = req("overclock.core.timers")
OC.Core.Commands = req("overclock.core.commands")
OC.Core.Players = req("overclock.core.players")
OC.Core.Params = req("overclock.core.params")
OC.Core.Convars = req("overclock.core.convars")

-- data -----------------------------------------------------------------------
OC.Data = OC.Data or {}
OC.Data.Tunables = req("overclock.data.tunables")

-- rules (game-wide tuning: GameRules/GameMode/ConVars + entity stats) ---------
OC.Rules = OC.Rules or {}
OC.Rules.Manager = req("overclock.rules.manager")

-- mechanics (combat mechanic lab) --------------------------------------------
OC.Mechanics = OC.Mechanics or {}
OC.Mechanics.Manager = req("overclock.mechanics.manager")

-- abilities (capability browser) ---------------------------------------------
OC.Abilities = OC.Abilities or {}
OC.Abilities.Browser = req("overclock.abilities.browser")

-- sandbox --------------------------------------------------------------------
OC.Sandbox = OC.Sandbox or {}
OC.Sandbox.Spawner = req("overclock.sandbox.spawner")
OC.Sandbox.HeroControl = req("overclock.sandbox.hero_control")
OC.Sandbox.TimeControl = req("overclock.sandbox.time_control")
OC.Sandbox.Camera = req("overclock.sandbox.camera")
OC.Sandbox.Items = req("overclock.sandbox.items")

-- modifiers ------------------------------------------------------------------
OC.Modifiers = OC.Modifiers or {}
OC.Modifiers.Registry = req("overclock.modifiers.registry")
OC.Modifiers.Engine = req("overclock.modifiers.engine")

-- metrics --------------------------------------------------------------------
OC.Metrics = OC.Metrics or {}
OC.Metrics.DamageLog = req("overclock.metrics.damage_log")
OC.Metrics.Dps = req("overclock.metrics.dps")
OC.Metrics.Ttk = req("overclock.metrics.ttk")
OC.Metrics.Ehp = req("overclock.metrics.ehp")

-- patch lab ------------------------------------------------------------------
OC.Patch = OC.Patch or {}
OC.Patch.Lab = req("overclock.patch.patch_lab")
OC.Patch.Sets = req("overclock.patch.patch_sets")

-- roguelike ------------------------------------------------------------------
OC.Roguelike = OC.Roguelike or {}
OC.Roguelike.Meta = req("overclock.roguelike.meta")
OC.Roguelike.Curses = req("overclock.roguelike.curses")
OC.Roguelike.Waves = req("overclock.roguelike.waves")
OC.Roguelike.Shop = req("overclock.roguelike.shop")
OC.Roguelike.Rewards = req("overclock.roguelike.rewards")
OC.Roguelike.Run = req("overclock.roguelike.run")

-- ui -------------------------------------------------------------------------
OC.UI = OC.UI or {}
OC.UI.Bridge = req("overclock.ui.bridge")

OC.VERSION = (OC.Core.Config and OC.Core.Config.VERSION) or "0.0.0"

if OC.Core.Logger then
	local n = 0
	for _, group in pairs(OC) do
		if type(group) == "table" then
			for _ in pairs(group) do n = n + 1 end
		end
	end
	OC.Core.Logger.info("OVERCLOCK v%s loaded (%d modules)", OC.VERSION, n)
end

return OC
