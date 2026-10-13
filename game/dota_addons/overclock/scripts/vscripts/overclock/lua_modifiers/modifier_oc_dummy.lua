--[[ OVERCLOCK modifier: inert measurement dummy.
     Cannot move, attack or use abilities; takes damage normally. ]]

modifier_oc_dummy = class({})

function modifier_oc_dummy:IsHidden() return false end
function modifier_oc_dummy:IsPurgable() return false end
function modifier_oc_dummy:RemoveOnDeath() return false end

function modifier_oc_dummy:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_oc_dummy:GetEffectName()
	return nil
end
