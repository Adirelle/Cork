
local myname, Cork = ...
local UnitAura = Cork.UnitAura or UnitAura
local IsSpellInRange = Cork.IsSpellInRange
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")


local blist = {npc = true, vehicle = true}
for i=1,5 do blist["arena"..i], blist["arenapet"..i] = true, true end

local MagicClasses = {["DRUID"] = true, ["MAGE"] = true, ["MONK"] = true, ["PALADIN"] = true, ["PRIEST"] = true, ["SHAMAN"] = true, ["WARLOCK"] = true}

-- Return a function that will look for any of the listed spells
local function AnyOf(...)
	local names = {}
	for i = 1, select('#', ...) do
		local id = select(i, ...)
		names[i] = GetSpellInfo(id)
	end
	return function(unit)
		for i, name in pairs(names) do
			if UnitAura(unit, name) then
				return true
			end
		end
	end
end

-- See http://www.wowhead.com/guide=1100 for details
Cork.RaidBuffs = {
	-- Mark of the Wild, Legacy of the Emperor, Blessing of Kings, Embrace of the Shale Spider (hunter pet)
	Stats       = AnyOf(1126, 116781, 20217, 90363),

	-- Power Word: Fortitude, Dark Intent, Commanding Shout, Qiraji Fortitude (hunter pet)
	Stamina     = AnyOf(21562, 109773, 469, 90364),

	-- Horn of Winter, Trueshot Aura, Battle Shout
	-- NOT USED YET -- AttackPower = AnyOf(57330, 19506, 6673),

	-- Unholy Aura, Swiftblade's Cunning, Unleashed Rage, Cackling Howl (hunter pet), Serpent's Swiftness (hunter pet)
	-- NOT USED YET -- AttackSpeed = AnyOf(55610, 113742, 30809, 128432, 128433),

	-- Arcane Brillance, Dalarance Brillance, Burning Wrath, Dark Intent, Still Water (hunter pet)
	SpellPower  = AnyOf(1459, 61316, 77747, 109773, 126309),

	-- Moonkin Aura, Mind Quickening, Elemental Oath, Energizing Spores (hunter pet)
	-- NOT USED YET -- SpellHaste  = AnyOf(24907, 49868, 51470, 135678),

	-- Leader of the Pack, Arcane Brillance, Dalarance Brillance, Legacy of the White Tiger, Furious Howl (hunter pet), Terrifying Roar (hunter pet), Fearless Roar (hunter pet), Still Water (hunter pet)
	Critical    = AnyOf(17007, 1459, 61316, 116781, 4604, 90309, 126373, 126309),

	-- Blessing of Might, Grace of Air, Roar of Courage (hunter pet), Spirit Beast Blessing (hunter pet)
	-- NOT USED YET -- Mastery     = AnyOf(19740, 116956, 93435, 128997),
}

-- Do not cast spell buffs on units that do not cast spells
local spellpower = Cork.RaidBuffs.SpellPower
Cork.RaidBuffs.SpellPower = function(unit, token) return not MagicClasses[token] or spellpower(unit) end
-- NOT USED YET -- local spellhaste = Cork.RaidBuffs.SpellHaste
-- NOT USED YET -- Cork.RaidBuffs.SpellHaste = function(unit, token) return not MagicClasses[token] or spellhaste(unit) end

local function truth() return true end

-- Create a raid buffing module.  This module will try to make sure all group
-- members have this buff
--
--      spellname - the name of our spell (give a localized one!)
--           icon - the icon to show in the tip
--           buff - first buff provided by the spell (see Cork.RaidBuffs)
--        secbuff - second buffs provided by the spell (see Cork.RaidBuffs)
function Cork:GenerateRaidBuffer(spellname, icon, buff, secbuff)
	local SpellCastableOnUnit, IconLine = self.SpellCastableOnUnit, self.IconLine

	local dataobj = ldb:NewDataObject("Cork "..spellname, {
		type = "cork",
		corktype = "buff",
		tiplink = GetSpellLink(spellname),
	})

	function dataobj:Init()
		Cork.defaultspc[spellname.."-enabled"] = GetSpellInfo(spellname) ~= nil
	end

	if not secbuff then
		secbuff = truth
	end

	local function Test(unit)
		if not Cork.dbpc[spellname.."-enabled"] or (IsResting() and not Cork.db.debug) or not Cork:ValidUnit(unit) then return end

		if not UnitAura(unit, spellname) then
			local _, token = UnitClass(unit)
			if not buff(unit, token) or not secbuff(unit, token) then
				return IconLine(icon, UnitName(unit), token)
			end
		end
	end
	Cork:RegisterRaidEvents(spellname, dataobj, Test)
	dataobj.Scan = Cork:GenerateRaidScan(Test)

	ae.RegisterEvent(dataobj, "PLAYER_UPDATE_RESTING", "Scan")


	dataobj.RaidLine = IconLine(icon, spellname.." (%d)")


	function dataobj:CorkIt(frame)
		if self.player and SpellCastableOnUnit(spellname, "player") then return frame:SetManyAttributes("type1", "spell", "spell", spellname, "unit", "player") end
		for unit in ldb:pairs(self) do if SpellCastableOnUnit(spellname, unit) then return frame:SetManyAttributes("type1", "spell", "spell", spellname, "unit", unit) end end
	end
end

local raidunits, partyunits, otherunits = {}, {}, { ["player"] = true, ["target"] = true, ["focus"] = true }
for i=1,40 do raidunits["raid"..i] = i end
for i=1,4 do partyunits["party"..i] = i end
function Cork:ValidUnit(unit)
	if blist[unit] or not UnitExists(unit) or (UnitIsPlayer(unit) and (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) or UnitInVehicle(unit)))
		or (UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) -- No pets, ever
		or (unit ~= "player" and UnitIsUnit(unit, "player"))
		or (unit == "target" and (UnitIsUnit("target", "focus") or not UnitCanAssist("player", unit) or not UnitIsPlayer(unit) or UnitIsEnemy("player", unit)))
		or (unit == "focus" and not UnitCanAssist("player", unit))
		or (IsInRaid() and partyunits[unit])
		or raidunits[unit] and select(3, GetRaidRosterInfo(raidunits[unit])) > Cork.RaidThresh() then return end

	return true
end
local function isScanUnit(unit)
	return not not (raidunits[unit] or partyunits[unit] or otherunits[unit])
end


function Cork:RegisterRaidEvents(spellname, dataobj, Test)
	local function TestUnit(event, unit) if isScanUnit(unit) then dataobj[unit] = Test(unit) end end
	ae.RegisterEvent("Cork "..spellname, "UNIT_AURA", TestUnit)
	ae.RegisterEvent("Cork "..spellname, "UNIT_DYNAMIC_FLAGS", TestUnit)
	ae.RegisterEvent("Cork "..spellname, "UNIT_ENTERED_VEHICLE", TestUnit)
	ae.RegisterEvent("Cork "..spellname, "UNIT_EXITED_VEHICLE", TestUnit)
	ae.RegisterEvent("Cork "..spellname, "UNIT_FLAGS", TestUnit)
	ae.RegisterEvent("Cork "..spellname, "GROUP_ROSTER_UPDATE", function()
		for k, _ in pairs(partyunits) do dataobj[k] = Test(k) end
		for k, _ in pairs(raidunits) do dataobj[k] = Test(k) end
	end)
	local function TestTargetandFocus() dataobj.target, dataobj.focus = Test("target"), Test("focus") end
	ae.RegisterEvent("Cork "..spellname, "PLAYER_TARGET_CHANGED", TestTargetandFocus)
	ae.RegisterEvent("Cork "..spellname, "PLAYER_FOCUS_CHANGED", TestTargetandFocus)
end


function Cork:GenerateRaidScan(Test)
	return function(self)
		for k, _ in pairs(otherunits) do self[k] = Test(k) end
		for k, _ in pairs(partyunits) do self[k] = Test(k) end
		for k, _ in pairs(raidunits) do self[k] = Test(k) end
	end
end
