--[[
	OVERCLOCK :: data/tunables.lua
	Registers every parameter exposed by the in-game "Параметры" panel. Each
	entry binds a label + control metadata to live get/set closures, so the UI
	needs zero knowledge of the subsystems behind them.

	install(Params) is called once at boot (after all subsystems exist).
--]]
local State = require("overclock.core.state")
local Config = require("overclock.core.config")
local Logger = require("overclock.core.logger")
local Players = require("overclock.core.players")

local TimeControl = require("overclock.sandbox.time_control")
local Camera = require("overclock.sandbox.camera")
local HeroControl = require("overclock.sandbox.hero_control")
local Items = require("overclock.sandbox.items")
local Spawner = require("overclock.sandbox.spawner")

local Dps = require("overclock.metrics.dps")
local Waves = require("overclock.roguelike.waves")
local Run = require("overclock.roguelike.run")

local M = {}

local function hero_of(ctx)
	if ctx and ctx.pid ~= nil then
		return Players.hero_of(ctx.pid)
	end
	return nil
end

local function log_level_name()
	for name, lvl in pairs(Logger.LEVELS) do
		if lvl == Logger.level then return name:lower() end
	end
	return "debug"
end

function M.install(Params)
	if not Params then return 0 end

	-- time ---------------------------------------------------------------
	Params.register({
		id = "time_paused", label = "Пауза", section = "Время", type = "bool",
		get = function() return State.time.paused end,
		set = function(v) TimeControl.set_paused(v) end,
	})
	Params.register({
		id = "time_scale", label = "Скорость времени", section = "Время",
		type = "number", min = 0.05, max = 5.0, step = 0.05, unit = "x",
		get = function() return State.time.scale end,
		set = function(v) TimeControl.set_scale(v) end,
	})
	Params.register({
		id = "freeze_abilities", label = "Заморозить способности", section = "Время",
		type = "bool",
		get = function() return State.time.frozen_abilities end,
		set = function(v) TimeControl.freeze_abilities(v) end,
	})

	-- metrics ------------------------------------------------------------
	Params.register({
		id = "metrics_dps", label = "DPS-метр", section = "Метрики", type = "bool",
		get = function() return State.metrics.dps_enabled end,
		set = function(v) State.metrics.dps_enabled = v end,
	})
	Params.register({
		id = "metrics_damage_log", label = "Лог урона", section = "Метрики", type = "bool",
		get = function() return State.metrics.damage_log_enabled end,
		set = function(v) State.metrics.damage_log_enabled = v end,
	})
	Params.register({
		id = "metrics_ttk", label = "Подсчёт TTK", section = "Метрики", type = "bool",
		get = function() return State.metrics.ttk_enabled end,
		set = function(v) State.metrics.ttk_enabled = v end,
	})
	Params.register({
		id = "metrics_window", label = "Окно DPS", section = "Метрики",
		type = "number", min = 1.0, max = 20.0, step = 0.5, unit = "с",
		get = function() return Config.tuning.metrics_window end,
		set = function(v) Config.tuning.metrics_window = v; Dps.window = v end,
	})

	-- sandbox ------------------------------------------------------------
	Params.register({
		id = "sandbox_dummy_hp", label = "HP манекена", section = "Песочница",
		type = "number", min = 100, max = 500000, step = 100,
		get = function() return State.sandbox.dummy_hp end,
		set = function(v) State.sandbox.dummy_hp = v end,
	})
	Params.register({
		id = "sandbox_dummy_armor", label = "Броня манекена", section = "Песочница",
		type = "number", min = -100, max = 200, step = 5,
		get = function() return State.sandbox.dummy_armor end,
		set = function(v) State.sandbox.dummy_armor = v end,
	})
	Params.register({
		id = "sandbox_spawn_dummy", label = "Создать манекен", section = "Песочница",
		type = "action",
		run = function(ctx)
			local hero = hero_of(ctx)
			local pos = hero and (hero:GetAbsOrigin() + Vector(400, 0, 0)) or Vector(0, 0, 128)
			Spawner.spawn_dummy(pos, {})
		end,
	})
	Params.register({
		id = "sandbox_clear", label = "Убрать всё заспавненное", section = "Песочница",
		type = "action",
		run = function() Spawner.clear(false) end,
	})

	-- hero (per caller) --------------------------------------------------
	Params.register({
		id = "hero_level", label = "Уровень героя", section = "Герой",
		type = "number", min = 1, max = 30, step = 1,
		get = function(ctx)
			local h = hero_of(ctx); return h and h:GetLevel() or nil
		end,
		set = function(v, ctx)
			local h = hero_of(ctx); if h then HeroControl.set_level(h, v) end
		end,
	})
	Params.register({
		id = "hero_aghs", label = "Аганимы (Scepter)", section = "Герой", type = "bool",
		get = function(ctx) local h = hero_of(ctx); return h and h:HasScepter() or nil end,
		set = function(v, ctx)
			local h = hero_of(ctx); if h then HeroControl.set_aghs(h, v) end
		end,
	})
	Params.register({
		id = "hero_shard", label = "Шард", section = "Герой", type = "bool",
		get = function(ctx) local h = hero_of(ctx); return h and h:HasShard() or nil end,
		set = function(v, ctx)
			local h = hero_of(ctx); if h then HeroControl.set_shard(h, v) end
		end,
	})
	Params.register({
		id = "hero_invulnerable", label = "Бессмертие", section = "Герой", type = "bool",
		get = function(ctx) local h = hero_of(ctx); return h and h:IsInvulnerable() or nil end,
		set = function(v, ctx)
			local h = hero_of(ctx); if h then HeroControl.set_invulnerable(h, v) end
		end,
	})
	Params.register({
		id = "hero_max_level", label = "Макс. уровень + все способности", section = "Герой",
		type = "action",
		run = function(ctx)
			local h = hero_of(ctx); if h then HeroControl.max_level_everything(h) end
		end,
	})
	Params.register({
		id = "hero_give_bench", label = "Выдать набор предметов", section = "Герой",
		type = "action",
		run = function(ctx)
			local h = hero_of(ctx); if h then Items.give_bench(h) end
		end,
	})
	Params.register({
		id = "hero_clear_items", label = "Убрать предметы", section = "Герой",
		type = "action",
		run = function(ctx)
			local h = hero_of(ctx); if h then Items.clear(h) end
		end,
	})
	Params.register({
		id = "hero_respawn", label = "Возродить героя", section = "Герой",
		type = "action",
		run = function(ctx)
			local h = hero_of(ctx); if h then HeroControl.respawn(h) end
		end,
	})
	Params.register({
		id = "hero_kill", label = "Убить героя", section = "Герой",
		type = "action",
		run = function(ctx)
			local h = hero_of(ctx); if h then HeroControl.kill(h) end
		end,
	})

	-- roguelike ----------------------------------------------------------
	Params.register({
		id = "run_start", label = "Начать забег", section = "Роглайк", type = "action",
		run = function(ctx) Run.install(); Run.start(ctx.pid) end,
	})
	Params.register({
		id = "run_wave", label = "Волна", section = "Роглайк",
		type = "number", min = 1, max = 50, step = 1,
		get = function() return State.run and State.run.wave or 0 end,
		set = function(v) if State.run then State.run.wave = v end end,
	})
	Params.register({
		id = "run_gold", label = "Золото забега", section = "Роглайк",
		type = "number", min = 0, max = 100000, step = 5,
		get = function() return State.run and State.run.gold or 0 end,
		set = function(v) if State.run then State.run.gold = v end end,
	})
	Params.register({
		id = "run_next", label = "Следующая волна", section = "Роглайк", type = "action",
		run = function() Run.next_wave(State.run) end,
	})
	Params.register({
		id = "run_abort", label = "Сдаться", section = "Роглайк", type = "action",
		run = function() Run.abort() end,
	})
	Params.register({
		id = "rogue_hp_scale", label = "Множитель HP врагов", section = "Роглайк",
		type = "number", min = 0.5, max = 10.0, step = 0.1, unit = "x",
		get = function() return Config.tuning.rogue_hp_scale end,
		set = function(v) Config.tuning.rogue_hp_scale = v end,
	})
	Params.register({
		id = "rogue_dmg_scale", label = "Множитель урона врагов", section = "Роглайк",
		type = "number", min = 0.5, max = 10.0, step = 0.1, unit = "x",
		get = function() return Config.tuning.rogue_dmg_scale end,
		set = function(v) Config.tuning.rogue_dmg_scale = v end,
	})
	Params.register({
		id = "rogue_count_scale", label = "Множитель числа врагов", section = "Роглайк",
		type = "number", min = 0.5, max = 5.0, step = 0.1, unit = "x",
		get = function() return Config.tuning.rogue_count_scale end,
		set = function(v) Config.tuning.rogue_count_scale = v end,
	})

	-- arena --------------------------------------------------------------
	Params.register({
		id = "arena_radius", label = "Радиус арены", section = "Арена",
		type = "number", min = 400, max = 3000, step = 50,
		get = function() return Waves.ARENA_RADIUS end,
		set = function(v) Waves.ARENA_RADIUS = v end,
	})

	-- debug --------------------------------------------------------------
	Params.register({
		id = "free_camera", label = "Свободная камера", section = "Отладка", type = "bool",
		get = function() return State.debug.free_camera end,
		set = function(v) Camera.set_free(v) end,
	})
	Params.register({
		id = "log_level", label = "Уровень лога", section = "Отладка", type = "enum",
		options = {
			{ "trace", "trace" }, { "debug", "debug" }, { "info", "info" },
			{ "warn", "warn" }, { "error", "error" },
		},
		get = function() return log_level_name() end,
		set = function(v) Logger.set_level(v) end,
	})

	Logger.info("registered %d tunable parameters", Params.count())
	return Params.count()
end

return M
