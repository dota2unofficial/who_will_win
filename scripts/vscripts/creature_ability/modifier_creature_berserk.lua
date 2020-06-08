modifier_creature_berserk = class({})


function modifier_creature_berserk:GetTexture()
	return "ogre_magi_bloodlust"
end


function modifier_creature_berserk:IsHidden()
	return false
end

function modifier_creature_berserk:IsDebuff()
	return false
end

function modifier_creature_berserk:IsPurgable()
	return false
end

function modifier_creature_berserk:GetEffectName()
    return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end


function modifier_creature_berserk:OnCreated( kv )
	if IsServer() then
		self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_tower_truesight_aura", {})
		self:StartIntervalThink( 1 )
	end
	EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", self:GetParent())
    EmitSoundOn("Hero_OgreMagi.Bloodlust.Target.FP", self:GetParent())
end



function modifier_creature_berserk:OnIntervalThink()
	if IsServer() then
	    self:SetStackCount(self:GetStackCount()+1)
        
        --层数过高 直接对周围单位造成伤害
        if self:GetStackCount()>60 then
            local flRadius = 350 + (self:GetStackCount()-60)*5
            local enemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, self:GetParent():GetOrigin(), self:GetParent(),flRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
            for _,hEnemy in ipairs(enemies) do
                
                if hEnemy and (not hEnemy:HasModifier("modifier_hero_refreshing")) then
                    local damage_table = {}
                    damage_table.attacker = self:GetParent()
                    damage_table.victim = hEnemy
                    damage_table.damage_type = DAMAGE_TYPE_PURE

                    --超过层数  每层每秒1%，超200层直接秒杀
                    damage_table.damage = hEnemy:GetMaxHealth() * 0.005 * (self:GetStackCount()-60)
                    damage_table.damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
                    ApplyDamage(damage_table)
                end

            end
        end
	end
end


function modifier_creature_berserk:DeclareFunctions()
    local funcs = {
    	MODIFIER_EVENT_ON_ATTACK_LANDED,
    	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
	return funcs
end


function modifier_creature_berserk:CheckState()
	local state =
	{
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_CANNOT_MISS] = true,
	}
	return state
end

function modifier_creature_berserk:OnAttackLanded(params)
    if IsServer() then
        if self:GetParent() == params.attacker then
            local hTarget = params.target
            if hTarget ~= nil then
                local hDebuff = hTarget:FindModifierByName("modifier_creature_berserk_debuff")
                if hDebuff == nil then
                    hDebuff = hTarget:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_creature_berserk_debuff", { duration = 12.0 })
                    if hDebuff ~= nil then
                        hDebuff:SetStackCount(0)
                    end
                end
                if hDebuff ~= nil then
                    hDebuff:SetStackCount(hDebuff:GetStackCount() + 1)
                    hDebuff:SetDuration(12.0, true)
                end
            end
        end
    end
    return 0
end

function modifier_creature_berserk:GetModifierAttackSpeedBonus_Constant(params)
   return   self:GetStackCount() *5
end

function modifier_creature_berserk:GetModifierDamageOutgoing_Percentage(params)
   return   self:GetStackCount() *15
end

function modifier_creature_berserk:GetModifierMoveSpeed_AbsoluteMin(params)
   return  self:GetParent():GetBaseMoveSpeed()+math.floor(self:GetParent():GetBaseMoveSpeed() * self:GetStackCount() * 0.05)
end

function modifier_creature_berserk:GetModifierModelScale(params)
    return 55
end
