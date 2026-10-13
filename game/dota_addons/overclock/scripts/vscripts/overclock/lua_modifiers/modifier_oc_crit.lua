--[[ OVERCLOCK modifier: critical strike.
     Reads chance + multiplier from State.mechanics[mech_id] each attack. ]]

modifier_oc_crit = class({})

local State = require("overclock.core.state")

function modifier_oc_crit:IsHidden() return false end
function modifier_oc_crit:IsPurgable() return false end
function modifier_oc_crit:RemoveOnDeath() return false end
function modifier_oc_crit:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_crit:OnCreated(kv)
	self.mech_id = kv.mech_id
end

function modifier_oc_crit:GetOcMechId() return self.mech_id end

function modifier_oc_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_oc_crit:GetModifierPreAttack_CriticalStrike(keys)
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m or not m.enabled then return end
	return {
		proc_chance = tonumber(m.chance) or 0,
		crit_multiplier = tonumber(m.mult) or 2.0,
		target = keys.target,
	}
end
