--[[ OVERCLOCK modifier: live damage-over-time on a target.
     dps / interval / damage_type read live from State.mechanics[mech_id]. ]]

modifier_oc_live_dot = class({})

local State = require("overclock.core.state")

local DAMAGE_TYPES = {
	magical = DAMAGE_TYPE_MAGICAL,
	magic = DAMAGE_TYPE_MAGICAL,
	physical = DAMAGE_TYPE_PHYSICAL,
	pure = DAMAGE_TYPE_PURE,
}

function modifier_oc_live_dot:IsHidden() return false end
function modifier_oc_live_dot:IsDebuff() return true end
function modifier_oc_live_dot:IsPurgable() return true end
function modifier_oc_live_dot:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_live_dot:OnCreated(kv)
	self.mech_id = kv.mech_id
	if IsServer() then
		local m = State.mechanics and State.mechanics[self.mech_id] or {}
		self.interval = tonumber(m.interval) or 1.0
		self:StartIntervalThink(self.interval)
	end
end

function modifier_oc_live_dot:OnIntervalThink()
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m then return end
	local interval = tonumber(m.interval) or self.interval or 1.0
	local dps = tonumber(m.dps) or 0
	if dps <= 0 then return end
	local dt = DAMAGE_TYPES[m.damage_type or "magical"] or DAMAGE_TYPE_MAGICAL
	ApplyDamage({
		victim = parent, attacker = self:GetCaster(),
		damage = dps * interval, damage_type = dt,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
		ability = self:GetAbility(),
	})
end

function modifier_oc_live_dot:GetEffectName()
	return "particles/items2_fx/orb_of_venom.vpcf"
end

function modifier_oc_live_dot:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
