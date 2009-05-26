
local _, c = UnitClass("player")
if c ~= "MAGE" then return end


-- Armor
Cork:GenerateAdvancedSelfBuffer("Armor", {168, 7302, 6117, 30482})

-- Fuckus Magic
local spellname, _, icon = GetSpellInfo(54646)
Cork:GenerateLastBuffedBuffer(spellname, icon)

-- Amplify Magic
local spellname, _, icon = GetSpellInfo(1008)
Cork:GenerateRaidBuffer(spellname, nil, icon, false)

-- Dampen Magic
local spellname, _, icon = GetSpellInfo(604)
Cork:GenerateRaidBuffer(spellname, nil, icon, false)


--~ i = core:NewModule("Amplify/Dampen Magic", buffs)
--~ i.target = "Raid"
--~ i.defaultspell = GetSpellInfo(604) -- Dampen Magic
--~ i.spells = {
--~ 	[GetSpellInfo(1008)] = true, -- Amplify Magic
--~ 	[i.defaultspell] = true,
--~ }

--Reagents
local RUNE_OF_TELEPORTATION = { 17031 }
local RUNE_OF_PORTALS = { 17032 }
local ARCANE_POWDER = { 17020, 17020, 17020 }
local reagents
-- Only the lowest level portals and teleports are listed
if UnitFactionGroup("player") == "Horde" then
	reagents = {
		[ 3567] = RUNE_OF_TELEPORTATION, -- Teleport: Orgrimmar
		[32272] = RUNE_OF_TELEPORTATION, -- Teleport: Silvermoon
		[ 3563] = RUNE_OF_TELEPORTATION, -- Teleport: Undercity	
		[49361] = RUNE_OF_PORTALS, -- Portal: Stonard	
		[11417] = RUNE_OF_PORTALS, -- Portal: Orgrimmar	
		[32267] = RUNE_OF_PORTALS, -- Portal: Silvermoon	
		[11418] = RUNE_OF_PORTALS, -- Portal: Undercity
	}
else
	reagents = {
		[32271] = RUNE_OF_TELEPORTATION, -- Teleport: Exodar
		[ 3562] = RUNE_OF_TELEPORTATION, -- Teleport: Ironforge
		[ 3561] = RUNE_OF_TELEPORTATION, -- Teleport: Stormwind	
		[49360] = RUNE_OF_PORTALS, -- Portal: Theramore	
		[32266] = RUNE_OF_PORTALS, -- Portal: Exodar	
		[11416] = RUNE_OF_PORTALS, -- Portal: Ironforge	
		[10059] = RUNE_OF_PORTALS, -- Portal: Stormwind	
	}
end
reagents[23028] = ARCANE_POWDER -- Arcane Brilliance
reagents[43987] = ARCANE_POWDER -- Ritual of Refreshment
Cork:GenerateReagentWatcher(reagents)
