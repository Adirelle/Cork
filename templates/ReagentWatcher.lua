local Cork = Cork

-- Use a lazily-created cork singleton that will handle all reagents
function Cork:GenerateReagentWatcher(newReagents)

	local IconLine = Cork.IconLine
	local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")

	local GetNumGlyphSockets = GetNumGlyphSockets
	local GetGlyphSocketInfo = GetGlyphSocketInfo
	local GetSpellName = GetSpellName
	local GetSpellInfo = GetSpellInfo
	local GetItemInfo = GetItemInfo
	local GetItemCount = GetItemCount
	local GetMerchantItemInfo = GetMerchantItemInfo

	local buckets = {}
	local bucketFrame = CreateFrame("Frame")
	bucketFrame:Hide()

	local defaults = Cork.defaultspc
	defaults['Reagents-enabled'] = true
	defaults['Reagents-stacks'] = 2
	defaults['Reagents-autofill'] = true

	local reagents = {}

	local glyphs = {}
	local items = {}
	local icons = {}
	local counts = {}
	local stackSizes = {}
	local stackObjectives = {}

	local autoFilling = false
	local doNotBuy = false

	local dataobj
	local db

	------------------------------------------------------------
	-- Glyph, spellbook and bags scanning
	------------------------------------------------------------

	function bucketFrame.Scan()
		local wantedStacks = db['Reagents-stacks']
		for item in pairs(items) do
			local count = counts[item]
			local threshold = (stackObjectives[item] or wantedStacks) * stackSizes[item]
			if count and count < 0.8*threshold then
				dataobj[item] = IconLine(icons[item], ("%s (%d/%d)"):format(item, count, threshold))
			else
				dataobj[item] = nil
			end
		end
	end

	function bucketFrame.UpdateCounts()
		wipe(counts)
		doNotBuy = false
		for item in pairs(items) do
			counts[item] = tonumber(GetItemCount(item))
		end
		buckets.Scan = "UpdateCounts"
		if autoFilling then
			dataobj:CorkIt()
		end
	end

	function bucketFrame.UpdateReagents()
		for item in pairs(items) do
			dataobj[item] = nil
		end
		wipe(items)
		wipe(icons)
		wipe(stackSizes)
		wipe(stackObjectives)
		for spell, data in pairs(reagents) do
			if not data.glyph or not glyphs[data.glyph] then
				local spellName, rank = GetSpellInfo(spell)
				local itemId = spellName and data[(rank and tonumber(rank:match("(%d+)"))) or 1]
				if itemId then
					local item, _, _, _, _, _, _, stackSize, _, icon = GetItemInfo(itemId)
					items[item], stackSizes[item], icons[item] = true, stackSize, icon
					if not data.wantMany then
						stackObjectives[item] = 1
					end
				end
			end
		end
		buckets.UpdateCounts = "UpdateReagents"
	end

	function bucketFrame.UpdateGlyphs()
		wipe(glyphs)
		for index = 1, GetNumGlyphSockets() do
			local _, _, id = GetGlyphSocketInfo(index)
			if id then
				glyphs[id] = true
			end
		end
		buckets.UpdateReagents = "UpdateGlyphs"
	end

	------------------------------------------------------------
	-- Create the cork
	------------------------------------------------------------

	dataobj = ldb:NewDataObject('Cork Reagents', {type = "cork"})

	function dataobj:Init()
		db = Cork.dbpc
		buckets.UpdateGlyphs = "Init"
	end

	function dataobj:Scan()
		buckets.Scan = "Scan"
		bucketFrame:Activate()
	end

	-- Autobuying stuff
	function dataobj:CorkIt()
		if not bucketFrame:IsShown() or doNotBuy or MainMenuBarBackpackButton.freeSlots == 0 then return end
		local num = GetMerchantNumItems()
		if not num or num == 0 then return end
		local wantedStacks = db['Reagents-stacks']
		local isAutoFilling = autoFilling
		autoFilling = false
		for item in pairs(items) do
			local count, stackSize = counts[item], stackSizes[item]
			local wanted = math.min((stackSize * (stackObjectives[item] or wantedStacks)) - count, stackSize)
			if wanted > 0 then
				for index = 1, num do
					local merchantItem, _, _, quantity = GetMerchantItemInfo(index)
					if merchantItem == item then
						BuyMerchantItem(index, math.ceil(wanted / (quantity or 1)))
						autoFilling = isAutoFilling
						doNotBuy = true
						break
					end
				end
			end
		end
	end

	-- Handle autofilling when talking to a merchant
	ae.RegisterEvent(dataobj, "MERCHANT_SHOW", function()
		if db['Reagents-autofill'] then
			autoFilling = true
			dataobj:CorkIt()
		end
	end)

	------------------------------------------------------------
	-- Homebrew Event buckecting to reduce CPU usage
	------------------------------------------------------------

	local bucketOrder = { "UpdateGlyphs", "UpdateReagents", "UpdateCounts", "Scan" }
	local BUCKET_COUNT = #bucketOrder
	bucketFrame:SetScript('OnUpdate',  function(self)
		if next(buckets) then
			for i = 1, BUCKET_COUNT do
				local bucket = bucketOrder[i]
				if buckets[bucket] then
					self[bucket]()
				end
			end
			wipe(buckets)
		end
	end)

	bucketFrame:SetScript('OnShow', function() buckets.UpdateCounts = "OnShow" end)

	bucketFrame:SetScript('OnHide', function()
		for item in pairs(items) do
			dataobj[item] = nil
		end
	end)

	function bucketFrame:BucketEvent(arg, event)
		buckets[arg] = buckets[arg] or event
	end

	function bucketFrame:Activate()
		if db['Reagents-enabled'] and IsResting() and not InCombatLockdown() then
			self:Show()
		else
			self:Hide()
		end
	end

	ae.RegisterEvent(bucketFrame, "BAG_UPDATE", "BucketEvent", "UpdateCounts")
	ae.RegisterEvent(bucketFrame, "PLAYER_UPDATE_RESTING", "BucketEvent", "Scan")
	ae.RegisterEvent(bucketFrame, "SPELLS_CHANGED", "BucketEvent", "UpdateReagents")
	ae.RegisterEvent(bucketFrame, "PLAYER_TALENT_UPDATE", "BucketEvent", "UpdateGlyphs")
	ae.RegisterEvent(bucketFrame, "GLYPH_ADDED", "BucketEvent", "UpdateGlyphs")
	ae.RegisterEvent(bucketFrame, "GLYPH_REMOVED", "BucketEvent", "UpdateGlyphs")
	ae.RegisterEvent(bucketFrame, "GLYPH_UPDATED", "BucketEvent", "UpdateGlyphs")
	ae.RegisterEvent(bucketFrame, "PLAYER_REGEN_DISABLED", "Activate")
	ae.RegisterEvent(bucketFrame, "PLAYER_REGEN_ENABLED", "Activate")
	ae.RegisterEvent(bucketFrame, "PLAYER_UPDATE_RESTING", "Activate")

	------------------------------------------------------------
	-- Configuration frame
	------------------------------------------------------------

	local configFrame = CreateFrame("Frame", nil, Cork.config)
	configFrame:SetWidth(1)
	configFrame:SetHeight(1)
	dataobj.configframe = configFrame
	configFrame:Hide()

	configFrame:SetScript("OnShow", function(self)
		local checkBox, fs = LibStub("tekKonfig-Checkbox").new(self, nil, "Autofill", "RIGHT", slider)
		checkBox.tiptext = "Autofilling. Check this to have Cork automatically refill your stock when speaking to merchants."
		checkBox:HookScript('OnClick', function()
			db['Reagents-autofill'] = not not checkBox:GetChecked()
		end)
		checkBox:SetPoint('RIGHT', self, 'RIGHT', -fs:GetStringWidth(), 0)

		local slider = LibStub("tekKonfig-Slider").newbare(self, "RIGHT", checkBox, "LEFT")
		slider.tiptext = 'Target stack count. Cork will try to maintain this number of stacks of heavily-used reagents.'
		slider:SetWidth(72)
		slider:SetMinMaxValues(1,5)
		slider:SetValueStep(1)

		local sliderText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		sliderText:SetPoint("RIGHT", slider, "LEFT")

		slider:SetScript("OnValueChanged", function(self, newvalue)
			newvalue = math.floor(newvalue)
			db['Reagents-stacks'] = newvalue
			sliderText:SetFormattedText("%d", newvalue)
			dataobj:Scan()
		end)

		local function Update()
			slider:SetValue(db['Reagents-stacks'])
			checkBox:SetChecked(db['Reagents-autofill'])
		end

		configFrame:SetScript("OnShow", Update)
		Update()
	end)

	------------------------------------------------------------
	-- Reagent registering
	------------------------------------------------------------

	local function AddReagents(Cork, newReagents)
		for id, data in pairs(newReagents) do
			local spell = GetSpellInfo(id)
			if spell then
				reagents[spell] = data
			end
		end
		buckets.UpdateReagents = "AddReagents"
		return dataobj
	end

	Cork.GenerateReagentWatcher = AddReagents

	return AddReagents(Cork, newReagents)
end
