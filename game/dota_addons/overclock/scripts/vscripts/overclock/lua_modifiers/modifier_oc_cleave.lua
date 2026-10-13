--[[ OVERCLOCK modifier: cleave.
     On attack, splashes a % of the hit damage to other enemies around the
     target. Radius + percent read live from State.mechanics[mech_id]. ]]

modifier_oc_cleave = class({})

local State = require("overclock.core.state")

function modifier_oc_cleave:IsHidden() return false end
function modifier_oc_cleave:IsPurgable() return false end
function modifier_oc_cleave:RemoveOnDeath() return false end
function modifier_oc_cleave:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_oc_cleave:OnCreated(kv)
	self.mech_id = kv.mech_id
end

function modifier_oc_cleave:GetOcMechId() return self.mech_id end

function modifier_oc_cleave:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_oc_cleave:OnAttackLanded(keys)
	if not IsServer() then return end
	local attacker = self:GetParent()
	if keys.attacker ~= attacker then return end
	local m = State.mechanics and State.mechanics[self.mech_id]
	if not m or not m.enabled then return end
	local target = keys.target
	if not target or target:IsNull() then return end

	local radius = tonumber(m.radius) or 300
	local pct = tonumber(m.percent) or 0
	if pct <= 0 then return end
	local base = tonumber(keys.damage) or 0
	local splash = base * pct / 100.0
	if splash <= 0 then return end

	local units = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil,
		radius, DOTA_UNIT_TARGET_TEAM_ENEMIES,
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in ipairs(units) do
		if unit ~= target and not unit:IsNull() then
			ApplyDamage({
				victim = unit, attacker = attacker,
				damage = splash, damage_type = DAMAGE_TYPE_PHYSICAL,
				damage_flags = DOTA_DAMAGE_FLAG_NONE,
				ability = self:GetAbility(),
			})
		end
	end
end
