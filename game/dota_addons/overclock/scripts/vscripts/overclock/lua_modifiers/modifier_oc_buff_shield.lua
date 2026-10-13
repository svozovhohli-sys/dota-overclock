--[[ OVERCLOCK modifier: buff — absorb shield + magic resist.
     kv.absorb = damage absorbed (consumed), applied as bonus HP that is
                 removed when the modifier ends.
     kv.resist = bonus magic resistance (percent).
]]

modifier_oc_buff_shield = class({})

function modifier_oc_buff_shield:IsHidden() return false end
function modifier_oc_buff_shield:IsPurgable() return true end
function modifier_oc_buff_shield:IsBuff() return true end

function modifier_oc_buff_shield:OnCreated(kv)
	self.absorb = tonumber(kv.absorb) or 100
	self.resist = tonumber(kv.resist) or 0
	if IsServer() then
		local parent = self:GetParent()
		parent:SetMaxHealth(parent:GetMaxHealth() + self.absorb)
		parent:SetHealth(parent:GetHealth() + self.absorb)
	end
end

function modifier_oc_buff_shield:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_oc_buff_shield:GetModifierMagicalResistanceBonus()
	return self.resist
end

function modifier_oc_buff_shield:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		local newmax = math.max(1, parent:GetMaxHealth() - self.absorb)
		parent:SetMaxHealth(newmax)
		parent:SetHealth(math.min(parent:GetHealth(), newmax))
	end
end

function modifier_oc_buff_shield:GetEffectName()
	return "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf"
end
