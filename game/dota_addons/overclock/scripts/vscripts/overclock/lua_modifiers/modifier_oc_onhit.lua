--[[ OVERCLOCK modifier: generic ON-HIT proc.
     Covers bash, mana burn, poison and bonus-damage procs. All numbers come
     from State.mechanics[mech_id] at the moment of the hit, so edits are live.

     kv.mech_id -> { enabled, chance, bonus_damage, damage_type, stun,
                     burn_mana, dot_dps, dot_duration }
]]

modifier_oc_onhit = class({})

local State = require("overclock.core.state")

local DAMAGE_TYPES = {
	magical = DAMAGE_TYPE_MAGICAL,
	magic = DAMAGE_TYPE_MAGICAL,
	physical = DAMAGE_TYPE_PHYSICAL,
	pure = DAMAGE_TYPE_PURE,
}

function modifier_oc_onhit:IsHidden() return false end
function modifier_oc_onhit:IsPurgable() return false end
function modifier_oc_onhit:RemoveOnDeath() return false end
function modifier_oc_onhit:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_onhit:OnCreated(kv)
	self.mech_id = kv.mech_id
end

function modifier_oc_onhit:GetOcMechId() return self.mech_id end

function modifier_oc_onhit:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_oc_onhit:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m or not m.enabled then return end
	local target = keys.target
	if not target or target:IsNull() then return end

	local chance = tonumber(m.chance) or 100
	if chance < 100 and math.random() * 100.0 > chance then return end

	local attacker = self:GetParent()
	local dt = DAMAGE_TYPES[m.damage_type or "magical"] or DAMAGE_TYPE_MAGICAL

	local dmg = tonumber(m.bonus_damage) or 0
	if dmg ~= 0 then
		ApplyDamage({
			victim = target, attacker = attacker,
			damage = dmg, damage_type = dt,
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
			ability = self:GetAbility(),
		})
	end

	local burn = tonumber(m.burn_mana) or 0
	if burn > 0 and target.GetMana and target.SetMana then
		local mana = math.min(burn, target:GetMana())
		if mana > 0 then
			target:SetMana(target:GetMana() - mana)
		end
	end

	local stun = tonumber(m.stun) or 0
	if stun > 0 then
		target:AddNewModifier(attacker, nil, "modifier_oc_stun", { duration = stun })
	end

	local dot_dps = tonumber(m.dot_dps) or 0
	local dot_dur = tonumber(m.dot_duration) or 0
	if dot_dps > 0 and dot_dur > 0 then
		target:AddNewModifier(attacker, nil, "modifier_oc_dot",
			{ dps = dot_dps, type = "magic", interval = 1.0, duration = dot_dur })
	end
end
