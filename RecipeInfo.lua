local function GetRecipeFromPlayer( id, playername )
	for tradeskillname, recipes in pairs(ESL_CRAFTSDB[ playername ]) do
		local recipe = recipes[id];
		if (recipe) then 
			--eprint ("found recipeFromPlayer "..string.gsub(recipe,"|"," | "));
			return tradeskillname, recipe;
		end
	end
end

local function GetRecipeFromOtherPlayers( id, excludePlayername )
	for playername, tradeskills in pairs( ESL_CRAFTSDB ) do
		if (playername ~= excludePlayername) then
			local tradeskillname, recipe = GetRecipeFromPlayer( id, playername );
			if (recipe) then 
				return playername, tradeskillname, recipe;
			end
		end
	end
end

function ESL_GetRecipeInfo( id )
	local recipe;
	local tradeskillName = "";
	local player = UnitName("player");
	-- first check current player
	--eprint ("first checking player "..player);
	tradeskillName, recipe = GetRecipeFromPlayer( id, player );
	
	if (recipe==nil) then --not found at current player, check others
		--eprint("checking other players");
		player, tradeskillName, recipe = GetRecipeFromOtherPlayers( id, player );
		
		if (recipe==nil) then 
			--eprint ("recipe not found at any player");
			return nil;
		end
	end
	
	--eprint("recipe found : "..string.gsub(recipe,"|"," | "));
	local listid, minMade, maxMade, skillType, reagentline, serviceType = strsplit("|", recipe);
	local reagents = {};
	
	for v in string.gmatch(reagentline, "(%d+x%d+)") do 
		--eprint("    reagent - "..reagentline);
		table.insert( reagents, v ); 
	end
	return serviceType, minMade, maxMade, skillType, reagents, player, tradeskillName, listid;
end