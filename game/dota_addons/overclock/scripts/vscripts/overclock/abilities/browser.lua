--[[
	OVERCLOCK :: abilities/browser.lua
	Search and inspect abilities and their AbilitySpecial values.

	Dota does not let a custom game rewrite the *values* of Valve's base
	abilities at runtime, but it does let us READ everything and, for our own
	OC abilities, edit freely. This browser is the "find the value you want"
	tool: it materialises any ability by name, enumerates its special values,
	and pushes them to the UI.

	Results are also written to the console so they survive even without UI.
--]]
local Log = require("overclock.core.logger")
local State = require("overclock.core.state")
local Players = require("overclock.core.players")
local Commands = require("overclock.core.commands")

local M = {}

M.MAX_RESULTS = 30

local function unit_abilities(unit)
	local out = {}
	if not unit or unit:IsNull() then return out end
	local n = unit:GetAbilityCount()
	for i = 0, n - 1 do
		local ab = unit:GetAbilityByIndex(i)
		if ab then out[#out + 1] = ab end
	end
	return out
end

-- Read all AbilitySpecial entries off an ability handle.
local function dump_ability(abil)
	local name = "?"
	local ok = pcall(function() name = abil:GetAbilityName() end)
	local res = { ability = name, values = {} }

	local kv
	local okkv, kvres = pcall(function() return abil:GetAbilityKeyValues() end)
	if okkv then kv = kvres end

	if kv and type(kv) == "table" and kv.AbilitySpecial then
		for _, entry in pairs(kv.AbilitySpecial) do
			if type(entry) == "table" then
				for k, _ in pairs(entry) do
					if k ~= "var_type" and k ~= "var_type_" then
						local val
						local okv, v = pcall(function() return abil:GetSpecialValueFor(k) end)
						if okv then val = v end
						res.values[#res.values + 1] = { key = tostring(k), value = val }
					end
				end
			end
		end
	end

	table.sort(res.values, function(a, b) return tostring(a.key) < tostring(b.key) end)
	return res
end

-- Try to get an ability handle by name, materialising it on the hero if needed.
local function materialize(hero, name)
	if not hero or hero:IsNull() then return nil, false end
	local existing = hero:FindAbilityByName(name)
	if existing then return existing, false end
	local ab
	local okadd, abres = pcall(function() return hero:AddAbility(name) end)
	if okadd then ab = abres end
	if ab then
		pcall(function() ab:SetLevel(1) end)
		return ab, true
	end
	return nil, false
end

local function present_heroes()
	local out = {}
	for pid, _ in pairs(State.players) do
		local h = Players.hero_of(pid)
		if h then out[#out + 1] = h end
	end
	return out
end

-- Core query: returns { query, results = { dump, ... }, note = string? }
function M.query(q, ctx)
	q = tostring(q or "")
	local results = {}
	local note

	if q == "" then
		note = "укажи имя способности (например spirit_breaker_greater_bash)"
		return { query = q, results = results, note = note }
	end

	local lq = string.lower(q)
	local hero = ctx and ctx.pid ~= nil and Players.hero_of(ctx.pid) or nil

	-- 1) exact / materialised ability
	local abil = hero and materialize(hero, q)
	if abil then
		results[#results + 1] = dump_ability(abil)
		return { query = q, results = results, note = "точное совпадение: " .. q }
	end

	-- 2) substring search across abilities present in the match
	local full = false
	for _, h in ipairs(present_heroes()) do
		if full then break end
		for _, ab in ipairs(unit_abilities(h)) do
			local name = ""
			pcall(function() name = ab:GetAbilityName() end)
			if string.find(string.lower(name), lq, 1, true) then
				results[#results + 1] = dump_ability(ab)
				if #results >= M.MAX_RESULTS then full = true; break end
			end
		end
	end

	if #results == 0 then
		note = "ничего не найдено по «" .. q .. "»"
	end
	return { query = q, results = results, note = note }
end

-- Log a result set to the console (always available).
function M.log_results(res)
	Log.info("ABILITIES: query='%s' (%d)", tostring(res.query), #res.results)
	if res.note then Log.info("  note: %s", res.note) end
	for i, dump in ipairs(res.results) do
		local parts = {}
		for _, kv in ipairs(dump.values) do
			parts[#parts + 1] = string.format("%s=%s", kv.key, tostring(kv.value))
		end
		Log.info("  [%d] %s  %s", i, dump.ability, table.concat(parts, "  "))
	end
end

-- Boot -----------------------------------------------------------------------

local function register_params(Params)
	Params.register({
		id = "ab_query", label = "Поиск способности", section = "Способности",
		type = "text", default = "",
		get = function() return State.ability.query end,
		set = function(v) State.ability.query = tostring(v) end,
	})
	Params.register({
		id = "ab_find", label = "Найти значения", section = "Способности",
		type = "action",
		run = function(ctx)
			local res = M.query(State.ability.query, ctx)
			State.ability.results = res.results
			M.log_results(res)
			local Bridge = _G.OC and _G.OC.UI and _G.OC.UI.Bridge
			if Bridge and ctx and ctx.pid then
				Bridge.push(ctx.pid, "oc_abilities", res)
			end
		end,
	})
	Params.register({
		id = "ab_clear", label = "Очистить результаты", section = "Способности",
		type = "action",
		run = function()
			State.ability.results = {}
			local Bridge = _G.OC and _G.OC.UI and _G.OC.UI.Bridge
			if Bridge then Bridge.push_all("oc_abilities", { query = "", results = {} }) end
		end,
	})
end

function M.install(Params)
	if M.installed then return end
	M.installed = true
	if Params then register_params(Params) end
	Commands.register("ab", {
		help = "поиск способности и её значений", usage = "ab <имя|подстрока>",
		section = "abilities",
		run = function(ctx)
			local q = table.concat(ctx.args or {}, " ")
			local res = M.query(q, { pid = ctx.pid })
			State.ability.query = q
			State.ability.results = res.results
			M.log_results(res)
			local Bridge = _G.OC and _G.OC.UI and _G.OC.UI.Bridge
			if Bridge then Bridge.push(ctx.pid, "oc_abilities", res) end
			return true, res
		end,
	})
	Log.info("ability browser installed")
end

return M
