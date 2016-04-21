-- TODO: fix window should hide when at main menu
-- TODO: check version at startup and delete local vars if necessary

-- *** constants ***
ESL_CURRENTRECIPESVERSION = 2;
ESL_CURRENTSHORTCUTSVERSION = 1;
ESL_NUMBUTTONS = 0;

-- *** globals ***
ESL_ListAllButton = nil;
ESL_ListIndex = {}
ESL_TooltipSkillLink = {}
ESL_clickedRecipeInfo = {}
ESL_currentListY = 0;
-- *** Scanning functions ***

local selectedTradeSkillIndex
local subClasses, subClassID
local invSlots, invSlotID
local haveMats
local checkedOpening

local ProfessionSkill = {
	["Alchemy"] = "Alchemy",
	["Blacksmithing"] = "Blacksmithing",
	["Enchanting"] = "Enchanting",
	["Engineering"] = "Engineering",
	["Inscription"] = "Inscription",
	["Jewelcrafting"] = "Jewelcrafting",
	["Leatherworking"] = "Leatherworking",
	["Tailoring"] = "Tailoring",
	["Mining"] = "Smelting",
	["First Aid"] = "First Aid",
	["Cooking"] = "Cooking",
		
	-- german --
	["Bergbau"] = "Verhüttung",
	
	-- spanish --
	["Minería"] = "Fundición",
	
	-- french --
	["Minage"] = "Fondre",
	
	-- Русский --
	["Горное дело"] = "Выплавка металлов",
}

function ESL_GetIdFromLink( link )
	return tonumber(link:match("enchant:(%d+)") or link:match("item:(%d+)"));		-- this actually extracts the spellID
end

-- *** Events ***

function ESL_OnLoad( self )
	--eprint("Onload");
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("TRADE_SKILL_SHOW");
	self:RegisterEvent("TRADE_SKILL_CLOSE");
	self:RegisterEvent("TRADE_SKILL_FILTER_UPDATE");	
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	self:RegisterForDrag("LeftButton");
	ESL_Reagent0Name:SetTextColor(YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b);
	
	ESL_Frame:SetFrameStrata("FULLSCREEN_DIALOG")
	ESL_Frame_minimized:SetFrameStrata("FULLSCREEN_DIALOG")
end

local function CreateShortCuts()
	ESL_SHORTCUTS = {};
	for i = 1, ESL_NUMSHORTCUTS, 1 do
		ESL_SHORTCUTS[i] = {};
	end
end
local function InitSavedVars() 
	if (ESL_RECIPESVERSION == nil or ESL_RECIPESVERSION < ESL_CURRENTRECIPESVERSION) then
		ESL_RECIPESVERSION = ESL_CURRENTRECIPESVERSION
		ESL_CRAFTSINFO = {};
		ESL_CRAFTSDB = {};
		ESL_CRAFTSINFO = {};
	end
	if (ESL_SHORTCUTSVERSION == nil or ESL_SHORTCUTSVERSION < ESL_CURRENTSHORTCUTSVERSION) then
		ESL_SHORTCUTSVERSION = ESL_CURRENTSHORTCUTSVERSION
		CreateShortCuts();
	end
end

function ESL_Event(self, event, ...)
    if ( event == "ADDON_LOADED" ) then
		-- add "list all" button to tradeskill window
		ESL_ListAllButton = CreateFrame( "Button", "ListAllButton", TradeSkillDetailScrollChildFrame, "ESL_ShowButton" );
		ESL_ListAllButton:SetPoint("LEFT", TradeSkillReagentLabel, "RIGHT", 2, 4 );
		ESL_ListAllButton:Show();
		InitSavedVars();
		ESL_ShortcutsInit();
	elseif ( event == "TRADE_SKILL_SHOW" ) then
		ESL_Frame:ClearAllPoints();
		ESL_Frame:SetPoint( "TOPLEFT", TradeSkillFrame, "TOPRIGHT", 8, 13);
		ESL_Frame:SetPoint( "BOTTOMRIGHT", TradeSkillFrame, "BOTTOMRIGHT", 280, -2);
		checkedOpening = ESL_ScanTradeSkills();
	elseif ( event == "TRADE_SKILL_CLOSE" ) then
		--ESL_Frame:Hide();
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		self:RegisterEvent("BAG_UPDATE");
		self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	elseif ( event == "BAG_UPDATE" ) then
		if (ESL_Frame:IsShown()) then
			ESL_UpdateCompleteList()
		end
	end
end

function ESL_GetProfessionSkill(profession)
	local skillName = ProfessionSkill[profession];
	if (skillName == nil) then 
		return profession;
	end
	return skillName;
end

local function HideMinimized()
	if (ESL_Frame_minimized:IsVisible()) then
		ESL_Frame_minimized:ClearAllPoints();
		ESL_Frame_minimized:Hide();
	end
end

function ESL_SetCurrentRecipe(link, name, icon, profession)
	ESL_clickedRecipeInfo[3] = link;
	ESL_clickedRecipeInfo[1] = name;
	ESL_clickedRecipeInfo[2] = icon;
	ESL_clickedRecipeInfo[4] = profession;
end
	
function ESL_ListButtonClicked()	
		
	HideMinimized();
	local index = GetTradeSkillSelectionIndex();
	local skillName = GetTradeSkillInfo( index );
	local link = GetTradeSkillItemLink( index );
	local icon = GetTradeSkillIcon( index );
	local profession = GetTradeSkillLine();

	ESL_SetCurrentRecipe(link, skillName, icon, profession);
	
	if (not checkedOpening) then
		checkedOpening = ESL_ScanTradeSkills();
	end;	
	ESL_UpdateCompleteList();
	ESL_Frame:Show();
end
		
function ESL_UpdateCompleteList()
	
	local link = ESL_clickedRecipeInfo[3];
	local name = ESL_clickedRecipeInfo[1];
	local icon = ESL_clickedRecipeInfo[2];
	local profession = ESL_clickedRecipeInfo[4];

	if (profession == nil) then
		return;
	end

	ESL_tradeskillbutton:SetAttribute("spell",ESL_GetProfessionSkill(profession));
	ESL_tradeskillbutton:SetText("show "..ESL_GetProfessionSkill(profession));
	
	ESL_Frame_minimizedIconFrameTexture:SetTexture(icon);
	ESL_Frame_minimizedIconFrame:SetID(1);

	local index = tonumber(link:match("enchant:(%d+)") or link:match("item:(%d+)"));
	
	--eprint("texture : "..GetTradeSkillTexture());
	--fill buttons with reagent content
	ESL_currentListY = - 8;
	ESL_AddReagentToList( index, name, link, icon, 0, 1 );
	ESL_AddonNameMin:SetText( name );
	
	--hide non-used buttons 
	--eprint("hiding buttons "..ESL_CURREAGENTNUM.." to "..ESL_NUMBUTTONS);
	local reagent = _G["ESL_Reagent0"];
	for i=ESL_CURREAGENTNUM, ESL_NUMBUTTONS-1, 1 do
		_G["ESL_Reagent"..i]:Hide();
	end	
	
	ESL_NUMBUTTONS = ESL_CURREAGENTNUM;
	local h;
	if (ESL_NUMBUTTONS > 7) then
		ESL_ScrollChildFrame:SetHeight( (reagent:GetHeight()+2) * ESL_NUMBUTTONS );
		ESL_ScrollFrame:EnableDrawLayer("BACKGROUND");
	else
		ESL_ScrollChildFrame:SetHeight( ESL_ScrollFrame:GetHeight()-10 );
		ESL_ScrollFrame:DisableDrawLayer("BACKGROUND");
	end
end

function ESL_SetGameToolTip( self )
	local id = self:GetID();
	--eprint("tooltip : "..id);
	if (not id or id <= 0) then
		return;
	end
	--eprint("link : "..ESL_TooltipSkillLink[id]);
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
	GameTooltip:SetHyperlink( ESL_TooltipSkillLink[id] );
	CursorUpdate(self);
end

function ESL_ClickReagent( self )
	-- TODO: replace rc with better name

	local id = self:GetID();
	--eprint("clicked recipe "..self:GetID());
	local rec = ESL_ListIndex[id];
	local link = rec[4];
	
	if ( not HandleModifiedItemClick( link )) then
		if ( rec and rec[1] == UnitName("player") ) then
			--eprint ("clicked "..(rec[1] or ".")..", "..(rec[2] or ".")..", "..(rec[3] or "."));
			if ( rec[2] ~= GetTradeSkillLine()) then 
				return 
			end
			
			-- reset all tradeskill filters
			SetTradeSkillInvSlotFilter(0);
			SetTradeSkillItemLevelFilter(0, 5000);
			SetTradeSkillItemNameFilter("");
			
			local skillType, isExpanded;
			for i = GetNumTradeSkills(), 1, -1 do		-- 1st pass, expand all categories
				_, skillType, _, isExpanded  = GetTradeSkillInfo(i)
				if (skillType == "header" and not isExpanded) then
						ExpandTradeSkillSubClass(i)
				end
			end
			
			TradeSkillFrame_SetSelection( rec[3] );
			TradeSkillFrame_Update();
		end
	end
end		

function ESL_OnToggleMinimize()
	if (ESL_Frame:IsVisible()) then
		ESL_Frame_minimized:Show();
		ESL_Frame:ClearAllPoints();
		ESL_Frame_minimized:ClearAllPoints();
		ESL_Frame_minimized:SetPoint("TOPRIGHT", ESL_Frame, -19, -10);
		ESL_Frame:Hide();
	else
		ESL_Frame:Show();
		ESL_Frame_minimized:ClearAllPoints();
		ESL_Frame:ClearAllPoints();
		ESL_Frame:SetPoint("TOPRIGHT", ESL_Frame_minimized, 19, 10);
		ESL_Frame_minimized:Hide();
	end
end		
				
function eprint( msg )
	--print("ESL: "..msg);
	DEFAULT_CHAT_FRAME:AddMessage("|cffaaaa44ESL|r: "..msg);
end

