--[[
	OVERCLOCK :: metrics/ehp.lua
	Effective HP math. Dota armour is a linear multiplier:
		damage_mult = 1 - (0.06 * armor) / (1 + 0.06 * |armor|)
	Magic resist is a straight percentage. EHP = HP / damage_mult.
--]]
local M = {}

function M.armor_multiplier(armor)
	armor = armor or 0
	return 1.0 - (0.06 * armor) / (1.0 + 0.06 * math.abs(armor))
end

function M.magic_multiplier(resist_percent)
	return 1.0 - ((resist_percent or 25) / 100.0)
end

-- Raw EHP from explicit numbers.
function M.compute(hp, armor, magic_resist_percent)
	local phys = hp / math.max(0.0001, M.armor_multiplier(armor))
	local mag = hp / math.max(0.0001, M.magic_multiplier(magic_resist_percent))
	return phys, mag, (phys + mag) / 2
end

-- EHP of a live unit.
function M.of_unit(unit)
	if not unit or not IsValidEntity(unit) then return nil end
	local hp = unit:GetMaxHealth()
	local armor = unit:GetPhysicalArmorValue(false) or 0
	local mr = (unit.GetMagicalArmorValue and unit:GetMagicalArmorValue()) or 0.25
	-- GetMagicalArmorValue returns a fraction (0.25 = 25%) on most builds
	local resist_percent = (mr <= 1.0) and (mr * 100.0) or mr
	local phys, mag, avg = M.compute(hp, armor, resist_percent)
	return {
		hp = hp,
		armor = armor,
		magic_resist = resist_percent,
		physical = phys,
		magical = mag,
		average = avg,
	}
end

function M.snapshot(units)
	local out = {}
	for _, unit in ipairs(units or {}) do
		local e = M.of_unit(unit)
		if e then
			e.name = unit:GetUnitName()
			e.index = unit:entindex()
			table.insert(out, e)
		end
	end
	table.sort(out, function(a, b) return a.average > b.average end)
	return out
end

return M
