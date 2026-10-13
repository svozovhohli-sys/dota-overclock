--[[ OVERCLOCK modifier: generic aura carrier.
     Sits on a unit and continuously applies `kv.effect` (an existing OC
     modifier class) to units in `kv.radius` of the given team/type.

     kv.effect  = "modifier_oc_slow" | "modifier_oc_buff_attack" | ...
     kv.radius  = aura radius (default 900)
     kv.team    = DOTA_UNIT_TARGET_TEAM_* (default ENEMIES)
     kv.type    = DOTA_UNIT_TARGET_TYPE_* (default BASIC)
     kv.flags   = DOTA_UNIT_TARGET_FLAG_* (default NONE)
     kv.duration= linger duration after leaving aura (default 0.5) ]]

modifier_oc_aura = class({})

function modifier_oc_aura:IsHidden() return false end
function modifier_oc_aura:IsPurgable() return false end
function modifier_oc_aura:RemoveOnDeath() return false end

function modifier_oc_aura:OnCreated(kv)
	self.effect = kv.effect or "modifier_oc_slow"
	self.radius = tonumber(kv.radius) or 900
	self.team = tonumber(kv.team) or DOTA_UNIT_TARGET_TEAM_ENEMIES
	self.target_type = tonumber(kv.type) or DOTA_UNIT_TARGET_TYPE_BASIC
	self.flags = tonumber(kv.flags) or DOTA_UNIT_TARGET_FLAG_NONE
	self.duration = tonumber(kv.duration) or 0.5
	self.__effect_kv = kv.effect_kv
end

function modifier_oc_aura:IsAura() return true end
function modifier_oc_aura:GetModifierAura() return self.effect end
function modifier_oc_aura:GetAuraRadius() return self.radius end
function modifier_oc_aura:GetAuraSearchTeam() return self.team end
function modifier_oc_aura:GetAuraSearchType() return self.target_type end
function modifier_oc_aura:GetAuraSearchFlags() return self.flags end
function modifier_oc_aura:GetAuraDuration() return self.duration end

-- Aura icon: reuse the effect modifier's visual on the carrier subtly.
function modifier_oc_aura:GetEffectName()
	return nil
end

-- Forward any extra kv to the effect modifier when the engine asks for it.
function modifier_oc_aura:GetModifierAuraKVs()
	return self.__effect_kv or {}
end
