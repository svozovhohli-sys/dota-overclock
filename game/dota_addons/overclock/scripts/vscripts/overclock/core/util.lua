--[[
	OVERCLOCK :: core/util.lua
	Small helper library used across the whole addon.

	Pure functions only (no game state), so it is safe to require from any
	module and from the client-independent bootstrap.
--]]
local M = {}

-- ---------------------------------------------------------------------------
-- math
-- ---------------------------------------------------------------------------

function M.clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

function M.lerp(a, b, t)
	return a + (b - a) * t
end

function M.round(v, places)
	local mult = 10 ^ (places or 0)
	return math.floor(v * mult + 0.5) / mult
end

function M.sign(v)
	if v > 0 then return 1 end
	if v < 0 then return -1 end
	return 0
end

function M.approach(current, target, step)
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

-- ---------------------------------------------------------------------------
-- tables
-- ---------------------------------------------------------------------------

function M.shallow_copy(t)
	local out = {}
	for k, v in pairs(t) do out[k] = v end
	return out
end

function M.deep_copy(t)
	if type(t) ~= "table" then return t end
	local out = {}
	for k, v in pairs(t) do
		out[k] = M.deep_copy(v)
	end
	return out
end

-- Recursively merge src into dst (src wins). Returns dst.
function M.merge(dst, src)
	for k, v in pairs(src or {}) do
		if type(v) == "table" and type(dst[k]) == "table" then
			M.merge(dst[k], v)
		else
			dst[k] = M.deep_copy(v)
		end
	end
	return dst
end

function M.keys(t)
	local out = {}
	for k in pairs(t) do table.insert(out, k) end
	return out
end

function M.values(t)
	local out = {}
	for _, v in pairs(t) do table.insert(out, v) end
	return out
end

function M.count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

function M.contains(list, value)
	for _, v in ipairs(list) do
		if v == value then return true end
	end
	return false
end

function M.index_of(list, value)
	for i, v in ipairs(list) do
		if v == value then return i end
	end
	return nil
end

function M.filter(list, pred)
	local out = {}
	for _, v in ipairs(list) do
		if pred(v) then table.insert(out, v) end
	end
	return out
end

function M.map(list, fn)
	local out = {}
	for i, v in ipairs(list) do
		out[i] = fn(v, i)
	end
	return out
end

function M.sum(list)
	local s = 0
	for _, v in ipairs(list) do s = s + v end
	return s
end

-- sorted iteration by key
function M.sorted_keys(t, cmp)
	local k = M.keys(t)
	table.sort(k, cmp)
	return k
end

-- ---------------------------------------------------------------------------
-- random
-- ---------------------------------------------------------------------------

local rng = nil

-- Deterministic PRNG (so a "run seed" reproduces the same roguelike).
function M.set_seed(seed)
	rng = seed
	math.randomseed(seed)
end

function M.random_int(lo, hi)
	if lo == nil then return math.random() end
	if hi == nil then return math.random(lo) end
	return math.random(lo, hi)
end

function M.pick(list)
	if #list == 0 then return nil end
	return list[M.random_int(1, #list)]
end

function M.pick_weighted(entries, weight_key)
	weight_key = weight_key or "weight"
	local total = 0
	for _, e in ipairs(entries) do
		total = total + (e[weight_key] or 1)
	end
	if total <= 0 then return nil end
	local roll = math.random() * total
	for _, e in ipairs(entries) do
		roll = roll - (e[weight_key] or 1)
		if roll <= 0 then return e end
	end
	return entries[#entries]
end

function M.shuffle(list)
	for i = #list, 2, -1 do
		local j = M.random_int(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

-- Draw n unique entries from a list (copy).
function M.sample(list, n)
	local copy = M.shallow_copy(list)
	M.shuffle(copy)
	local out = {}
	for i = 1, math.min(n, #copy) do
		out[i] = copy[i]
	end
	return out
end

-- ---------------------------------------------------------------------------
-- strings
-- ---------------------------------------------------------------------------

function M.split(str, sep)
	sep = sep or ","
	local out = {}
	for token in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(out, token)
	end
	return out
end

function M.trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.starts_with(s, prefix)
	return s:sub(1, #prefix) == prefix
end

function M.ends_with(s, suffix)
	return suffix == "" or s:sub(-#suffix) == suffix
end

function M.format_thousands(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1 ")
	return out:reverse():gsub("^%s+", "")
end

function M.format_duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

return M
