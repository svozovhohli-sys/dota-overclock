--[[
	OVERCLOCK :: ui/bridge.lua
	The only module that talks to Panorama. It:
	  * listens for custom game events sent from the JS UI,
	  * registers the OC command set (also usable from chat/console),
	  * pushes state snapshots back to players / to a net table.

	Event names (client -> server via GameEvents):
		oc_cmd           { raw = "spawn creep_x" }
		oc_action        { action = "run_curse", id = "frailty" }
		oc_request_state {}

	Server -> client:
		oc_state         (full snapshot)
		oc_notify        { kind, text }
--]]
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")
local Config = require("overclock.core.config")
local State = require("overclock.core.state")
local Commands = require("overclock.core.commands")
local Players = require("overclock.core.players")
local Spawner = require("overclock.sandbox.spawner")

local M = {}

M.installed = false
M.listener = nil

-- ---------------------------------------------------------------------------
-- push helpers
-- ---------------------------------------------------------------------------

function M.push(pid, event_name, payload)
	if not CustomGameEventManager then return end
	local ok, err = pcall(function()
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(pid),
			event_name, payload or {})
	end)
	if not ok then
		Log.debug("push %s to %d failed: %s", event_name, pid, tostring(err))
	end
end

function M.push_all(event_name, payload)
	for _, pid in ipairs(Players.active_player_ids()) do
		M.push(pid, event_name, payload)
	end
end

function M.notify(pid, text, kind)
	M.push(pid, "oc_notify", { text = tostring(text), kind = kind or "info" })
end

-- Push the full live-parameter list (values resolved for this player).
function M.push_params(pid)
	local Params = require("overclock.core.params")
	M.push(pid, "oc_params", { params = Params.list({ pid = pid }) })
end

-- Broadcast a full state snapshot (UI redraws from this).
function M.broadcast_state()
	State = require("overclock.core.state")
	local OCCore = _G.OC
	local payload = State.snapshot()
	if OCCore and OCCore.Roguelike and OCCore.Roguelike.Run then
		payload.run = OCCore.Roguelike.Run.view(State.run)
	end
	if OCCore and OCCore.Patch and OCCore.Patch.Lab then
		payload.active_patch = OCCore.Patch.Lab.active()
	end
	M.push_all("oc_state", payload)
	return payload
end

-- ---------------------------------------------------------------------------
-- structured actions
-- ---------------------------------------------------------------------------

local actions = {}

actions.set_mode = function(pid, id)
	State.set_mode(id)
	M.broadcast_state()
	return true
end

actions.spawn_unit = function(pid, id)
	local hero = Players.hero_of(pid)
	local pos = hero and (hero:GetAbsOrigin() + Vector(200, 0, 0)) or Vector(0, 0, 128)
	Spawner.spawn_unit(id, pos, {})
	M.broadcast_state()
	return true
end

actions.spawn_hero = function(pid, id)
	local hero = Players.hero_of(pid)
	local pos = hero and (hero:GetAbsOrigin() + Vector(300, 0, 0)) or Vector(0, 0, 128)
	Spawner.spawn_unit(id, pos, { team = Config.TEAM.PLAYERS })
	M.broadcast_state()
	return true
end

actions.spawn_dummy = function(pid)
	local hero = Players.hero_of(pid)
	local pos = hero and (hero:GetAbsOrigin() + Vector(400, 0, 0)) or Vector(0, 0, 128)
	Spawner.spawn_dummy(pos, {})
	M.broadcast_state()
	return true
end

actions.clear = function(pid)
	Spawner.clear(false)
	M.broadcast_state()
	return true
end

actions.time_pause = function(pid, value)
	local TC = _G.OC and _G.OC.Sandbox and _G.OC.Sandbox.TimeControl
	if TC then TC.set_paused(value == "1" or value == true) end
	M.broadcast_state()
	return true
end

actions.run_start = function(pid)
	local Run = _G.OC and _G.OC.Roguelike and _G.OC.Roguelike.Run
	if not Run then return false, "roguelike off" end
	Run.install()
	local run = Run.start(pid)
	M.broadcast_state()
	return run ~= nil
end

actions.run_curse = function(pid, id)
	local Run = _G.OC and _G.OC.Roguelike and _G.OC.Roguelike.Run
	if Run then Run.choose_curse(State.run, id) end
	M.broadcast_state()
	return true
end

actions.run_reward = function(pid, id)
	local Run = _G.OC and _G.OC.Roguelike and _G.OC.Roguelike.Run
	if Run then Run.choose_reward(State.run, id) end
	M.broadcast_state()
	return true
end

actions.run_buy = function(pid, id)
	local Run = _G.OC and _G.OC.Roguelike and _G.OC.Roguelike.Run
	if Run then Run.buy(State.run, id) end
	M.broadcast_state()
	return true
end

actions.run_next = function(pid)
	local Run = _G.OC and _G.OC.Roguelike and _G.OC.Roguelike.Run
	if Run then Run.next_wave(State.run) end
	M.broadcast_state()
	return true
end

actions.run_abort = function(pid)
	local Run = _G.OC and _G.OC.Roguelike and _G.OC.Roguelike.Run
	if Run then Run.abort() end
	M.broadcast_state()
	return true
end

actions.patch_apply = function(pid, id)
	local Lab = _G.OC and _G.OC.Patch and _G.OC.Patch.Lab
	if not Lab then return false, "patch lab off" end
	local hero = Players.hero_of(pid)
	Lab.apply_set(id, hero)
	M.broadcast_state()
	return true
end

actions.patch_clear = function(pid)
	local Lab = _G.OC and _G.OC.Patch and _G.OC.Patch.Lab
	if Lab then Lab.clear() end
	M.broadcast_state()
	return true
end

actions.patch_benchmark = function(pid, label)
	local Lab = _G.OC and _G.OC.Patch and _G.OC.Patch.Lab
	if Lab then Lab.mark_benchmark(label) end
	M.broadcast_state()
	return true
end

actions.stats = function(pid)
	M.push(pid, "oc_stats", require("overclock.metrics.dps").snapshot())
	return true
end

-- live parameter panel ------------------------------------------------------

actions.param_get = function(pid)
	M.push_params(pid)
	return true
end

actions.param_set = function(pid, id, data)
	local Params = require("overclock.core.params")
	local ok, v = Params.set(id, data and data.value, { pid = pid })
	M.push_params(pid)
	return ok, v
end

actions.param_invoke = function(pid, id)
	local Params = require("overclock.core.params")
	Params.invoke(id, { pid = pid })
	M.push_params(pid)
	M.broadcast_state()
	return true
end

function M.handle_action(pid, action, id, data)
	local fn = actions[action]
	if not fn then
		Log.warn("unknown UI action: %s", tostring(action))
		return false, "unknown action"
	end
	local ok, res = pcall(fn, pid, id, data)
	if not ok then
		Log.error("UI action %s failed: %s", tostring(action), tostring(res))
		return false, tostring(res)
	end
	return res
end

-- ---------------------------------------------------------------------------
-- commands (available from chat + UI + console)
-- ---------------------------------------------------------------------------

local function register_commands()
	if M._cmds_done then return end
	M._cmds_done = true

	Commands.register("help", {
		help = "список команд", usage = "help", section = "general",
		run = function(ctx)
			return true, Commands.describe()
		end,
	})
	Commands.register("mode", {
		help = "переключить режим (sandbox|lab|roguelike)",
		usage = "mode <sandbox|lab|roguelike>", section = "general",
		run = function(ctx)
			local m = ctx.args[1]
			if not m then return false, "укажи режим" end
			State.set_mode(m)
			M.broadcast_state()
			return true, m
		end,
	})
	Commands.register("spawn", {
		help = "заспавнить юнита/героя по имени",
		usage = "spawn <npc_name>", section = "sandbox",
		run = function(ctx)
			local name = ctx.args[1]
			if not name then return false, "укажи npc_name" end
			local hero = Players.hero_of(ctx.pid)
			local pos = hero and (hero:GetAbsOrigin() + Vector(200, 0, 0)) or Vector(0, 0, 128)
			local u = Spawner.spawn_unit(name, pos, {})
			M.broadcast_state()
			return u ~= nil, name
		end,
	})
	Commands.register("dummy", {
		help = "создать тренировочный манекен",
		usage = "dummy [hp] [armor]", section = "sandbox",
		run = function(ctx)
			local hero = Players.hero_of(ctx.pid)
			local pos = hero and (hero:GetAbsOrigin() + Vector(400, 0, 0)) or Vector(0, 0, 128)
			local d = Spawner.spawn_dummy(pos, {
				hp = tonumber(ctx.args[1]),
				armor = tonumber(ctx.args[2]),
			})
			M.broadcast_state()
			return d ~= nil
		end,
	})
	Commands.register("clear", {
		help = "убрать всё заспавненное", usage = "clear", section = "sandbox",
		run = function(ctx)
			local n = Spawner.clear(false)
			M.broadcast_state()
			return true, n
		end,
	})
	Commands.register("run", {
		help = "роглайк: старт забега", usage = "run [seed]", section = "roguelike",
		run = function(ctx)
			local Run = _G.OC.Roguelike.Run
			Run.install()
			local r = Run.start(ctx.pid, tonumber(ctx.args[1]))
			M.broadcast_state()
			return r ~= nil
		end,
	})
	Commands.register("next", {
		help = "роглайк: следующая волна", usage = "next", section = "roguelike",
		run = function(ctx)
			local ok = _G.OC.Roguelike.Run.next_wave(State.run)
			M.broadcast_state()
			return ok
		end,
	})
	Commands.register("patch", {
		help = "лаб: применить набор правок", usage = "patch <id|clear>", section = "lab",
		run = function(ctx)
			local Lab = _G.OC.Patch.Lab
			local id = ctx.args[1]
			if id == "clear" then Lab.clear()
			else Lab.apply_set(id, Players.hero_of(ctx.pid)) end
			M.broadcast_state()
			return true
		end,
	})
	Commands.register("stats", {
		help = "показать DPS-метрики", usage = "stats", section = "metrics",
		run = function(ctx)
			local snap = require("overclock.metrics.dps").snapshot()
			M.push(ctx.pid, "oc_stats", snap)
			return true, snap
		end,
	})
	Commands.register("params", {
		help = "список живых параметров", usage = "params", section = "params",
		run = function(ctx)
			M.push_params(ctx.pid)
			return true, require("overclock.core.params").list({ pid = ctx.pid })
		end,
	})
	Commands.register("set", {
		help = "изменить живой параметр", usage = "set <id> <value>", section = "params",
		run = function(ctx)
			local id, val = ctx.args[1], ctx.args[2]
			if not id then return false, "укажи id параметра" end
			local ok, res = require("overclock.core.params").set(id, val, { pid = ctx.pid })
			M.push_params(ctx.pid)
			M.broadcast_state()
			return ok, res
		end,
	})
end

-- ---------------------------------------------------------------------------
-- install
-- ---------------------------------------------------------------------------

function M.install()
	if M.installed then return end
	if not CustomGameEventManager then
		Log.warn("CustomGameEventManager missing; UI bridge disabled")
		return
	end
	register_commands()

	CustomGameEventManager:RegisterListener("oc_cmd", function(_, data)
		local pid = data.PlayerID or data.playerid
		if pid ~= nil then
			Commands.run_from(pid, data.raw or "", "ui")
		end
	end)

	CustomGameEventManager:RegisterListener("oc_action", function(_, data)
		local pid = data.PlayerID or data.playerid
		if pid ~= nil then
			M.handle_action(pid, data.action, data.id, data)
		end
	end)

	CustomGameEventManager:RegisterListener("oc_request_state", function(_, data)
		local pid = data.PlayerID or data.playerid
		if pid ~= nil then
			local payload = State.snapshot()
			payload.run = _G.OC.Roguelike.Run.view(State.run)
			M.push(pid, "oc_state", payload)
			M.push_params(pid)
		end
	end)

	M.installed = true
	Log.info("UI bridge installed (%d commands)", Commands.count())
end

function M.command_list()
	return Commands.describe()
end

return M
