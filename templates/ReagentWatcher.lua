local Cork = Cork
local IconLine = Cork.IconLine
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")
local defaults = Cork.defaultspc

function Cork:GenerateReagentWatcher(name, items)
	local MODULE = name.." Reagents"
	defaults[MODULE.."-enabled"] = true
	defaults[MODULE.."-threshold"] = 20

	local dataobj = ldb:NewDataObject("Cork "..MODULE, {type = "cork"})

	local function Test()
	end
	
	function dataobj:Scan()
		if Cork.dbpc[MODULE.."-enabled"] and IsResting() and not InCombatLockdown() then
			dataobj.player = Test()
		else
			dataobj.player = nil
		end
	end
	
	ae.RegisterEvent("Cork "..MODULE, "BAG_UPDATE", dataobj.Scan)
	ae.RegisterEvent("Cork "..MODULE, "PLAYER_UPDATE_RESTING", dataobj.Scan)
	ae.RegisterEvent("Cork "..MODULE, "SPELLS_CHANGED", dataobj.Scan)
	
end
