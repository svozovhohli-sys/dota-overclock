--[[ OVERCLOCK modifier: lifesteal.
     Heals the attacker for a live % of damage dealt on each hit. ]]

modifier_oc_lifesteal = class({})

local State = require("overclock.core.state")

function modifier_oc_lifesteal:IsHidden() return false end
function modifier_oc_lifesteal:IsPurgable() return false end
function modifier_oc_lifesteal:RemoveOnDeath() return false end
function modifier_oc_lifesteal:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_lifesteal:OnCreated(kv)
	self.mech_id = kv.mech_id
end

function modifier_oc_lifesteal:GetOcMechId() return self.mech_id end

function modifier_oc_lifesteal:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_oc_lifesteal:OnAttackLanded(keys)
	if not IsServer() then return end
	local attacker = self:GetParent()
	if keys.attacker ~= attacker then return end
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m or not m.enabled then return end
	local heal = (tonumber(keys.damage) or 0) * (tonumber(m.percent) or 0) / 100.0
	if heal > 0 then
		attacker:Heal(heal, attacker)
	end
end
