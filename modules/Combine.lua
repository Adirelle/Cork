
local Cork = Cork
local IconLine = Cork.IconLine
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")

local ITEMS = {
	[37700] = 10, -- Crystallized Air
	[37701] = 10, -- Crystallized Earth
	[37702] = 10, -- Crystallized Fire
	[37703] = 10, -- Crystallized Shadow
	[37704] = 10, -- Crystallized Life
	[37705] = 10, -- Crystallized Water
	[33567] = 5,  -- Borean Leather Scraps
	[34056] = 3,  -- Lesser Cosmic Essence
}

Cork.defaultspc["Combine-enabled"] = true

local dataobj = ldb:NewDataObject("Cork Combine", {type = "cork"})

function dataobj:Scan()
	if Cork.dbpc["Combine-enabled"] and not InCombatLockdown() then
		for id,threshold in pairs(ITEMS) do
			local count = GetItemCount(id) or 0
			if count >= threshold then
				local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(id) 
				dataobj[id] = IconLine(itemTexture, itemName.." ("..count..")")
			end
		end
	else
		for id in pairs(ITEMS) do
			dataobj[id] = nil
		end
	end
end

ae.RegisterEvent("Cork Combine", "BAG_UPDATE", dataobj.Scan)

function dataobj:CorkIt(frame)
	for id,threshold in pairs(ITEMS) do
		if dataobj[id] and frame:SetManyAttributes("type1", "item", "item1", "item:"..id) then
			dataobj[id] = nil -- Do not use it again before bags are updated
			return true
		end
	end
end
