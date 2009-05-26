local Cork = Cork
local IconLine = Cork.IconLine
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")
local defaults = Cork.defaultspc

local GetNumGlyphSockets = GetNumGlyphSockets
local GetGlyphSocketInfo = GetGlyphSocketInfo
local GetSpellName = GetSpellName
local GetSpellInfo = GetSpellInfo
local GetItemInfo = GetItemInfo
local GetItemCount = GetItemCount

local glyphs 
local spellRanks

local function WatchSpells()
	local Update
	if Update then return	end
	
	glyphs = {}
	spellRanks = {}

	Update = function()
		wipe(glyphs)
		for i = 1, GetNumGlyphSockets() do
			local _, _, id = GetGlyphSocketInfo(i)
			if id then
				glyphs[id] = true
			end
		end
		wipe(spellRanks)
		for i = 1, 1000 do
			local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
			if not name then break end
			rank = tonumber(rank:match("(%d+)")) or 0
			if rank > (spellRanks[name] or -1) then
				spellRanks[name] = rank
			end
		end
	end
	
	ae.RegisterEvent('Cork ReagentWatcher', 'SPELLS_CHANGED', Update)
	ae.RegisterEvent('Cork ReagentWatcher', "PLAYER_TALENT_UPDATE", Update)
	ae.RegisterEvent('Cork ReagentWatcher', "GLYPH_ADDED", Update)
	ae.RegisterEvent('Cork ReagentWatcher', "GLYPH_REMOVED", Update)
	ae.RegisterEvent('Cork ReagentWatcher', "GLYPH_UPDATED", Update)
	
	Update()
end

function Cork:GenerateReagentWatcher(name, reagentSetup)
	local MODULE = name.." Reagents"
	defaults[MODULE.."-enabled"] = true
	defaults[MODULE.."-threshold"] = 40

	local dataobj = ldb:NewDataObject("Cork "..MODULE, {type = "cork"})
	local reagents
	
	function dataobj.Init()
		WatchSpells()
		reagents = {}
		for spellId, data in pairs(reagentSetup) do
			reagents[GetSpellInfo(spellId)] = data
		end
	end
	
	function dataobj.Scan()
		if Cork.dbpc[MODULE.."-enabled"] and IsResting() and not InCombatLockdown() then
			local threshold = Cork.dbpc[MODULE.."-threshold"]
			for spell, data in pairs(reagents) do
				if not data.glyph or not glyphs[data.glyph] then
					local rank = spellRanks[spell]
					local itemId = rank and data[rank]
					local count = itemId and GetItemCount(itemId)
					if count and count < threshold then
						local itemName, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId) 
						dataobj[spell] = IconLine(icon, ("%s (%d/%d)"):format(itemName, count, threshold))
					end
				end
			end
		else
			for spell in pairs(reagents) do
				dataobj[spell] = nil
			end
		end
	end
	
	ae.RegisterEvent("Cork "..MODULE, "BAG_UPDATE", dataobj.Scan)
	ae.RegisterEvent("Cork "..MODULE, "PLAYER_UPDATE_RESTING", dataobj.Scan)
	ae.RegisterEvent("Cork "..MODULE, "SPELLS_CHANGED", dataobj.Scan)
	
	function dataobj.CorkIt(frame)
		if Cork.dbpc[MODULE.."-enabled"] and IsResting() and not InCombatLockdown() then
			local num = GetMerchantNumItems()
			if num and num > 0 then
				for spell, data in pairs(reagents) do
					if dataobj[spell] then
						local item, _, _, _, _, _, _, stackSize = GetItemInfo(data[spellRanks[spell]]) 
						local count = GetItemCount(item)
						local wanted = Cork.dbpc[MODULE.."-threshold"] - count
						if wanted > stackSize then
							wanted = stackSize
						end
						for index = 1, num do
							local merchantItem, _, _, quantity = GetMerchantItemInfo(index)
							if merchantItem == item then
								BuyMerchantItem(index, math.ceil(wanted / (quantity or 1)))
								dataobj[spell] = nil
								break
							end
						end										
					end
				end
			end
		end
	end
	
end
