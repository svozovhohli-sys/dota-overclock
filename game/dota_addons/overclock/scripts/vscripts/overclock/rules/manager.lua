--[[
	OVERCLOCK :: rules/manager.lua
	The "edit the whole game" layer. Three things live here:

	  1. Game rules catalog (data/game_rules.lua) -> live params + engine calls.
	  2. Entity stat tuning (throne / towers / creeps / heroes) -> applied via
	     modifier_oc_entity_stat and auto-applied on npc_spawned.
	  3. Generic ConVar / server-console browser -> reach *any* engine variable
	     the game exposes, even ones with no dedicated Lua API.

	install(Params) is called once at boot.
--]]
local Log = require("overclock.core.logger")
local Convars = require("overclock.core.convars")
local State = require("overclock.core.state")
local Players = require("overclock.core.players")
local Events = require("overclock.core.events")
local Commands = require("overclock.core.commands")
local Engine = require("overclock.modifiers.engine")

local M = {}

M.defs = {}
M.installed = false

-- entity groups -------------------------------------------------------------

M.groups = {
	{ id = "throne", label = "Трон" },
	{ id = "towers", label = "Башни" },
	{ id = "creeps", label = "Крипы" },
	{ id = "heroes", label = "Герои" },
}

M.entity_fields = {
	{ id = "hp", label = "Макс. HP", min = 0, max = 500000, step = 500,
	  help = "0 = не менять; иначе абсолютное значение" },
	{ id = "armor", label = "Броня", min = -100, max = 500, step = 5 },
	{ id = "damage", label = "Бонус урона", min = -1000, max = 5000, step = 10 },
	{ id = "magic_resist", label = "Магрезист", min = -100, max = 200, step = 5 },
	{ id = "attack_speed", label = "Скорость атаки", min = -200, max = 1000, step = 10 },
}

-- apply one game-rule entry to the engine -----------------------------------

local function rule_apply(def, value)
	local ok, err = pcall(function()
		if def.kind == "gr" then
			GameRules[def.method](GameRules, value)
		elseif def.kind == "gm" then
			local gm = GameRules:GetGameModeEntity()
			gm[def.method](gm, value)
		elseif def.kind == "convar" then
			if def.type == "bool" then
				Convars.set_int(def.name, value and 1 or 0)
			else
				Convars.set_auto(def.name, value)
			end
		end
	end)
	if not ok then
		Log.warn("rule '%s' apply failed: %s", def.id, tostring(err))
		return false
	end
	return true
end

function M.apply_rule(id, value)
	local def = M.defs[id]
	if not def then return false end
	if value == nil then value = def.default end
	State.rules[id] = value
	return rule_apply(def, value)
end

function M.apply_all()
	local n = 0
	for id, def in pairs(M.defs) do
		M.apply_rule(id, State.rules[id])
		n = n + 1
	end
	return n
end

-- entity tuning -------------------------------------------------------------

local function classify(ent)
	if not ent or ent:IsNull() then return nil end
	if ent:IsRealHero() then return "heroes" end
	local n = string.lower(ent:GetUnitName() or "")
	if string.find(n, "fort", 1, true) then return "throne" end
	if string.find(n, "tower", 1, true) then return "towers" end
	if string.find(n, "creep", 1, true)
		or string.find(n, "neutral", 1, true)
		or string.find(n, "lane", 1, true)
		or string.find(n, "ranged", 1, true)
		or string.find(n, "melee", 1, true) then
		return "creeps"
	end
	return nil
end

function M.tune_entity(ent)
	if not ent or ent:IsNull() then return false end
	local group = classify(ent)
	if not group then return false end
	if Engine.has(ent, "modifier_oc_entity_stat") then return true end
	return Engine.apply(ent, ent, "modifier_oc_entity_stat", {
		group = group,
		base_hp = ent:GetMaxHealth(),
	}) and true or false
end

function M.tune_all()
	local n = 0
	for _, rec in pairs(State.spawned) do
		local ent = rec.entity or rec
		if ent and not ent:IsNull() and not ent:IsRealHero() then
			if M.tune_entity(ent) then n = n + 1 end
		end
	end
	for pid, _ in pairs(State.players) do
		local h = Players.hero_of(pid)
		if h then M.tune_entity(h) end
	end
	return n
end

-- boot ----------------------------------------------------------------------

local function load_defs()
	local ok, data = pcall(require, "overclock.data.game_rules")
	if not ok then
		Log.error("cannot load data/game_rules.lua: %s", tostring(data))
		return 0
	end
	for _, def in ipairs(data) do
		M.defs[def.id] = def
	end
	Log.info("loaded %d game rules", #data)
	return #data
end

-- params --------------------------------------------------------------------

local function register_rule_params(Params)
	local list = {}
	for id in pairs(M.defs) do list[#list + 1] = id end
	table.sort(list)
	for _, id in ipairs(list) do
		local def = M.defs[id]
		Params.register({
			id = "rule_" .. id,
			label = def.label,
			section = "Правила: " .. (def.section or "Прочее"),
			type = def.type,
			min = def.min, max = def.max, step = def.step, unit = def.unit,
			get = function() return State.rules[id] end,
			set = function(v) M.apply_rule(id, v) end,
		})
	end
	Params.register({
		id = "rules_apply_all", label = "Применить все правила заново",
		section = "Правила: Прочее", type = "action",
		run = function() M.apply_all() end,
	})
end

local function register_entity_params(Params)
	for _, g in ipairs(M.groups) do
		for _, f in ipairs(M.entity_fields) do
			local group, field = g.id, f.id
			Params.register({
				id = "ent_" .. group .. "_" .. field,
				label = f.label,
				section = "Статы: " .. g.label,
				type = "number",
				min = f.min, max = f.max, step = f.step,
				get = function() return State.entities[group][field] end,
				set = function(v) State.entities[group][field] = v; M.tune_all() end,
			})
		end
		Params.register({
			id = "ent_apply_" .. g.id,
			label = "Применить к " .. string.lower(g.label),
			section = "Статы: " .. g.label,
			type = "action",
			run = function() M.tune_all() end,
		})
	end
end

local function register_convar_params(Params)
	Params.register({
		id = "cv_name", label = "Имя ConVar / команды", section = "Console",
		type = "text", default = "",
		get = function() return State.rules._cv_name or "" end,
		set = function(v) State.rules._cv_name = tostring(v) end,
	})
	Params.register({
		id = "cv_value", label = "Значение / аргументы", section = "Console",
		type = "text", default = "1",
		get = function() return State.rules._cv_value or "1" end,
		set = function(v) State.rules._cv_value = tostring(v) end,
	})
	Params.register({
		id = "cv_set", label = "Установить параметр", section = "Console", type = "action",
		run = function()
			local name = State.rules._cv_name or ""
			if name == "" then return end
			Convars.set_auto(name, State.rules._cv_value or "1")
			Log.info("convar %s = %s", name, tostring(State.rules._cv_value))
		end,
	})
	Params.register({
		id = "cv_get", label = "Прочитать параметр", section = "Console", type = "action",
		run = function()
			local name = State.rules._cv_name or ""
			if name == "" then return end
			local v = Convars.get(name)
			Log.info("convar %s = %s", name, tostring(v))
			Events.emit("convar:read", { name = name, value = v })
		end,
	})
	Params.register({
		id = "cv_exec", label = "Выполнить команду консоли", section = "Console", type = "action",
		run = function()
			local name = State.rules._cv_name or ""
			local value = State.rules._cv_value or ""
			if name == "" then return end
			Convars.exec((value ~= "" and (name .. " " .. value)) or name)
		end,
	})
end

-- commands -------------------------------------------------------------------

local function coerce_rule(def, raw)
	if def.type == "bool" then
		if type(raw) == "boolean" then return raw end
		if raw == nil then return def.default end
		local s = tostring(raw):lower()
		if s == "true" or s == "1" or s == "on" then return true end
		if s == "false" or s == "0" or s == "off" then return false end
		return def.default
	end
	return tonumber(raw) or def.default
end

local function register_commands()
	Commands.register("rule", {
		help = "задать правило игры", usage = "rule <id> <value>", section = "rules",
		run = function(ctx)
			local id = ctx.args[1]
			if not id then return false, "укажи id правила" end
			local def = M.defs[id]
			if not def then return false, "нет правила " .. id end
			return M.apply_rule(id, coerce_rule(def, ctx.args[2])), id
		end,
	})
	Commands.register("rulelist", {
		help = "список id правил", usage = "rulelist", section = "rules",
		run = function()
			local ids = {}
			for id in pairs(M.defs) do ids[#ids + 1] = id end
			table.sort(ids)
			Log.info("rules: %s", table.concat(ids, ", "))
			return true, ids
		end,
	})
	Commands.register("cv", {
		help = "прочитать/задать ConVar", usage = "cv <name> [value]", section = "rules",
		run = function(ctx)
			local name = ctx.args[1]
			if not name then return false, "укажи имя" end
			if ctx.args[2] == nil then
				local v = Convars.get(name)
				Log.info("convar %s = %s", name, tostring(v))
				return true, v
			end
			Convars.set_auto(name, ctx.args[2])
			return true, name
		end,
	})
	Commands.register("exec", {
		help = "команда в серверную консоль", usage = "exec <command...>", section = "rules",
		run = function(ctx)
			local cmd = table.concat(ctx.args or {}, " ")
			if cmd == "" then return false, "пусто" end
			return Convars.exec(cmd), cmd
		end,
	})
end

function M.install(Params)
	if M.installed then return end
	M.installed = true

	load_defs()
	for id, def in pairs(M.defs) do
		State.rules[id] = def.default
	end
	M.apply_all()

	if Params then
		register_rule_params(Params)
		register_entity_params(Params)
		register_convar_params(Params)
	end

	-- auto-tune units as they appear (includes map-placed buildings).
	Events.on("npc_spawned", function(data)
		local ent = EntIndexToHScript and EntIndexToHScript(data.entindex) or nil
		if ent then M.tune_entity(ent) end
	end)

	register_commands()

	Log.info("rules manager installed")
end

return M
