
local myname, Cork = ...
local UnitAura = UnitAura
local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")


local spellname, _, icon = GetSpellInfo(57139)

local iconline = Cork.IconLine(icon, spellname)

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Cork "..spellname, {type = "cork", lowpriority = true, tiptext = "Warn when you are not well fed."})

Cork.defaultspc[spellname.."-enabled"] = UnitLevel("player") >= 10
Cork.defaultspc[spellname.."-macro"] = ""

local function Test(unit) if Cork.dbpc[spellname.."-enabled"] and not UnitAura("player", spellname) and not (IsResting() and not Cork.db.debug) then return iconline end end

LibStub("AceEvent-3.0").RegisterEvent("Cork "..spellname, "UNIT_AURA", function(event, unit) if unit == "player" then dataobj.custom = Test() end end)
LibStub("AceEvent-3.0").RegisterEvent("Cork "..spellname, "PLAYER_UPDATE_RESTING", function() dataobj.custom = Test() end)

function dataobj:Scan() self.custom = Test() end

function dataobj:CorkIt(frame)
	local macro = Cork.dbpc[spellname.."-macro"]
	if self.custom and macro and macro ~= "" then return frame:SetManyAttributes("type1", "macro", "macrotext1", macro) end
end


----------------------
--      Config      --
----------------------

local frame = CreateFrame("Frame", nil, Cork.config)
frame:SetWidth(1) frame:SetHeight(1)
dataobj.configframe = frame
frame:Hide()

frame:SetScript("OnShow", function()
	local function MakeMacro()
		local infotype, itemid, itemlink = GetCursorInfo()
		if infotype == "merchant" then itemid = tonumber(GetMerchantItemLink(itemid):match("item:(%d+):")) end
		if infotype == "item" or infotype == "merchant" then Cork.dbpc[spellname.."-macro"] = "/use item:"..itemid end
		return ClearCursor()
	end


	local editbox = CreateFrame("EditBox", nil, frame)
	editbox:SetWidth(300)
	editbox:SetPoint("RIGHT")
	editbox:SetFrameStrata("DIALOG")
	editbox:Hide()
	editbox:SetFontObject(GameFontHighlightSmall)
	editbox:SetTextInsets(8,8,8,8)
	editbox:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4}
	})
	editbox:SetBackdropColor(.3, .1, .1, 1)
	editbox:SetMultiLine(true)
	editbox:SetAutoFocus(true)
	editbox:SetScript("OnShow", function(self) self:SetText(Cork.dbpc[spellname.."-macro"]) end)
	editbox:SetScript("OnHide", function(self) Cork.dbpc[spellname.."-macro"] = self:GetText() end)
	editbox:SetScript("OnEscapePressed", editbox.Hide)
	editbox:SetScript("OnReceiveDrag", function()
		MakeMacro()
		self:SetText(Cork.dbpc[spellname.."-macro"])
	end)


	local butt = LibStub("tekKonfig-Button").new_small(frame, "RIGHT")
	butt:SetWidth(60) butt:SetHeight(18)
	butt.tiptext = "Click to edit macro, or drop an item to automatically generate a macro."
	butt:SetText("Macro")
	butt:SetScript("OnClick", function() editbox:Show() end)
	butt:SetScript("OnReceiveDrag", MakeMacro)


	frame:SetScript("OnHide", function() editbox:Hide() end)
	frame:SetScript("OnShow", nil)
end)


local orig = IsOptionFrameOpen
function IsOptionFrameOpen(...)
	if not frame:IsVisible() then return orig(...) end
end
