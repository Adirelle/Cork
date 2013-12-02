
local myname, Cork = ...
if Cork.MYCLASS ~= "DRUID" then return end


-- Mark of the Wild
local spellname, _, icon = GetSpellInfo(1126)
Cork:GenerateRaidBuffer(spellname, icon, Cork.RaidBuffs.Stats)


-- Symbiosis
local spellname, _, icon = GetSpellInfo(110309)
local dataobj = Cork:GenerateLastBuffedBuffer(spellname, icon)
dataobj.partyonly = true
dataobj.ignoreplayer = true
function dataobj:CorkIt(frame)
	if self.custom then
		if self.lasttarget then
			if select(2, UnitClass(self.lasttarget)) == "DRUID" then
				self.lasttarget = nil
			else
				local macro = "/target ".. dataobj.lasttarget.. "\n/cast ".. spellname
				return frame:SetManyAttributes("type1", "macro", "macrotext1", macro)
			end
		end
		if IsInGroup() and not IsInRaid() and GetNumSubgroupMembers() == 1 and select(2, UnitClass("party1")) ~= "DRUID" then
			local macro = "/target party1\n/cast ".. spellname
			return frame:SetManyAttributes("type1", "macro", "macrotext1", macro)
		end
	end
end


-- Shapeshifts
local dobj, ref = Cork:GenerateAdvancedSelfBuffer("Fursuit", {768, 5487, 24858})
function dobj:CorkIt(frame)
	ref()
	local spell = Cork.dbpc["Fursuit-spell"]
	if self.player and Corkboard:NumLines() == 1 then
		return frame:SetManyAttributes("type1", "spell", "spell", spell, "unit", "player")
	end
end
