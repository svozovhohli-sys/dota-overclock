--[[ OVERCLOCK modifier: movement/attack slow.
     kv.slow = percent (0..100), stacks multiply. ]]

modifier_oc_slow = class({})

function modifier_oc_slow:IsHidden() return false end
function modifier_oc_slow:IsPurgable() return true end
function modifier_oc_slow:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_slow:OnCreated(kv)
	self.slow = tonumber(kv.slow) or 30
end

function modifier_oc_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_oc_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_oc_slow:GetModifierAttackSpeedBonus_Constant()
	return -self.slow
end

function modifier_oc_slow:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end
