--[[ OVERCLOCK modifier: generic LIVE stat knob.
     One class covers every "number on a stat" mechanic. The value is read from
     State.mechanics[mech_id].value on every query, so the params panel edits it
     in real time.

     kv.mech_id = id into State.mechanics
     kv.prop    = one of the PROPS keys below (chooses the engine property)
]]

modifier_oc_live_stat = class({})

local State = require("overclock.core.state")

local PROPS = {
	attack_speed = MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	move_speed = MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	armor = MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	magic_resist = MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	spell_amp = MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	cdr = MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	status_resist = MODIFIER_PROPERTY_STATUS_RESISTANCE,
	slow_resist = MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING,
	evasion = MODIFIER_PROPERTY_EVASION_CONSTANT,
	hp_regen = MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	mana_regen = MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	cast_range = MODIFIER_PROPERTY_CAST_RANGE_BONUS,
	attack_range = MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	heal_amp = MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE,
}

modifier_oc_live_stat.PROPS = PROPS

function modifier_oc_live_stat:IsHidden() return false end
function modifier_oc_live_stat:IsPurgable() return false end
function modifier_oc_live_stat:RemoveOnDeath() return false end
function modifier_oc_live_stat:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_live_stat:OnCreated(kv)
	self.mech_id = kv.mech_id
	self.prop = PROPS[kv.prop or ""] or MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
end

function modifier_oc_live_stat:GetOcMechId() return self.mech_id end

function modifier_oc_live_stat:DeclareFunctions()
	return { self.prop }
end

function modifier_oc_live_stat:_v()
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m then return 0 end
	return tonumber(m.value) or 0
end

-- Only the property declared in DeclareFunctions is ever queried, so every
-- getter can safely share the same accessor.
function modifier_oc_live_stat:GetModifierAttackSpeedBonus_Constant() return self:_v() end
function modifier_oc_live_stat:GetModifierMoveSpeedBonus_Percentage() return self:_v() end
function modifier_oc_live_stat:GetModifierPhysicalArmorBonus() return self:_v() end
function modifier_oc_live_stat:GetModifierMagicalResistanceBonus() return self:_v() end
function modifier_oc_live_stat:GetModifierSpellAmplify_Percentage() return self:_v() end
function modifier_oc_live_stat:GetModifierPercentageCooldown() return self:_v() end
function modifier_oc_live_stat:GetModifierStatusResistance() return self:_v() end
function modifier_oc_live_stat:GetModifierSlowResistance_Stacking() return self:_v() end
function modifier_oc_live_stat:GetModifierEvasion_Constant() return self:_v() end
function modifier_oc_live_stat:GetModifierHealthRegenConstant() return self:_v() end
function modifier_oc_live_stat:GetModifierConstantManaRegen() return self:_v() end
function modifier_oc_live_stat:GetModifierCastRangeBonus() return self:_v() end
function modifier_oc_live_stat:GetModifierAttackRangeBonus() return self:_v() end
function modifier_oc_live_stat:GetModifierHealAmplify_Percentage() return self:_v() end
