local Debug = function(str, ...)
    if ... then str = str:format(...) end
    DEFAULT_CHAT_FRAME:AddMessage(("Addon: %s"):format(str));
end

local QuickGroups = QuickGroups or {};

QuickGroups.frame = CreateFrame("Frame", nil, UIParent);

QuickGroups.frame:SetScript("OnEvent", function(self, event, ...)
    if self[event] then return self[event](self, ...) end
end);

QuickGroups.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

function QuickGroups.frame:PLAYER_ENTERING_WORLD(delayed)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD");
    self.PLAYER_ENTERING_WORLD = nil;

    local keystone_lvl = C_MythicPlus.GetOwnedKeystoneLevel();

    local greeting = "Welcome to using QuickGroups! ";
    if (keystone_lvl) then
        local map_id = C_MythicPlus.GetOwnedKeystoneChallengeMapID();
        local map_name = select(1, C_ChallengeMode.GetMapUIInfo(map_id));

        greeting = greeting .. "Your current keystone is: |cff4287f5" ..
                       map_name .. " +" .. keystone_lvl .. "|r";
    else
        greeting = greeting .. "You currently don't own a Mythic+ keystone!";
    end

    print(greeting);
end

local function add_tooltip_text(tooltip)
    local name, _ = tooltip:GetItem();

    -- Add tooltip text only when hovering over keystone
    if name == "Mythic Keystone" and not CursorHasItem() then
        tooltip:AddLine("|cffeda55fAlt-Click|r to list group for this keystone.");
    end
end

GameTooltip:HookScript("OnTooltipSetItem", add_tooltip_text)

local function GetActivityGrpIdFromMapId(map_id)
    if type(map_id) ~= "number" then map_id = tonumber(map_id) end

    -- Please don't hate me for this, but no idea how else to do this!
    local map_name = C_ChallengeMode.GetMapUIInfo(map_id);

    -- Create map of map name -> group id
    grp_id_dict = {};
    for i = 259, 266 do
        local name = C_LFGList.GetActivityGroupInfo(i);
        grp_id_dict[name] = i;
    end

    return grp_id_dict[map_name];
end

local function CreateListing(item_string)
    local item_data = {strsplit(":", item_string)}
    
    -- If the item is not a keystone, do nothing
    if item_data[1] ~= "keystone" then return; end
    
    group_id = GetActivityGrpIdFromMapId(item_data[3])

    -- Open up group creation panel if not already open
    local panel = LFGListFrame.EntryCreation;
    if (not LFGListFrame.EntryCreation:IsVisible()) then
        PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub");
        
        -- categoryID 2 == Dungeons
        LFGListEntryCreation_Show(panel, LFGListFrame.baseFilters, 2,
                                  panel.selectedFilters);
        LFGListEntryCreation_Select(panel, nil, nil, group_id, nil)
    end

    -- Fill out group info
    local level = item_data[4];

    local _, avg_ilvl, _ = GetAverageItemLevel();
    
    -- Get min ilvl by rounding down to next multiple of 10
    local min_ilvl = avg_ilvl - avg_ilvl % 10;

    Debug("level: " .. level);
    Debug("min ilvl: " .. min_ilvl);

    -- local activities = C_LFGList.GetAvailableActivities(2, 0, bit.bor(panel.baseFilters, panel.selectedFilters, LE_LFG_LIST_FILTER_RECOMMENDED));
    -- Debug("Nr of available activities: "..tostring(#activities))
    -- for _, activityID in ipairs(activities) do
    --     local name = select(ACTIVITY_RETURN_VALUES.shortName, C_LFGList.GetActivityInfo(activityID));
    --     Debug(tostring(activityID).." "..name)
    -- end

    -- local groups = C_LFGList.GetAvailableActivityGroups(2, bit.bor(panel.baseFilters, panel.selectedFilters, LE_LFG_LIST_FILTER_RECOMMENDED));
    -- Debug("Nr of available activity groups: "..tostring(#groups))
    -- for _, groupID in ipairs(groups) do
    --     local name = C_LFGList.GetActivityGroupInfo(groupID);
    --     Debug(tostring(groupID).." "..name)
    -- end
end

local function OnModifiedClick(self, button)
    if IsAltKeyDown() and button == "LeftButton" and not CursorHasItem() then
        local link =
            GetContainerItemLink(self:GetParent():GetID(), self:GetID())
        -- Retuturn if user clicked on nothing
        if (not link) then return; end
        local item_string = select(3, strfind(link, "|H(.+)|h"));
        CreateListing(item_string);
    end
end

local function OnHyperlinkClick(chatFrame, link, text, button)
    if IsAltKeyDown() and button == "LeftButton" then CreateListing(link) end
end

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", OnModifiedClick)
hooksecurefunc("ChatFrame_OnHyperlinkShow", OnHyperlinkClick)

-- local old_IsPanelValid = LFGListFrame_IsPanelValid;
-- local function LFGListFrame_IsPanelValidNew(self, panel)
--     local val = old_IsPanelValid(self, panel);
--     Debug("self is LFGListFrame: "..tostring(self == LFGListFrame))
--     if ( not val and panel == LFGListFrame.EntryCreation ) then
--         Debug("EntryCreation was invalid!");
--         Debug("IsEditMode: "..tostring(LFGListEntryCreation_IsEditMode(self.EntryCreation)));
--         Debug("BaseFilters equal: "..tostring(self.baseFilters == self.EntryCreation.baseFilters));
--     end
--     return val;
-- end

-- hooksecurefunc("LFGListFrame_IsPanelValid", LFGListFrame_IsPanelValidNew)

-- local function GetModifiers(linkType, ...)
-- 	if type(linkType) ~= 'string' then return end
-- 	local modifierOffset = 4
-- 	local itemID, instanceID, mythicLevel, notDepleted, _ = ... -- "keystone" links
-- 	if linkType:find('item') then -- only used for ItemRefTooltip currently
-- 		_, _, _, _, _, _, _, _, _, _, _, _, _, instanceID, mythicLevel = ...
-- 		if ... == '138019' or ... == '158923' then -- mythic keystone
-- 			modifierOffset = 16
-- 		else
-- 			return
-- 		end
-- 	elseif not linkType:find('keystone') then
-- 		return
-- 	end

-- 	local modifiers = {}
-- 	for i = modifierOffset, select('#', ...) do
-- 		local num = strmatch(select(i, ...) or '', '^(%d+)')
-- 		if num then
-- 			local modifierID = tonumber(num)
-- 			--if not modifierID then break end
-- 			tinsert(modifiers, modifierID)
-- 		end
-- 	end
-- 	local numModifiers = #modifiers
-- 	if modifiers[numModifiers] and modifiers[numModifiers] < 2 then
-- 		tremove(modifiers, numModifiers)
-- 	end
-- 	return modifiers, instanceID, mythicLevel
-- end

-- local function DecorateTooltip(self, link, _)
-- 	if not link then
-- 		_, link = self:GetItem()
-- 	end
-- 	if type(link) == 'string' then
-- 		local modifiers, instanceID, mythicLevel = GetModifiers(strsplit(':', link))
-- 		if modifiers then
-- 			for _, modifierID in ipairs(modifiers) do
-- 				local modifierName, modifierDescription = C_ChallengeMode.GetAffixInfo(modifierID)
-- 				if modifierName and
-- 					modifierDescription then
-- 					self:AddLine(format('|cff00ff00%s|r - %s', modifierName, modifierDescription), 0, 1, 0, true)
-- 				end
-- 			end
-- 			if instanceID then
-- 				local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(instanceID)
-- 				if timeLimit then
-- 					self:AddLine('Time Limit: ' .. SecondsToTime(timeLimit, false, true), 1, 1, 1)
-- 				end
-- 			end
-- 			if mythicLevel then
-- 				local weeklyRewardLevel, endOfRunRewardLevel = C_MythicPlus.GetRewardLevelForDifficultyLevel(mythicLevel)
-- 				if weeklyRewardLevel ~= 0 then
-- 					self:AddDoubleLine('Weekly Reward Level:', weeklyRewardLevel, 1, 1, 1, 1, 1, 1)
-- 				end
-- 			end
-- 			-- C_MythicPlus.GetRewardLevelForDifficultyLevel(9)
-- 			-- -> 375, 365 (weeklyRewardLevel, endOfRunRewardLevel)
-- 			self:Show()
-- 		end
-- 	end
-- end

-- -- hack to handle ItemRefTooltip:GetItem() not returning a proper keystone link
-- hooksecurefunc(ItemRefTooltip, 'SetHyperlink', DecorateTooltip) 
-- --ItemRefTooltip:HookScript('OnTooltipSetItem', DecorateTooltip)
-- GameTooltip:HookScript('OnTooltipSetItem', DecorateTooltip)
