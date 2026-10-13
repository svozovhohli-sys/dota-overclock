--[[ OVERCLOCK modifier: curse — armor shred.
     kv.armor = flat armor to remove (negative). Stacks additively. ]]

modifier_oc_curse_armor = class({})

function modifier_oc_curse_armor:IsHidden() return false end
function modifier_oc_curse_armor:IsPurgable() return false end
function modifier_oc_curse_armor:IsDebuff() return true end

function modifier_oc_curse_armor:OnCreated(kv)
	self.armor = tonumber(kv.armor) or 5
end

function modifier_oc_curse_armor:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_oc_curse_armor:GetModifierPhysicalArmorBonus()
	return -(self.armor * math.max(1, self:GetStackCount()))
end

function modifier_oc_curse_armor:GetEffectName()
	return "particles/units/heroes/hero_slardar/slardar_amplify_damage.vpcf"
end
