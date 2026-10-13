--[[
	OVERCLOCK :: sandbox/items.lua
	Give / remove / randomize items for testing builds and combo timings.
--]]
local State = require("overclock.core.state")
local Log = require("overclock.core.logger")
local Util = require("overclock.core.util")

local M = {}

-- A useful default bench for damage/utility testing.
M.BENCH = {
	"item_heart",
	"item_black_king_bar",
	"item_butterfly",
	"item_monkey_king_bar",
	"item_daedalus",
	"item_satanic",
	"item_skadi",
	"item_octarine_core",
	"item_refresher",
	"item_blink",
	"item_sheepstick",
	"item_shivas_guard",
}

function M.give(hero, item_name)
	if not hero then return false end
	local item = CreateItem(item_name, hero, hero)
	if not item then
		Log.error("cannot create item %s", tostring(item_name))
		return false
	end
	hero:AddItem(item)
	Log.debug("gave %s to %s", item_name, hero:GetUnitName())
	return true
end

function M.give_many(hero, items)
	local n = 0
	for _, name in ipairs(items or {}) do
		if M.give(hero, name) then n = n + 1 end
	end
	return n
end

function M.give_bench(hero)
	return M.give_many(hero, M.BENCH)
end

function M.clear(hero)
	if not hero then return false end
	for i = 0, 5 do
		local item = hero:GetItemInSlot(i)
		if item then
			hero:RemoveItem(item)
		end
	end
	return true
end

function M.randomize(hero, pool)
	pool = pool or M.BENCH
	if not hero then return false end
	M.clear(hero)
	local picks = Util.sample(pool, 6)
	return M.give_many(hero, picks)
end

function M.consume_all_cooldowns(hero)
	if not hero then return false end
	for i = 0, 5 do
		local item = hero:GetItemInSlot(i)
		if item and item.EndCooldown then
			item:EndCooldown()
		end
	end
	return true
end

return M
