--[[
	OVERCLOCK :: addon_game_mode.lua
	Custom game entry point. Loads the OC framework, wires all subsystems, and
	defines the global Activate()/GameMode that Dota calls on load.
--]]
require("overclock")

if OC == nil then
	print("[OVERCLOCK][FATAL] framework failed to load; aborting")
	return
end

GameMode = class({})

local Config = OC.Core.Config
local Log = OC.Core.Logger
local State = OC.Core.State
local Events = OC.Core.Events
local Commands = OC.Core.Commands
local Players = OC.Core.Players
local Spawner = OC.Sandbox.Spawner
local DamageLog = OC.Metrics.DamageLog
local Dps = OC.Metrics.Dps
local Ttk = OC.Metrics.Ttk
local PatchLab = OC.Patch.Lab
local Run = OC.Roguelike.Run
local Bridge = OC.UI.Bridge

local TICK_PERIOD = Config.tuning.tick_interval
local last_autosave = 0

function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end

function GameMode:InitGameMode()
	Log.info("=== OVERCLOCK v%s booting ===", Config.VERSION)

	-- base game-mode flags --------------------------------------------------
	local gm = GameRules:GetGameModeEntity()
	gm:SetAnnouncerDisabled(true)
	gm:SetWeatherEffectsDisabled(true)
	gm:SetFixedRespawnTime(3)
	gm:SetCustomGameForceHero("npc_dota_hero_axe")
	GameRules:SetPreGameTime(0)
	GameRules:SetStrategyTime(0)
	GameRules:SetShowcaseTime(0)
	GameRules:SetStartingGold(600)
	GameRules:SetGoldPerTick(0)
	GameRules:SetUseUniversalShopMode(true)
	GameRules:SetSameHeroSelectionEnabled(true)
	GameRules:SetHeroRespawnEnabled(true)

	-- subsystems ------------------------------------------------------------
	if Config.is_feature("modifiers") then
		OC.Modifiers.Registry.load_all()
	end
	Spawner.precache()
	if Config.is_feature("metrics") then
		DamageLog.install()
		Dps.install()
		Ttk.install()
	end
	if Config.is_feature("patch_lab") then
		PatchLab.load_all()
	end
	if Config.is_feature("roguelike") then
		Run.install()
	end
	OC.Data.Tunables.install(OC.Core.Params)
	Bridge.install()

	self:RegisterEvents()
	self:StartThink()

	Log.info("boot complete (mode=%s)", State.mode)
end

function GameMode:RegisterEvents()
	local function on_player_connect(_, data)
		local pid = data.PlayerID or data.playerid
		if pid == nil then return end
		Players.register(pid)
		Bridge.notify(pid, "Добро пожаловать в OVERCLOCK v" .. Config.VERSION)
	end

	Events.on("player_connect_full", on_player_connect)
	Events.on("player_activate", function(data)
		local pid = data.PlayerID or data.playerid
		if pid ~= nil then
			Players.register(pid)
			Bridge.push(pid, "oc_state", State.snapshot())
		end
	end)

	Events.on("npc_spawned", function(data)
		local ent = EntIndexToHScript and EntIndexToHScript(data.entindex) or nil
		if ent and ent:IsRealHero() then
			local pid = ent:GetPlayerID()
			if pid then Players.register(pid, { hero = ent }) end
		end
	end)

	Events.on("entity_killed", function(data)
		local ent = EntIndexToHScript and EntIndexToHScript(data.entindex_killed) or nil
		if ent and ent:IsRealHero() then
			Events.emit("hero:death", { hero = ent })
		end
	end)

	-- chat commands ---------------------------------------------------------
	Events.on("player_chat", function(data)
		local text = data.text or ""
		local pid = data.playerid or data.PlayerID
		if text:sub(1, 1) == "!" or text:sub(1, 1) == "-" then
			Commands.run_from(pid, text:sub(2), "chat")
		end
	end)
end

function GameMode:StartThink()
	local gm = GameRules:GetGameModeEntity()
	gm:SetThink("OCTick", function()
		local ok, err = pcall(function()
			if Config.is_feature("metrics") then
				Dps.tick()
			end
			local now = GameRules:GetGameTime()
			if now - last_autosave >= Config.tuning.auto_save_interval then
				last_autosave = now
				OC.Roguelike.Meta.save()
			end
		end)
		if not ok then
			Log.error("tick: %s", tostring(err))
		end
		return TICK_PERIOD
	end, GameRules:GetGameTime(), TICK_PERIOD)
end

-- Convenience dev entry points callable from the console.
function OCSpawn(name) return Spawner.spawn_unit(name, Vector(0, 0, 128), {}) end
function OCClear() return Spawner.clear(false) end
function OCState() return State.snapshot() end
