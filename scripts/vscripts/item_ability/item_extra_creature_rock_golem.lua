item_extra_creature_rock_golem = class({})


function item_extra_creature_rock_golem:OnSpellStart()
	if IsServer() then
		local hCaster = self:GetCaster()
		local hPlayer =  hCaster:GetPlayerOwner()
		if hCaster and hCaster:IsRealHero() and not hCaster:IsTempestDouble() and not hCaster:HasModifier("modifier_morphling_replicate")  then          
	       if hPlayer then
	       	   ExtraCreature:AddExtraCreature(hPlayer:GetPlayerID(),"npc_dota_rock_golem")
	       	   self:SpendCharge()
	       end
		end
	end
end

