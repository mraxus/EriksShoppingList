-- *** Slash commands ***
function ESL_SlashHandler(msg, editbox) 
	if (ESL_Frame:IsVisible()) then
		ESL_Frame:Hide();
	else
		if (ESL_Reagent0Name:GetText() == nil) then
			--eprint("empty, trying to fill with shortcut");
			ESL_ShortcutsInit();
			local shortcutId = ESL_GetFirstFilledShortcut();
			--eprint("first filled shortcut "..shortcutId);
			if (shortcutId ~= nil) then
				ESL_UpdateListWithShortcut(shortcutId);
			end
		--else
		--	eprint("text : "..ESL_Reagent0Name:GetText());
		end
		ESL_Frame:Show();
	end
end

local function PrintRecipes(tradeskillName)
	local playername = UnitName("player");
	if (ESL_CRAFTSDB[playername] == nil) then
		eprint(" player not found: "..playername);
		return;
	end
	if (ESL_CRAFTSDB[playername][tradeskillName] ~= nil) then
		if (#ESL_CRAFTSDB[playername][tradeskillName] > 0) then
			for id, recipeString in pairs(ESL_CRAFTSDB[playername][tradeskillName]) do
				eprint ("   "..id.." - "..string.gsub(recipe,"|"," | "));
			end
		else
			eprint(" no recipes found for "..tradeskillName);
		end
	else
		eprint(" tradeskill "..tradeskillName.." not found");
	end 
end

function ESL_DebugSlashHandler(msg, editbox) 
	cmd, detail = msg:match("^(%S*)%s*(.-)$");
	eprint ("debug command "..cmd.." ('"..detail.."')");	
	if (cmd == "recipes") then
		if (detail ~= nil and detail ~= "") then
			PrintRecipes(detail);
		end
		return
	end
	if (cmd == "test") then
		local link;
			local _, link = GetItemInfo(detail);
			eprint ("link is "..link);
	end
	if (cmd == "maxdepth") then
		ESL_MAXREAGENTDEPTH = tonumber(detail);
		eprint("max reagent depth : "..detail);
	end
end

SLASH_ESL1 = "/esl";
SLASH_ESLDEBUG1 = "/esldebug";
SlashCmdList["ESL"] = ESL_SlashHandler;
SlashCmdList["ESLDEBUG"] = ESL_DebugSlashHandler;