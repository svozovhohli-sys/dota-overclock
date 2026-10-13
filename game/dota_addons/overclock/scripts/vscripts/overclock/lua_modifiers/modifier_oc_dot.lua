--[[ OVERCLOCK modifier: damage over time.
     kv.dps   = damage per second
     kv.type  = "magic"|"physical"|"pure"
     kv.interval = optional tick length (default 1.0)
]]

modifier_oc_dot = class({})

local DAMAGE_TYPES = {
	magic = DAMAGE_TYPE_MAGICAL,
	physical = DAMAGE_TYPE_PHYSICAL,
	pure = DAMAGE_TYPE_PURE,
}

function modifier_oc_dot:IsHidden() return false end
function modifier_oc_dot:IsPurgable() return true end
function modifier_oc_dot:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_dot:OnCreated(kv)
	self.dps = tonumber(kv.dps) or 10
	self.dtype = DAMAGE_TYPES[kv.type or "magic"] or DAMAGE_TYPE_MAGICAL
	self.interval = tonumber(kv.interval) or 1.0
	if IsServer() then
		self:StartIntervalThink(self.interval)
		-- optional attached particle
		if kv.particle then
			self.particle = ParticleManager:CreateParticle(kv.particle,
				PATTACH_OVERHEAD_FOLLOW, self:GetParent())
		end
	end
end

function modifier_oc_dot:OnIntervalThink()
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local dmg = {
		victim = parent,
		attacker = self:GetCaster(),
		damage = self.dps * self.interval,
		damage_type = self.dtype,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
		ability = self:GetAbility(),
	}
	ApplyDamage(dmg)
end

function modifier_oc_dot:OnDestroy()
	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		self.particle = nil
	end
end
