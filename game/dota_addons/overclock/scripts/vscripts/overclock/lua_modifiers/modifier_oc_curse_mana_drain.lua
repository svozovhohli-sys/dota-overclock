--[[ OVERCLOCK modifier: curse — mana burn per second.
     kv.burn = mana removed per second (also deals pure damage). ]]

modifier_oc_curse_mana_drain = class({})

function modifier_oc_curse_mana_drain:IsHidden() return false end
function modifier_oc_curse_mana_drain:IsPurgable() return false end
function modifier_oc_curse_mana_drain:IsDebuff() return true end

function modifier_oc_curse_mana_drain:OnCreated(kv)
	self.burn = tonumber(kv.burn) or 10
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_oc_curse_mana_drain:OnIntervalThink()
	local parent = self:GetParent()
	if not parent or parent:IsNull() then return end
	local mana = math.min(parent:GetMana(), self.burn)
	parent:Script_ReduceMana(mana, self:GetAbility())
	if mana > 0 then
		ApplyDamage({
			victim = parent,
			attacker = self:GetCaster(),
			damage = mana,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
			ability = self:GetAbility(),
		})
	end
end
