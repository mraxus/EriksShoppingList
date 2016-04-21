ESL_MAXREAGENTDEPTH = 10;
ESL_ReagentLevel = {}; 

function isLoopingRecipe(currentItemlink, currentReagentLevel) 
	local reagentIndex = ESL_CURREAGENTNUM - 1;
	local currentReagentLevel = ESL_ReagentLevel[reagentIndex]
	while (reagentIndex >= 0) do
		local _,_,_,itemLink = ESL_ListIndex[reagentIndex];

		if ( currentReagentLevel >= ESL_ReagentLevel[reagentIndex]) then
			--eprint(" not lower reagentlevel "..reagentIndex.." -> false");
			return false;
		end

		if ( itemLink == currentItemlink) then
			--eprint(" found match "..ESL_CURREAGENTNUM.." -> "..reagentIndex.." true ");
			return true;
		end

		currentReagentLevel = ESL_ReagentLevel[reagentIndex]
		reagentIndex = reagentIndex - 1;
	end
	--eprint(" finished loop check -> false ");
	return false
end	

function ESL_AddReagentToList( id, itemName, itemLink, itemIcon, reagentLevel, amountNeeded )
	if ( reagentLevel == 0 ) then
		ESL_CURREAGENTNUM = 0;
	end

	if ( isLoopingRecipe(itemlink, reagentLevel) or reagentLevel == ESL_MAXREAGENTDEPTH ) then
		return;
	end
	
	local serviceType, minMade, maxMade, skillType, reagents, recPlayer, recProf, recListNum = ESL_GetRecipeInfo( id );
	
	-- fill button content
	local reagent = _G["ESL_Reagent"..ESL_CURREAGENTNUM]
	if ( not reagent ) then
		-- if button not already present, create one
		reagent = CreateFrame( "Button", "ESL_Reagent"..ESL_CURREAGENTNUM, ESL_ScrollChildFrame, "ESL_ItemTemplate" );
		reagent:Show();
		ESL_NUMBUTTONS = ESL_NUMBUTTONS + 1;
	end

	ESL_ListIndex[ESL_CURREAGENTNUM] = {recPlayer, recProf, recListNum, itemLink};
	ESL_ReagentLevel[ESL_CURREAGENTNUM] = reagentLevel;

	-- check to if displaying tradeskill button
	tradeskillButton = _G["ESL_Reagent"..ESL_CURREAGENTNUM.."_TradeskillButton"];
	if (ESL_CheckButton:GetChecked() and recPlayer==UnitName("player") and recProf~=nil ) then
		tradeskillButton:Show();
		tradeskillButton:SetAttribute("spell", ESL_GetProfessionSkill(recProf));
		craftinfo = ESL_CRAFTSINFO[recProf];
		SetPortraitToTexture("ESL_Reagent"..ESL_CURREAGENTNUM.."_TradeskillButtonNormal", craftinfo["icon"]);
	else
		tradeskillButton:Hide();
	end
	
	-- retreive tradeskill info
	local playerReagentCount;
	if (reagentLevel>0) then
		playerReagentCount = GetItemCount( id );
	else
		playerReagentCount = 0;
	end

	local name = _G["ESL_Reagent"..ESL_CURREAGENTNUM.."Name"];
	local count = _G["ESL_Reagent"..ESL_CURREAGENTNUM.."Count"];
	if ( not itemName or not itemIcon ) then
		reagent:Hide();
		return;
	end
	
	reagent:Show();
	SetItemButtonTexture(reagent, itemIcon);
	name:SetText(itemName);
	
	-- position button
	local reagentX = 8 + 24 * reagentLevel;
	if (ESL_CheckButton:GetChecked()) then reagentX = reagentX + 30; end
	reagent:SetPoint( "TOPLEFT", reagentX, ESL_currentListY );

	-- set name and count text
	if (reagentLevel==0) then
		if (minMade==maxMade) then 
			if (minMade == nil or minMade=="1") then
				count:SetText("");
			else
				count:SetText(minMade.." ");
			end
		else
			count:SetText(minMade.."-"..maxMade);
		end
	else
	-- Grayout items
		if ( playerReagentCount < amountNeeded ) then
			SetItemButtonTextureVertexColor(reagent, 0.5, 0.5, 0.5);
			name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
			creatable = nil;
		else
			SetItemButtonTextureVertexColor(reagent, 1.0, 1.0, 1.0);
			name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			if ( playerReagentCount >= 100 ) then
				playerReagentCount = "*";
			end
		end
	
		count:SetText(playerReagentCount.." /"..amountNeeded);
	end
	
	ESL_currentListY = ESL_currentListY - (reagent:GetHeight()+2);	
	reagent:SetID( ESL_CURREAGENTNUM );
	ESL_TooltipSkillLink[ESL_CURREAGENTNUM] = itemLink;

	ESL_CURREAGENTNUM = ESL_CURREAGENTNUM + 1;
	if (not reagents) then
		return;
	end
	
	if ( playerReagentCount >= amountNeeded and reagentLevel > 0) then 
		-- got more than enough, no need to display subrecipe
		return; 
	end 
	
	if ( not ESL_CheckButton:GetChecked() and recProf ~= ESL_clickedRecipeInfo[4] ) then 
		-- not showing recipes of other professions
		return; 
	end
	
	for k,reagentStr in pairs(reagents) do
		local reagentID, reagentCount = strsplit("x",reagentStr);
		local reagentCount = tonumber( reagentCount );
		local reagentID = tonumber( reagentID );
		
		local reagentName, reagentLink,_,_,_,_,_,_,_,reagentTexture = GetItemInfo( reagentID );
		--eprint("diving deeper for reagent "..reagentID.." ("..playerReagentCount.."//"..reagentCount..")");
		local numneeded = ceil((amountNeeded - playerReagentCount)/minMade);
		ESL_AddReagentToList( reagentID, reagentName, reagentLink, reagentTexture, reagentLevel+1, reagentCount*numneeded)
				
	end
end