
local _, c = UnitClass("player")
if c ~= "PRIEST" then return end


-- Fort
local multispell, spellname, _, icon = GetSpellInfo(21562), GetSpellInfo(1243)
Cork:GenerateRaidBuffer(spellname, multispell, icon)


-- Inner Fire
local spellname, _, icon = GetSpellInfo(588)
Cork:GenerateSelfBuffer(spellname, icon)


-- Shadowform
local spellname, _, icon = GetSpellInfo(15473)
Cork:GenerateSelfBuffer(spellname, icon)


-- Divine Spirit
local multispell, spellname, _, icon = GetSpellInfo(27681), GetSpellInfo(14752)
Cork:GenerateRaidBuffer(spellname, multispell, icon)


-- Shadow Protection
local multispell, spellname, _, icon = GetSpellInfo(27683), GetSpellInfo(976)
Cork:GenerateRaidBuffer(spellname, multispell, icon)

-- Fear Ward
local spellname, _, icon = GetSpellInfo(6346)
Cork:GenerateLastBuffedBuffer(spellname, icon)

-- Reagents
Cork:GenerateReagentWatcher({
	[27681] = { 17029, 17029, 44615 }, -- Prayer of Spirit
	[21562] = { 17028, 17029, 17029, 44615 }, -- Prayer of Fortitude
	[27683] = { 17029, 17029, 44615 }, -- Prayer of Shadow Protection
})
