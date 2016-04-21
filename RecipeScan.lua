-- *** Recipe scanning functions ***
-- TODO: fix recipe scanning !!!!!

invSlotID = nil;

CreateFrame("GameTooltip", "ESLDataScanTooltip", UIParent, "GameTooltipTemplate")
ESLDataScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local SkillTypeToColor = {
	["trivial"] = 0,		-- grey
	["easy"] = 1,			-- green
	["medium"] = 2,		-- yellow
	["optimal"] = 3,		-- orange
}

local DefaultCraftInfo = {
	["icon"] = "Interface\\Icons\\Trade_Engineering";
}

local function GetInvSlotID()
	-- The purpose of this function is to get the invSlotID in a UI independant way	(same as GetSubClassID)
	-- ie: without relying on UIDropDownMenu_GetSelectedID(TradeSkillInvSlotDropDown), which uses a hardcoded frame name.

	if GetTradeSkillInvSlotFilter(0) then		-- if "All Slots" is selected, GetTradeSkillInvSlotFilter() will return 1 for all indexes, including 0
		return 1				-- thus return 1 as selected id	(as would be returned by  UIDropDownMenu_GetSelectedID(TradeSkillInvSlotDropDown))
	end

	local filter
	for i = 1, #invSlots do
	   filter = GetTradeSkillInvSlotFilter(i)
	   if filter then
	      return i+1			-- ex: 3rd element of the invSlots array, but 4th in the dropdown due to "All Slots", so return i+1
	   end
	end
end

local function SaveActiveFilters()
	selectedTradeSkillIndex = GetTradeSkillSelectionIndex()
	
	subClasses = GetTradeSkillSubClasses()
	invSlots = GetTradeSkillInvSlots()
	invSlotID = GetInvSlotID()

	-- Inventory slots
	SetTradeSkillInvSlotFilter(0, 1, 1)		-- this checks "All slots"
	if TradeSkillInvSlotDropDown then
		UIDropDownMenu_SetSelectedID(TradeSkillInvSlotDropDown, 1)
	end
	
	-- Have Materials
	if TradeSkillFrameAvailableFilterCheckButton then
		haveMats = TradeSkillFrameAvailableFilterCheckButton:GetChecked()	-- nil or true
		TradeSkillFrameAvailableFilterCheckButton:SetChecked(false)
	end
	TradeSkillOnlyShowMakeable(false)
end

local function SaveHeaders()
	local headersState = {}
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.
	
	for i = GetNumTradeSkills(), 1, -1 do		-- 1st pass, expand all categories
		local _, skillType, _, isExpanded  = GetTradeSkillInfo(i)
		 if (skillType == "header") then
			headerCount = headerCount + 1
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
				headersState[headerCount] = true
			end
		end
	end
	return headersState;
end

local function RestoreHeaders(headersState)
	local headerCount = 0
	for i = GetNumTradeSkills(), 1, -1 do
		local _, skillType  = GetTradeSkillInfo(i)
		if (skillType == "header") then
			headerCount = headerCount + 1
			if headersState[headerCount] then
				CollapseTradeSkillSubClass(i)
			end
		end
	end
	wipe(headersState)
end

local function RestoreActiveFilters()
	
	-- Inventory slots
	invSlotID = invSlotID or 1
	SetTradeSkillInvSlotFilter(invSlotID-1, 1, 1)	-- this checks the previously checked value
	
	-- frame = TradeSkillInvSlotDropDown
	-- if frame then
	-- 	local text = (invSlotID == 1) and ALL_INVENTORY_SLOTS or invSlots[invSlotID-1]
	-- 	UIDropDownMenu_SetSelectedID(frame, invSlotID)
	-- 	UIDropDownMenu_SetText(frame, text);
	-- end
	
	-- invSlotID = nil
	-- wipe(invSlots)
	-- invSlots = nil
	
	-- Have Materials
	if TradeSkillFrameAvailableFilterCheckButton then
		TradeSkillFrameAvailableFilterCheckButton:SetChecked(haveMats or false)
	end
	TradeSkillOnlyShowMakeable(haveMats or false)
	haveMats = nil
	
	SelectTradeSkill(selectedTradeSkillIndex)
	selectedTradeSkillIndex = nil
end

local function InitializeCraftsDbIfNecessary(pname, tradeskillName)
	if ( ESL_CRAFTSDB==nil ) then	ESL_CRAFTSDB = {}; end
	if ( ESL_CRAFTSDB[ pname ] == nil ) then ESL_CRAFTSDB[ pname ] = {}; end
	if ( ESL_CRAFTSDB[ pname ][ tradeskillName ] == nil ) then ESL_CRAFTSDB[ pname ][ tradeskillName ] = {}; end 
end

local function NotReadyForScan()
	local tradeskillName = GetTradeSkillLine()
	if not tradeskillName or tradeskillName == "UNKNOWN" then
		--eprint(" scan aborted: no tradeskillname");
	-- may happen after a patch, or under extreme lag, so do not save anything to the db !
		return true;
	end		

	local numTradeSkills = GetNumTradeSkills()
	if not numTradeSkills or numTradeSkills == 0 then 
		--eprint(" scan aborted: no recipes");
		return true;
	end
	
	local skillName, skillType = GetTradeSkillInfo(1)	-- test the first line
	if skillType ~= "header" then 
		--eprint(" scan aborted: first line is NOT header");
	-- skip scan if first line is not a header.
		return true;
	end
	return false;
end

local function UpdateCraftsIcon(tradeskillName)
	if ( ESL_CRAFTSINFO[tradeskillName] == nil) then
		ESL_CRAFTSINFO[tradeskillName] = DefaultCraftInfo;
		--eprint("craftinfo was nil for "..tradeskillName);
	--eprint("default craftinfo icon is  "..DefaultCraftInfo["icon"]);
	end;
	ESL_CRAFTSINFO[tradeskillName]["icon"] = GetTradeSkillTexture();
end

local function CustomGetTradeSkillReagentItemLink( recipeIndex, reagentIndex)
	local tooltip = ESLDataScanTooltip;
	tooltip:ClearLines();
	tooltip:SetTradeSkillItem(recipeIndex, reagentIndex);
	local _, link = tooltip:GetItem();
	return link;
end

local function GetReagentStrings(recipeIndex)
	local reagents = {};
	local numReagents = GetTradeSkillNumReagents(recipeIndex);
	--eprint ("    recipe "..recipeIndex.." has "..numReagents.." reagents");

	for reagentIndex = 1, numReagents, 1 do
		local _,_,reagentCount = GetTradeSkillReagentInfo( recipeIndex, reagentIndex);
		--eprint("    recipe "..recipeIndex.." needs "..reagentCount.." of [#"..reagentIndex.."]");
		if (reagentCount ~= nil) then 
			--local link = GetTradeSkillReagentItemLink( recipeIndex, reagentIndex); -- known bug in 5.2.0: always returns nil
			local link = CustomGetTradeSkillReagentItemLink( recipeIndex, reagentIndex);
			if (link ~= nil) then
				reagentID = ESL_GetIdFromLink( link );
				--eprint("        reagentID : "..reagentID);
				table.insert( reagents, reagentID.."x"..reagentCount);
			else
				--eprint ("    no link for recipe "..recipeIndex.." reagent nr "..reagentIndex);
			end
		else
			--eprint ("    no reagentcount for recipe "..recipeIndex);
		end
	end
	return reagents;
end

local function UpdateCrafts(crafts)

	for i = 1, GetNumTradeSkills() do

		local skillName, skillType = GetTradeSkillInfo(i);
		if skillType ~= "header" and skillType ~= "subheader" then

			----eprint (skillName.." is not header");
			-- handle reagents

			local reagents = GetReagentStrings(i);
			if (#reagents > 0) then
				local minMade, maxMade = GetTradeSkillNumMade(i);
				local link = GetTradeSkillItemLink(i);
				local recipeId = ESL_GetIdFromLink(link);

				crafts[recipeId] = i.."|"..minMade.."|"..maxMade.."|"..SkillTypeToColor[skillType].."|"..table.concat( reagents, ";");
				----eprint ("   "..string.gsub(crafts[recipeId],"|"," | "));
			else
				----eprint ("no reagents for recipe "..i);
			end
		else
			----eprint (skillType.." is a header");
		end
	end
end

local function ScanRecipes()
	--eprint("recipe scan");

	if (NotReadyForScan()) then
		return false;
	end
	--eprint("ready for recipe scan");
	local pname = UnitName("player");
	local tradeskillName = GetTradeSkillLine();

	--eprint("init craftsdb");
	InitializeCraftsDbIfNecessary(pname, tradeskillName);

	--eprint("update craft icon");
	UpdateCraftsIcon(tradeskillName);

	--eprint("starting recipe scan");
	UpdateCrafts( ESL_CRAFTSDB[ pname ][ tradeskillName ] );
	
	--eprint("finished recipe scan");
	return true;
end

function ESL_ScanTradeSkills()
	--eprint("preparing for scan");
	local namefilter = GetTradeSkillItemNameFilter();
	SetTradeSkillItemNameFilter( "" );
	SaveActiveFilters();
	local headersState = SaveHeaders();
	local scanSuccessful = ScanRecipes();
	RestoreHeaders(headersState);
	RestoreActiveFilters();
	SetTradeSkillItemNameFilter( namefilter );
	return scanSuccessful;
end