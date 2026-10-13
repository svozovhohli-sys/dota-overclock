--[[ OVERCLOCK modifier: max-HP burn.
     Each tick deals pure damage equal to a live % of the target's max HP. ]]

modifier_oc_maxhp_burn = class({})

local State = require("overclock.core.state")

function modifier_oc_maxhp_burn:IsHidden() return false end
function modifier_oc_maxhp_burn:IsDebuff() return true end
function modifier_oc_maxhp_burn:IsPurgable() return true end
function modifier_oc_maxhp_burn:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_maxhp_burn:OnCreated(kv)
	self.mech_id = kv.mech_id
	if IsServer() then
		local m = State.mechanics and State.mechanics[self.mech_id] or {}
		self.interval = tonumber(m.interval) or 0.5
		self:StartIntervalThink(self.interval)
	end
end

function modifier_oc_maxhp_burn:OnIntervalThink()
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m then return end
	local pct = tonumber(m.percent_per_sec) or 0
	local interval = tonumber(m.interval) or self.interval or 0.5
	if pct <= 0 then return end
	local dmg = parent:GetMaxHealth() * pct / 100.0 * interval
	if dmg <= 0 then return end
	ApplyDamage({
		victim = parent, attacker = self:GetCaster(),
		damage = dmg, damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = self:GetAbility(),
	})
end
