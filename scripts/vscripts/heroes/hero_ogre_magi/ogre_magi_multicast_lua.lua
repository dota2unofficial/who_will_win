ogre_magi_multicast_lua = {
	GetIntrinsicModifierName = function() return "modifier_multicast_lua" end,
}

function IsUltimateAbility(ability)
	return bit:_and(ability:GetAbilityType(), 1) == 1
end


function IsGlobalAbility(hAbility)

	if hAbility and ("invoker_sun_strike_lua"==hAbility:GetAbilityName() or "zuus_thundergods_wrath"==hAbility:GetAbilityName() 
	or "furion_wrath_of_nature"==hAbility:GetAbilityName() or "zuus_cloud"==hAbility:GetAbilityName() or "ancient_apparition_ice_blast"==hAbility:GetAbilityName()
    or "spectre_haunt"==hAbility:GetAbilityName()) then
      return true
    else
      return false
    end

end


function HasBehavior(behavior,ability)
	local abilityBehavior = tonumber(tostring(ability:GetBehavior()))
	return bit:_and(abilityBehavior, behavior) == behavior
end

if IsServer() then
	function ogre_magi_multicast_lua:OnSpellStart()
		local caster = self:GetCaster()
		if not caster:HasScepter() then return end

		local target = self:GetCursorTarget()
		local duration = self:GetSpecialValueFor("duration_ally_scepter")
		target:EmitSound("Hero_OgreMagi.Fireblast.x3")
		target:AddNewModifier(caster, self, "modifier_multicast_lua", { duration = duration })
	end
end

function ogre_magi_multicast_lua:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function ogre_magi_multicast_lua:GetManaCost(...)
	return self:GetCaster():HasScepter() and self.BaseClass.GetManaCost(self, ...) or 0
end

function ogre_magi_multicast_lua:GetCastRange(...)
	return self:GetCaster():HasScepter() and self.BaseClass.GetCastRange(self, ...) or 0
end

function ogre_magi_multicast_lua:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	if caster == target or target:FindAbilityByName("ogre_magi_multicast_lua") then
		return UF_FAIL_CUSTOM
	end

	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())
end


function ogre_magi_multicast_lua:GetCustomCastErrorTarget(target)
	if self:GetCaster() == target then
		return "#dota_hud_error_cant_cast_on_self"
	end
	if target:FindAbilityByName("ogre_magi_multicast_lua") then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end


LinkLuaModifier("modifier_multicast_lua", "heroes/hero_ogre_magi/ogre_magi_multicast_lua.lua", LUA_MODIFIER_MOTION_NONE)
modifier_multicast_lua = {
	IsPurgable = function() return false end,
	GetEffectName = function() return "particles/arena/units/heroes/hero_ogre_magi/multicast_aghanims_buff.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end,
	DeclareFunctions = function() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end,
}

if IsServer() then
	function modifier_multicast_lua:OnAbilityExecuted(keys)
		local parent = self:GetParent()
		if parent ~= keys.unit then return end
		local castedAbility = keys.ability

		local caster = self:GetParent()
		local target = keys.target or caster:GetCursorPosition()
		local ability = self:GetAbility()

		local ogreAbilities = {
			ogre_magi_bloodlust = true,
			ogre_magi_fireblast = true,
			ogre_magi_ignite = true,
			ogre_magi_unrefined_fireblast = true
		}
		if ogreAbilities[castedAbility:GetAbilityName()] then
			local mc = caster:AddAbility("ogre_magi_multicast")
			mc:SetHidden(true)
			mc:SetLevel(ability:GetLevel())
			Timers:CreateTimer(0.1, function() caster:RemoveAbility("ogre_magi_multicast") end)
			return
		end

		local multiplier = IsUltimateAbility(castedAbility) and 0.5 or 1
        
        if IsGlobalAbility(castedAbility) then
           multiplier = multiplier * 0.5
        end

        if "item_hand_of_midas"==castedAbility:GetAbilityName() then
           multiplier = multiplier * 0.5
        end

        --print(multiplier)

		local multicast

		if RollPercentage(math.floor(ability:GetSpecialValueFor("multicast_4_times") * multiplier)) then
			multicast = 4
		elseif RollPercentage(math.floor(ability:GetSpecialValueFor("multicast_3_times") * multiplier))then
			multicast = 3
		elseif RollPercentage(math.floor(ability:GetSpecialValueFor("multicast_2_times") * multiplier))then
			multicast = 2
		end

		if multicast then
			PreformMulticast(caster, castedAbility, multicast, ability:GetSpecialValueFor("multicast_delay"), target)
		end
	end

	local MULTICAST_TYPE_NONE = 0
	local MULTICAST_TYPE_SAME = 1 -- Fireblast
	local MULTICAST_TYPE_DIFFERENT = 2 -- Ignite
	local MULTICAST_TYPE_INSTANT = 3 -- Bloodlust
	local MULTICAST_ABILITIES = {
		ogre_magi_bloodlust = MULTICAST_TYPE_NONE,
		ogre_magi_fireblast = MULTICAST_TYPE_NONE,
		ogre_magi_ignite = MULTICAST_TYPE_NONE,
		ogre_magi_unrefined_fireblast = MULTICAST_TYPE_NONE,
		ogre_magi_multicast_lua = MULTICAST_TYPE_NONE,

		item_manta_arena = MULTICAST_TYPE_NONE,
		item_diffusal_style = MULTICAST_TYPE_NONE,
		item_refresher_arena = MULTICAST_TYPE_NONE,
		item_refresher_core = MULTICAST_TYPE_NONE,

		invoker_quas = MULTICAST_TYPE_NONE,
		invoker_wex = MULTICAST_TYPE_NONE,
		invoker_exort = MULTICAST_TYPE_NONE,
		invoker_invoke = MULTICAST_TYPE_NONE,
		alchemist_unstable_concoction = MULTICAST_TYPE_NONE,
		alchemist_unstable_concoction_throw = MULTICAST_TYPE_NONE,
		elder_titan_ancestral_spirit = MULTICAST_TYPE_NONE,
		elder_titan_return_spirit = MULTICAST_TYPE_NONE,
		ember_spirit_sleight_of_fist = MULTICAST_TYPE_NONE,
		monkey_king_tree_dance = MULTICAST_TYPE_NONE,
		monkey_king_primal_spring = MULTICAST_TYPE_NONE,
		monkey_king_primal_spring_early = MULTICAST_TYPE_NONE,
		wisp_spirits = MULTICAST_TYPE_NONE,
		wisp_spirits_in = MULTICAST_TYPE_NONE,
		wisp_spirits_out = MULTICAST_TYPE_NONE,
		arc_warden_tempest_double = MULTICAST_TYPE_NONE,
		phoenix_sun_ray = MULTICAST_TYPE_NONE,
		phoenix_sun_ray_stop = MULTICAST_TYPE_NONE,
		phoenix_sun_ray_toggle_move = MULTICAST_TYPE_NONE,

		terrorblade_conjure_image = MULTICAST_TYPE_INSTANT,
		terrorblade_reflection = MULTICAST_TYPE_INSTANT,
		magnataur_empower = MULTICAST_TYPE_INSTANT,
		oracle_purifying_flames = MULTICAST_TYPE_SAME,
		vengefulspirit_magic_missile = MULTICAST_TYPE_SAME,

		undying_tombstone_lua = MULTICAST_TYPE_NONE,
		item_spell_book_empty_lua = MULTICAST_TYPE_NONE,
		item_spell_book_lua = MULTICAST_TYPE_NONE,
		item_relearn_book_lua = MULTICAST_TYPE_NONE,
		item_relearn_torn_page_lua = MULTICAST_TYPE_NONE,
		item_summon_book_lua = MULTICAST_TYPE_NONE,
		item_paragon_book = MULTICAST_TYPE_NONE,

		item_book_of_strength = MULTICAST_TYPE_NONE,
		item_book_of_agility = MULTICAST_TYPE_NONE,
		item_book_of_intelligence = MULTICAST_TYPE_NONE,


		shredder_chakram = MULTICAST_TYPE_NONE,
		shredder_chakram_2 = MULTICAST_TYPE_NONE,
		item_aegis_lua = MULTICAST_TYPE_NONE,
		tusk_walrus_punch = MULTICAST_TYPE_DIFFERENT,
		tusk_walrus_kick = MULTICAST_TYPE_DIFFERENT,

		warlock_fatal_bonds = MULTICAST_TYPE_NONE,
		nyx_assassin_burrow = MULTICAST_TYPE_NONE,
		nyx_assassin_unburrow = MULTICAST_TYPE_NONE,
		item_force_staff = MULTICAST_TYPE_DIFFERENT,
		item_hurricane_pike = MULTICAST_TYPE_DIFFERENT,
		item_black_king_bar = MULTICAST_TYPE_NONE,
		item_smoke_of_deceit = MULTICAST_TYPE_NONE,
		item_ward_sentry = MULTICAST_TYPE_NONE,
        
        monkey_king_wukongs_command = MULTICAST_TYPE_NONE,
        item_manta = MULTICAST_TYPE_NONE,
	}

	function GetAbilityMulticastType(ability)
		local name = ability:GetAbilityName()
		if MULTICAST_ABILITIES[name] then return MULTICAST_ABILITIES[name] end
		if ability:IsToggle() then return MULTICAST_TYPE_NONE end

		if HasBehavior(DOTA_ABILITY_BEHAVIOR_PASSIVE,ability) then return MULTICAST_TYPE_NONE end
		return HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET,ability) and MULTICAST_TYPE_DIFFERENT or MULTICAST_TYPE_SAME
	end

	function PreformMulticast(caster, ability_cast, multicast, multicast_delay, target)
		local multicast_type = GetAbilityMulticastType(ability_cast)
		if multicast_type ~= MULTICAST_TYPE_NONE then
			local prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf', PATTACH_OVERHEAD_FOLLOW, caster)
			local multicast_flag_data = GetMulticastFlags(caster, ability_cast, multicast_type)
			local channelData = {}
			caster:AddEndChannelListener(function(interrupted)
				channelData.endTime = GameRules:GetGameTime()
				channelData.channelFailed = interrupted
			end)
			if multicast_type == MULTICAST_TYPE_INSTANT then
				Timers:NextTick(function()
					ParticleManager:SetParticleControl(prt, 1, Vector(multicast, 0, 0))
					ParticleManager:ReleaseParticleIndex(prt)
					local multicast_casted_data = {}
					for i=2,multicast do
						CastMulticastedSpellInstantly(caster, ability_cast, target, multicast_flag_data, multicast_casted_data, 0, channelData)
					end
				end)
			else
				CastMulticastedSpell(caster, ability_cast, target, multicast-1, multicast_type, multicast_flag_data, {}, multicast_delay, channelData, prt, 2)
			end
		end
	end

	function GetMulticastFlags(caster, ability, multicast_type)
		local rv = {}
		if multicast_type ~= MULTICAST_TYPE_SAME then
			rv.cast_range = ability:GetCastRange(caster:GetOrigin(), caster)
			local abilityTarget = ability:GetAbilityTargetTeam()
			if abilityTarget == 0 then abilityTarget = DOTA_UNIT_TARGET_TEAM_ENEMY end
			rv.abilityTarget = abilityTarget
			local abilityTargetType = ability:GetAbilityTargetTeam()
			if abilityTargetType == 0 then abilityTargetType = DOTA_UNIT_TARGET_ALL
			elseif abilityTargetType == 2 and HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT,ability) then abilityTargetType = 3 end
			rv.abilityTargetType = abilityTargetType
			rv.team = caster:GetTeam()
			rv.targetFlags = ability:GetAbilityTargetFlags()
		end
		return rv
	end

	function CastMulticastedSpellInstantly(caster, ability, target, multicast_flag_data, multicast_casted_data, delay, channelData)
		local candidates = FindUnitsInRadius(multicast_flag_data.team, caster:GetOrigin(), nil, multicast_flag_data.cast_range, multicast_flag_data.abilityTarget, multicast_flag_data.abilityTargetType, multicast_flag_data.targetFlags, FIND_ANY_ORDER, false)
		local Tier1 = {} --heroes
		local Tier2 = {} --creeps and self
		local Tier3 = {} --already casted
		local Tier4 = {} --dead stuff
		for k, v in pairs(candidates) do
			if caster:CanEntityBeSeenByMyTeam(v) then
				if multicast_casted_data[v] then
					Tier3[#Tier3 + 1] = v
				elseif not v:IsAlive() then
					Tier4[#Tier4 + 1] = v
				elseif v:IsHero() and v ~= caster then
					Tier1[#Tier1 + 1] = v
				else
					Tier2[#Tier2 + 1] = v
				end
			end
		end
		local castTarget = Tier1[math.random(#Tier1)] or Tier2[math.random(#Tier2)] or Tier3[math.random(#Tier3)] or Tier4[math.random(#Tier4)] or target
		multicast_casted_data[castTarget] = true
		CastAdditionalAbility(caster, ability, castTarget, delay, channelData)
		return multicast_casted_data
	end

	function CastMulticastedSpell(caster, ability, target, multicasts, multicast_type, multicast_flag_data, multicast_casted_data, delay, channelData, prt, prtNumber)
		if multicasts >= 1 then
			Timers:CreateTimer(delay, function()
				ParticleManager:DestroyParticle(prt, true)
				ParticleManager:ReleaseParticleIndex(prt)
				prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf', PATTACH_OVERHEAD_FOLLOW, caster)
				ParticleManager:SetParticleControl(prt, 1, Vector(prtNumber, 0, 0))
				if multicast_type == MULTICAST_TYPE_SAME then
					CastAdditionalAbility(caster, ability, target, delay * (prtNumber - 1), channelData)
				else
					multicast_casted_data = CastMulticastedSpellInstantly(caster, ability, target, multicast_flag_data, multicast_casted_data, delay * (prtNumber - 1), channelData)
				end
				caster:EmitSound('Hero_OgreMagi.Fireblast.x'.. multicasts)
				if multicasts >= 2 then
					CastMulticastedSpell(caster, ability, target, multicasts - 1, multicast_type, multicast_flag_data, multicast_casted_data, delay, channelData, prt, prtNumber + 1)
				end
			end)
		else
			ParticleManager:DestroyParticle(prt, false)
			ParticleManager:ReleaseParticleIndex(prt)
		end
	end
end

function CastAdditionalAbility(caster, ability, target, delay, channelData)
	local skill = ability
	local unit = caster
	local channelTime = ability:GetChannelTime() or 0
	if channelTime > 0 then
		if not caster.dummyCasters then
			caster.dummyCasters = {}
			caster.nextFreeDummyCaster = 1
			for i = 1, 8 do
				local dummy = CreateUnitByName("npc_dummy_caster", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
				dummy:SetControllableByPlayer(caster:GetPlayerID(), true)
				dummy:AddNoDraw()
				dummy:MakeIllusion()
				table.insert(caster.dummyCasters, dummy)
			end
		end
		local dummy = caster.dummyCasters[caster.nextFreeDummyCaster]
		skill = nil
		caster.nextFreeDummyCaster = caster.nextFreeDummyCaster % #caster.dummyCasters + 1
		local abilityName = ability:GetName()
		for i = 0, DOTA_ITEM_SLOT_9 do
			local ditem = dummy:GetItemInSlot(i)
			if ditem then
				ditem:Destroy()
			end
			local citem = caster:GetItemInSlot(i)
			if citem then
				local newditem = dummy:AddItem(CopyItem(citem))
				if newditem:GetName() == abilityName then
					skill = newditem
				end
			end
		end
		dummy:SetOwner(caster)
		dummy:SetAbsOrigin(caster:GetAbsOrigin())
		dummy:SetBaseStrength (caster:GetStrength())
		dummy:SetBaseAgility(caster:GetAgility())
		dummy:SetBaseIntellect(caster:GetIntellect())
		for _, v in pairs(caster:FindAllModifiers()) do
			local buffName = v:GetName()
			local buffAbility = v:GetAbility()
			local dummyModifier = dummy:FindModifierByName(buffName) or dummy:AddNewModifier(dummy, buffAbility, buffName, nil)
			if dummyModifier then dummyModifier:SetStackCount(v:GetStackCount()) end
		end
		Illusions:_copyAbilities(caster, dummy)
		skill = skill or dummy:FindAbilityByName(ability:GetName())
		skill:SetLevel(ability:GetLevel())
		skill.GetCaster = function() return ability:GetCaster() end
		unit = dummy
	end
	if HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET,skill) then
		if target and type(target) == "table" then
			unit:SetCursorCastTarget(target)
		end
	end
	if HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT,skill) then
		if target then
			if target.x and target.y and target.z then
				unit:SetCursorPosition(target)
			elseif target.GetOrigin then
				unit:SetCursorPosition(target:GetOrigin())
			end
		end
	end
	skill:OnSpellStart()
	if channelTime > 0 then
		if channelData.endTime then
			EndAdditionalAbilityChannel(caster, unit, skill, channelData.channelFailed, delay - GameRules:GetGameTime() + channelData.endTime)
		else
			caster:AddEndChannelListener(function(interrupted)
				EndAdditionalAbilityChannel(caster, unit, skill, interrupted, delay)
			end)
		end
	end
end