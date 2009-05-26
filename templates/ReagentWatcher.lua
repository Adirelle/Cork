local Cork = Cork

function Cork:GenerateReagentWatcher(newReagents)

	local IconLine = Cork.IconLine
	local ldb, ae = LibStub:GetLibrary("LibDataBroker-1.1"), LibStub("AceEvent-3.0")
	
	local GetNumGlyphSockets = GetNumGlyphSockets
	local GetGlyphSocketInfo = GetGlyphSocketInfo
	local GetSpellName = GetSpellName
	local GetSpellInfo = GetSpellInfo
	local GetItemInfo = GetItemInfo
	local GetItemCount = GetItemCount
	
	local bucketFrame = CreateFrame("Frame")
	local buckets = {}

	local defaults = Cork.defaultspc
	defaults['Reagents-enabled'] = true
	defaults['Reagents-stacks'] = 2
	defaults['Reagents-autofill'] = true

	local glyphs = {}
	local reagents = {}
	local names = {}
	local icons = {}
	local counts ={}
	local stackSizes = {}
	
	local autoFilling = false
	local doNotBuy = false
	
	local dataobj
	local db
	
	------------------------------------------------------------
	-- Glyph, spellbook and bags scanning
	------------------------------------------------------------
	
	function bucketFrame.Scan()
		buckets.Scan = nil
		for spell in pairs(reagents) do
			dataobj[spell] = nil
		end		
		if db['Reagents-enabled'] and IsResting() and not InCombatLockdown() then
			local wantedStacks = db['Reagents-stacks']
			for spell, count in pairs(counts) do
				local threshold = wantedStacks * stackSizes[spell]
				if count and count < 0.8*threshold then
					dataobj[spell] = IconLine(icons[spell], ("%s (%d/%d)"):format(names[spell], count, threshold))
				end
			end
		end
	end
	
	function bucketFrame.UpdateCounts()
		wipe(counts)
		doNotBuy = false
		for spell, name in pairs(names) do
			counts[spell] = tonumber(GetItemCount(name))
		end
		buckets.Scan = "UpdateCounts"
		if autoFilling then
			dataobj:CorkIt()
		end
	end
	
	function bucketFrame.UpdateReagents()
		wipe(names)
		wipe(icons)
		wipe(stackSizes)
		for spell, data in pairs(reagents) do
			if not data.glyph or not glyphs[data.glyph] then
				local name, rank = GetSpellInfo(spell)
				if name then
					local itemId = data[tonumber(rank:match("(%d+)")) or 0]
					if itemId then
						names[spell], _, _, _, _, _, _, stackSizes[spell], _, icons[spell] = GetItemInfo(itemId) 
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
	
	dataobj = ldb:NewDataObject('Cork Reagents', {
		type = "cork",
		Scan = bucketFrame.Scan,
	})

	function dataobj:Init()
		db = Cork.dbpc
		buckets.UpdateGlyphs = "Init"
		bucketFrame:Activate()
	end
	
	function dataobj:CorkIt()
		if not bucketFrame:IsShown() or doNotBuy then return end
		local num = GetMerchantNumItems()
		if not num or num == 0 then return end
		local wantedStacks = db['Reagents-stacks']
		local isAutoFilling = autoFilling
		autoFilling = false
		for spell, item in pairs(names) do
			local count, stackSize = counts[spell], stackSizes[spell]
			local wanted = math.min((stackSize * wantedStacks) - count, stackSize)
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
			print('OnClick', checkBox:GetChecked(), db['Reagents-autofill'])
		end)
		checkBox:SetPoint('RIGHT', self, 'RIGHT', -fs:GetStringWidth(), 0)
		
		local slider = LibStub("tekKonfig-Slider").newbare(self, "RIGHT", checkBox, "LEFT")
		slider.tiptext = 'Target stack count. Cork will try to maintain this number of stacks of each watched reagents.'
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
