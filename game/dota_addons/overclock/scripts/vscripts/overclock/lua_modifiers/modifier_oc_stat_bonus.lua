--[[ OVERCLOCK modifier: flat stat bonus.
     kv.stat  = "damage"|"attack_speed"|"armor"|"hp"|"mana"|"move_speed"|"magic_resist"
     kv.value = number
     kv.stacks= optional stack count
]]

modifier_oc_stat_bonus = class({})

local FUNCTION_MAP = {
	damage = MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	attack_speed = MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	armor = MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	hp = MODIFIER_PROPERTY_HEALTH_BONUS,
	mana = MODIFIER_PROPERTY_MANA_BONUS,
	move_speed = MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	magic_resist = MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	spell_amp = MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
}

function modifier_oc_stat_bonus:IsHidden() return false end
function modifier_oc_stat_bonus:IsPurgable() return false end
function modifier_oc_stat_bonus:RemoveOnDeath() return false end

function modifier_oc_stat_bonus:OnCreated(kv)
	self.stat = kv.stat or "damage"
	self.value = tonumber(kv.value) or 0
	self.prop = FUNCTION_MAP[self.stat]
end

function modifier_oc_stat_bonus:DeclareFunctions()
	return { self.prop or MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_oc_stat_bonus:GetModifierPreAttack_BonusDamage() return self.value end
function modifier_oc_stat_bonus:GetModifierAttackSpeedBonus_Constant() return self.value end
function modifier_oc_stat_bonus:GetModifierPhysicalArmorBonus() return self.value end
function modifier_oc_stat_bonus:GetModifierHealthBonus() return self.value end
function modifier_oc_stat_bonus:GetModifierManaBonus() return self.value end
function modifier_oc_stat_bonus:GetModifierMoveSpeedBonus_Constant() return self.value end
function modifier_oc_stat_bonus:GetModifierMagicalResistanceBonus() return self.value end
function modifier_oc_stat_bonus:GetModifierSpellAmplify_Percentage() return self.value end
