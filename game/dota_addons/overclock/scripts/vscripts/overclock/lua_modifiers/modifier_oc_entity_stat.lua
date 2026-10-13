--[[ OVERCLOCK modifier: live entity stat tuning.
     Applied to throne / towers / creeps / heroes. Values are read from
     State.entities[group] on every query, so edits apply instantly.

     kv.group   = "throne" | "towers" | "creeps" | "heroes"
     kv.base_hp = unit:GetMaxHealth() captured at apply time (for absolute HP)
]]

modifier_oc_entity_stat = class({})

local State = require("overclock.core.state")

local function cfg(self)
	return (State.entities and State.entities[self.group]) or {}
end

function modifier_oc_entity_stat:IsHidden() return true end
function modifier_oc_entity_stat:IsPurgable() return false end
function modifier_oc_entity_stat:RemoveOnDeath() return false end

function modifier_oc_entity_stat:OnCreated(kv)
	self.group = kv.group or "creeps"
	self.base_hp = tonumber(kv.base_hp) or 0
end

function modifier_oc_entity_stat:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_oc_entity_stat:GetModifierHealthBonus()
	local target = tonumber(cfg(self).hp) or 0
	if target <= 0 then return 0 end
	return target - self.base_hp
end

function modifier_oc_entity_stat:GetModifierPhysicalArmorBonus()
	return tonumber(cfg(self).armor) or 0
end

function modifier_oc_entity_stat:GetModifierPreAttack_BonusDamage()
	return tonumber(cfg(self).damage) or 0
end

function modifier_oc_entity_stat:GetModifierMagicalResistanceBonus()
	return tonumber(cfg(self).magic_resist) or 0
end

function modifier_oc_entity_stat:GetModifierAttackSpeedBonus_Constant()
	return tonumber(cfg(self).attack_speed) or 0
end
