
local _, c = UnitClass("player")
if c ~= "PALADIN" then return end


-- Righteous Fury
local spellname, _, icon = GetSpellInfo(25780)
Cork:GenerateSelfBuffer(spellname, icon)


-- Auras
Cork:GenerateAdvancedSelfBuffer("Aura", {465, 7294, 19746, 19876, 19888, 19891, 32223})

-- Seals
local isawhorde = UnitFactionGroup("player") == "Horde"
Cork:GenerateAdvancedSelfBuffer("Seal", {21084, 20375, isawhorde and 31892 or 53720, 20166, isawhorde and 53736 or 31801, 20165, 20164})

-- Reagents
local SYMBOL_OF_KINGS = { 21177, 21177, 21177, 21177, 21177, wantMany = true }
Cork:GenerateReagentWatcher({
	-- Greater Blessing of Kings
	[25989] = SYMBOL_OF_KINGS,
	-- Greater Blessing of Might
	[25782] = SYMBOL_OF_KINGS,
	-- Greater Blessing of Sanctuary
	[25899] = SYMBOL_OF_KINGS,
	-- Greater Blessing of Wisdom
	[25899] = SYMBOL_OF_KINGS,	
	-- Divine Intervention
	[19752] = { 17033 },
})
