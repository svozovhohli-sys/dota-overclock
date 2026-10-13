--[[
	OVERCLOCK :: core/players.lua
	Player/hero identity + registration helpers.
--]]
local State = require("overclock.core.state")
local Log = require("overclock.core.logger")

local M = {}

function M.hero_of(pid)
	local rec = State.players[pid]
	if rec and rec.hero and IsValidEntity(rec.hero) then
		return rec.hero
	end
	return nil
end

function M.player_of_hero(hero)
	if not hero or not IsValidEntity(hero) then return nil end
	local pid = hero:GetPlayerID()
	return State.players[pid]
end

function M.register(pid, extra)
	local rec = State.players[pid] or { pid = pid }
	rec.pid = pid
	rec.name = PlayerResource:GetPlayerName(pid) or ("Игрок " .. tostring(pid))
	rec.team = PlayerResource:GetTeam(pid)
	rec.hero = PlayerResource:GetSelectedHeroEntity(pid)
	if type(extra) == "table" then
		for k, v in pairs(extra) do rec[k] = v end
	end
	State.players[pid] = rec
	Log.debug("registered player %d (%s)", pid, rec.name)
	return rec
end

function M.unregister(pid)
	State.players[pid] = nil
end

function M.gold(pid)
	return PlayerResource:GetGold(pid) or 0
end

function M.add_gold(pid, amount)
	local hero = M.hero_of(pid)
	if hero then
		hero:ModifyGold(amount, false, DOTA_ModifyGold_Unspecified)
	end
end

function M.all_heroes()
	local out = {}
	for _, rec in pairs(State.players) do
		if rec.hero and IsValidEntity(rec.hero) then
			table.insert(out, rec.hero)
		end
	end
	return out
end

-- Players that are real humans (not spectators/unassigned).
function M.active_player_ids()
	local out = {}
	for pid = 0, DOTA_MAX_TEAM_PLAYERS * 2 - 1 do
		if PlayerResource and PlayerResource:IsValidPlayerID(pid)
			and PlayerResource:GetTeam(pid) ~= DOTA_TEAM_NOTEAM then
			table.insert(out, pid)
		end
	end
	return out
end

return M
