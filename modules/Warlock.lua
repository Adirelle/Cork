
local _, c = UnitClass("player")
if c ~= "WARLOCK" then return end


-- Demon Skin
Cork:GenerateAdvancedSelfBuffer("Demon Skin", {687, 706, 28176})


--~ local di = GetSpellInfo(132) -- Detect Invisibility
--~ i = core:NewModule(di, buffs)
--~ i.target = "Friendly"
--~ i.spell = di


--~ local ueb = GetSpellInfo(5697) -- Unending Breath
--~ i = core:NewModule(ueb, buffs)
--~ i.target = "Friendly"
--~ i.spell = ueb

-- Reagents
Cork:GenerateReagentWatcher({
	[ 1122] = {  5565 }, -- Inferno	
	[18540] = { 16583 }, -- Ritual of Doom
})
