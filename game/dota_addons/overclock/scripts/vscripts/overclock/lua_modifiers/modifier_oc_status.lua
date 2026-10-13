--[[ OVERCLOCK modifier: generic hard status on a target.
     kv.state = "rooted"|"silenced"|"disarmed"|"hexed"|"passives_disabled"|"muted"
     Duration passed at apply time. ]]

modifier_oc_status = class({})

local STATES = {
	rooted = MODIFIER_STATE_ROOTED,
	silenced = MODIFIER_STATE_SILENCED,
	disarmed = MODIFIER_STATE_DISARMED,
	hexed = MODIFIER_STATE_HEXED,
	passives_disabled = MODIFIER_STATE_PASSIVES_DISABLED,
	muted = MODIFIER_STATE_MUTED,
}

modifier_oc_status.STATES = STATES

function modifier_oc_status:IsHidden() return false end
function modifier_oc_status:IsDebuff() return true end
function modifier_oc_status:IsPurgable() return true end

function modifier_oc_status:OnCreated(kv)
	self.state_key = kv.state or "rooted"
end

function modifier_oc_status:CheckState()
	local st = STATES[self.state_key]
	if not st then return {} end
	return { [st] = true }
end

function modifier_oc_status:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_oc_status:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
