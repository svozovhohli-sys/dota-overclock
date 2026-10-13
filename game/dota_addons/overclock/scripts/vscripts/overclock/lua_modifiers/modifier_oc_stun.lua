--[[ OVERCLOCK modifier: stun (used by bash and status mechanics). ]]

modifier_oc_stun = class({})

function modifier_oc_stun:IsHidden() return false end
function modifier_oc_stun:IsStunDebuff() return true end
function modifier_oc_stun:IsDebuff() return true end
function modifier_oc_stun:IsPurgable() return true end

function modifier_oc_stun:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_oc_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_oc_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
