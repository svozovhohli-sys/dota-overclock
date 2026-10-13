--[[
	OVERCLOCK :: mechanics/manager.lua
	Turns data/mechanics.lua into a live, editable combat-mechanics lab.

	Each mechanic maps to one implementing modifier class (see KINDS). "self"
	mechanics are attached to the caller's hero; "target" mechanics are applied
	to the nearest enemy. Every field becomes a live parameter, so balance can
	be tuned to tiny increments while the game runs.
--]]
local Log = require("overclock.core.logger")
local State = require("overclock.core.state")
local Players = require("overclock.core.players")
local Commands = require("overclock.core.commands")
local Engine = require("overclock.modifiers.engine")

local M = {}

M.defs = {}
M.order = {}
M.installed = false

local KINDS = {
	stat = { mod = "modifier_oc_live_stat", file = "overclock/lua_modifiers/modifier_oc_live_stat" },
	onhit = { mod = "modifier_oc_onhit", file = "overclock/lua_modifiers/modifier_oc_onhit" },
	crit = { mod = "modifier_oc_crit", file = "overclock/lua_modifiers/modifier_oc_crit" },
	cleave = { mod = "modifier_oc_cleave", file = "overclock/lua_modifiers/modifier_oc_cleave" },
	lifesteal = { mod = "modifier_oc_lifesteal", file = "overclock/lua_modifiers/modifier_oc_lifesteal" },
	dot = { mod = "modifier_oc_live_dot", file = "overclock/lua_modifiers/modifier_oc_live_dot" },
	maxhp = { mod = "modifier_oc_maxhp_burn", file = "overclock/lua_modifiers/modifier_oc_maxhp_burn" },
	rupture = { mod = "modifier_oc_rupture", file = "overclock/lua_modifiers/modifier_oc_rupture" },
	status = { mod = "modifier_oc_status", file = "overclock/lua_modifiers/modifier_oc_status" },
}

-- extra classes referenced directly by other mechanics -----------------------
local EXTRA = {
	{ "modifier_oc_stun", "overclock/lua_modifiers/modifier_oc_stun" },
	{ "modifier_oc_dot", "overclock/lua_modifiers/modifier_oc_dot" },
}

local function hero_of(ctx)
	if ctx and ctx.pid ~= nil then return Players.hero_of(ctx.pid) end
	return nil
end

local function class_of(mech)
	local k = KINDS[mech.kind]
	return k and k.mod or nil
end

local function build_kv(mech)
	if mech.kind == "stat" then
		return { mech_id = mech.id, prop = mech.prop }
	elseif mech.kind == "status" then
		return { state = mech.state }
	end
	return { mech_id = mech.id }
end

-- has a specific mechanic instance on a unit --------------------------------

local function find_instance(unit, class, mech_id)
	if not unit or unit:IsNull() then return nil end
	local mods = unit:FindAllModifiersByName(class)
	if not mods then return nil end
	for _, mod in pairs(mods) do
		if (not mod.GetOcMechId) or mod:GetOcMechId() == mech_id then
			return mod
		end
	end
	return nil
end

local function has_instance(unit, class, mech_id)
	return find_instance(unit, class, mech_id) ~= nil
end

-- self mechanics -------------------------------------------------------------

function M.enable(mech_id, ctx)
	local mech = M.defs[mech_id]
	local h = hero_of(ctx)
	if not mech or not h then return false end
	local class = class_of(mech)
	if not class then return false end
	if not has_instance(h, class, mech_id) then
		Engine.apply(h, h, class, build_kv(mech))
	end
	State.mechanics[mech_id].enabled = true
	return true
end

function M.disable(mech_id, ctx)
	local mech = M.defs[mech_id]
	local h = hero_of(ctx)
	if not mech or not h then return false end
	local class = class_of(mech)
	local mod = find_instance(h, class, mech_id)
	if mod then mod:Destroy() end
	State.mechanics[mech_id].enabled = false
	return true
end

function M.is_enabled(mech_id, ctx)
	local mech = M.defs[mech_id]
	local h = hero_of(ctx)
	if not mech or not h then return State.mechanics[mech_id] and State.mechanics[mech_id].enabled or false end
	return has_instance(h, class_of(mech), mech_id)
end

-- target mechanics -----------------------------------------------------------

local function nearest_enemy(h)
	local units = FindUnitsInRadius(h:GetTeamNumber(), h:GetAbsOrigin(), nil, 3000,
		DOTA_UNIT_TARGET_TEAM_ENEMIES,
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	return units and units[1] or nil
end

function M.apply_target(mech_id, ctx)
	local mech = M.defs[mech_id]
	local h = hero_of(ctx)
	if not mech or not h then return false end
	local target = nearest_enemy(h)
	if not target then return false end
	local duration = State.mechanics[mech_id] and State.mechanics[mech_id].duration or 5
	return Engine.apply(target, h, class_of(mech), build_kv(mech), duration) and true or false
end

local function clear_on(unit, class)
	if unit and not unit:IsNull() and unit:HasModifier(class) then
		unit:RemoveModifierByName(class)
	end
end

function M.clear_target(mech_id)
	local mech = M.defs[mech_id]
	if not mech then return false end
	local class = class_of(mech)
	for _, rec in pairs(State.spawned) do
		clear_on(rec.entity or rec, class)
	end
	for pid, _ in pairs(State.players) do
		clear_on(Players.hero_of(pid), class)
	end
	return true
end

-- boot -----------------------------------------------------------------------

local function link_modifiers()
	for _, k in pairs(KINDS) do
		pcall(LinkLuaModifier, k.mod, k.file, LUA_MODIFIER_MOTION_NONE)
	end
	for _, extra in ipairs(EXTRA) do
		pcall(LinkLuaModifier, extra[1], extra[2], LUA_MODIFIER_MOTION_NONE)
	end
end

local function load_defs()
	local ok, data = pcall(require, "overclock.data.mechanics")
	if not ok then
		Log.error("cannot load data/mechanics.lua: %s", tostring(data))
		return 0
	end
	for _, mech in ipairs(data) do
		M.defs[mech.id] = mech
		M.order[#M.order + 1] = mech.id
		local cfg = { enabled = false }
		for _, f in ipairs(mech.fields or {}) do
			cfg[f.id] = f.default
		end
		State.mechanics[mech.id] = cfg
	end
	Log.info("registered %d mechanics", #data)
	return #data
end

-- params ---------------------------------------------------------------------

local function register_params(Params)
	for _, id in ipairs(M.order) do
		local mech = M.defs[id]
		local section = "Механики: " .. mech.label
		if mech.scope == "self" then
			Params.register({
				id = "mc_" .. id, label = "Включено", section = section, type = "bool",
				get = function(ctx) return M.is_enabled(id, ctx) end,
				set = function(v, ctx)
					if v then M.enable(id, ctx) else M.disable(id, ctx) end
				end,
			})
		else
			Params.register({
				id = "mc_" .. id .. "_apply", label = "Применить к цели",
				section = section, type = "action",
				run = function(ctx) M.apply_target(id, ctx) end,
			})
			Params.register({
				id = "mc_" .. id .. "_clear", label = "Снять со всех",
				section = section, type = "action",
				run = function() M.clear_target(id) end,
			})
		end
		for _, f in ipairs(mech.fields or {}) do
			local field = f.id
			Params.register({
				id = "mc_" .. id .. "_" .. field,
				label = f.label,
				section = section,
				type = f.type or "number",
				min = f.min, max = f.max, step = f.step, unit = f.unit,
				options = f.options,
				get = function() return State.mechanics[id][field] end,
				set = function(v) State.mechanics[id][field] = v end,
			})
		end
	end
end

local function register_commands()
	Commands.register("mech", {
		help = "включить/выключить механику на герое", usage = "mech <id> on|off", section = "mechanics",
		run = function(ctx)
			local id = ctx.args[1]
			local on = (ctx.args[2] ~= "off") and (ctx.args[2] ~= "0")
			if not id then return false, "укажи id механики" end
			if not M.defs[id] then return false, "нет механики " .. id end
			if on then return M.enable(id, ctx) else return M.disable(id, ctx) end
		end,
	})
	Commands.register("mechset", {
		help = "задать поле механики", usage = "mechset <id> <field> <value>", section = "mechanics",
		run = function(ctx)
			local id, field, value = ctx.args[1], ctx.args[2], ctx.args[3]
			if not (id and field and value) then return false, "укажи id field value" end
			local cfg = State.mechanics[id]
			if not cfg then return false, "нет механики " .. id end
			cfg[field] = tonumber(value) or value
			return true, id .. "." .. field .. "=" .. tostring(cfg[field])
		end,
	})
	Commands.register("mechapply", {
		help = "применить целевую механику к ближайшему врагу",
		usage = "mechapply <id>", section = "mechanics",
		run = function(ctx)
			local id = ctx.args[1]
			if not id then return false, "укажи id" end
			return M.apply_target(id, ctx), id
		end,
	})
	Commands.register("mechlist", {
		help = "список механик", usage = "mechlist", section = "mechanics",
		run = function()
			Log.info("mechanics: %s", table.concat(M.order, ", "))
			return true, M.order
		end,
	})
end

function M.install(Params)
	if M.installed then return end
	M.installed = true
	link_modifiers()
	load_defs()
	if Params then register_params(Params) end
	register_commands()
	Log.info("mechanics lab installed")
end

return M
