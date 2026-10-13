--[[ OVERCLOCK modifier: buff — bonus attack speed + damage.
     kv.as     = attack speed
     kv.damage = flat damage
]]

modifier_oc_buff_attack = class({})

function modifier_oc_buff_attack:IsHidden() return false end
function modifier_oc_buff_attack:IsPurgable() return true end
function modifier_oc_buff_attack:IsBuff() return true end

function modifier_oc_buff_attack:OnCreated(kv)
	self.as = tonumber(kv.as) or 50
	self.damage = tonumber(kv.damage) or 20
end

function modifier_oc_buff_attack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_oc_buff_attack:GetModifierAttackSpeedBonus_Constant() return self.as end
function modifier_oc_buff_attack:GetModifierPreAttack_BonusDamage() return self.damage end

function modifier_oc_buff_attack:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end
