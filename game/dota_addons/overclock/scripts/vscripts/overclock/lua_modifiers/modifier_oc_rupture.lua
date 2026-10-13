--[[ OVERCLOCK modifier: Rupture-style bleed.
     Deals pure damage proportional to distance moved. Live knob:
     State.mechanics[mech_id].per_100 = damage per 100 units moved.
     Duration is passed at apply time. ]]

modifier_oc_rupture = class({})

local State = require("overclock.core.state")

function modifier_oc_rupture:IsHidden() return false end
function modifier_oc_rupture:IsDebuff() return true end
function modifier_oc_rupture:IsPurgable() return false end

function modifier_oc_rupture:OnCreated(kv)
	self.mech_id = kv.mech_id
	self.last = self:GetParent():GetAbsOrigin()
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_oc_rupture:OnIntervalThink()
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m then return end
	local now = parent:GetAbsOrigin()
	local dist = (now - self.last):Length2D()
	self.last = now
	local per_100 = tonumber(m.per_100) or 0
	if dist < 1 or per_100 <= 0 then return end
	ApplyDamage({
		victim = parent, attacker = self:GetCaster(),
		damage = (dist / 100.0) * per_100,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = self:GetAbility(),
	})
end

function modifier_oc_rupture:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

function modifier_oc_rupture:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
