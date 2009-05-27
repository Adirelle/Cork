
local _, c = UnitClass("player")
if c ~= "DRUID" then return end


-- Mark of the Wild
local multispell, spellname, _, icon = GetSpellInfo(21849), GetSpellInfo(1126)
Cork:GenerateRaidBuffer(spellname, multispell, icon)


-- Shapeshifts
local bear = GetSpellInfo(GetSpellInfo(5487)) and 5487 or 9634
local dobj, ref = Cork:GenerateAdvancedSelfBuffer("Fursuit", {bear, 768, 24858, 33891})
function dobj:CorkIt(frame)
	ref()
	local spell = Cork.dbpc["Fursuit-spell"]
	if self.player and Corkboard:NumLines() == 1 then return frame:SetManyAttributes("type1", "spell", "spell", spell, "unit", "player") end
end


-- Thorns
local spellname, _, icon = GetSpellInfo(467)
Cork:GenerateLastBuffedBuffer(spellname, icon)

--Reagents
Cork:GenerateReagentWatcher({
	-- Gift of the Wlid
	[21849] = { 17201, 17026, 22148, 44605, wantMany = true },
	-- Rebirth
	[20484] = {
		17034, 17035, 17036, 17037, 17038, 22147, 44614,
		glyph = 57857, -- this is a spell id
	}
})
