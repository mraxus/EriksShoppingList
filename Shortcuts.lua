-- TODO: support shift-click to copy-paste link to chat

-- *** Shortcut functions ***
ESL_NUMSHORTCUTS = 5;

local function CreateShortCuts()
	ESL_SHORTCUTS = {};
	for i = 1, ESL_NUMSHORTCUTS, 1 do
		ESL_SHORTCUTS[i] = {};
	end
end

function ESL_ShortcutsInit()
	for i = 1, ESL_NUMSHORTCUTS, 1 do
		local shortcut = _G["ESL_Shortcut"..i];
		if (ESL_SHORTCUTS[i]["icon"] ~= nil) then
			ESL_SetShortcutIcon(shortcut:GetName(), ESL_SHORTCUTS[i]["icon"]);
		end
	end
end

function ESL_FillShortcut(self) 
	--eprint("clicked button "..self:GetName());
	
	local shortcut = self:GetParent();
	ESL_SetShortcut(shortcut:GetID());
	
	ESL_SetShortcutIcon(shortcut:GetName(), ESL_clickedRecipeInfo[2]);
end

function ESL_SetShortcutIcon(shortcut, texture)
	--eprint("setting icon "..shortcut.." to "..texture);
	local iconframe = _G[shortcut.."Slot"];
	SetItemButtonTexture(iconframe, texture);
end

function ESL_SetShortcut(id)
	--eprint("clicked recipe "..link);
	--eprint("shortcut : "..id);
	ESL_SHORTCUTS[id]["link"] = ESL_clickedRecipeInfo[3];
	ESL_SHORTCUTS[id]["icon"] = ESL_clickedRecipeInfo[2];
	ESL_SHORTCUTS[id]["name"] = ESL_clickedRecipeInfo[1];
	ESL_SHORTCUTS[id]["profession"] = ESL_clickedRecipeInfo[4];
end

function ESL_SetShortcutTooltip(self)
	local shortcutId = self:GetParent():GetID();
	
	if (ESL_SHORTCUTS[shortcutId] == nil) then
		return;
	end
	link = ESL_SHORTCUTS[shortcutId]["link"];
	if (link == nil) then
		return;
	end
	--eprint("link : "..link);
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
	GameTooltip:SetHyperlink( link );
	CursorUpdate(self);
end

function ESL_ClickShortcut(self)
	local shortcutId = self:GetParent():GetID();
	ESL_UpdateListWithShortcut(shortcutId);
end

function ESL_UpdateListWithShortcut(shortcutId)	
	if (ESL_SHORTCUTS[shortcutId] == nil) then
		return;
	end
	link = ESL_SHORTCUTS[shortcutId]["link"];
	if (link == nil) then
		return;
	end
	
	name =  ESL_SHORTCUTS[shortcutId]["name"];
	icon =  ESL_SHORTCUTS[shortcutId]["icon"];
	profession = ESL_SHORTCUTS[shortcutId]["profession"];

		--eprint("update with args");

	ESL_SetCurrentRecipe(link, name, icon, profession);
	ESL_UpdateCompleteList();
end

function ESL_GetFirstFilledShortcut()
	for i = 1, ESL_NUMSHORTCUTS, 1 do
		if (ESL_SHORTCUTS[i] ~= nil) then
			return i;
		end
	end
end