local _, addon = ...
local quickgroups = addon.new_module("quickgroups")

local colors = addon.get_module("colors")

local function add_tooltip_text(tooltip)
    local name, _ = tooltip:GetItem();

    -- Add tooltip text only when hovering over keystone
    if name == "Mythic Keystone" and not CursorHasItem() then
        tooltip:AddLine(
            "\n|cffeda55fAlt-Click|r to list group for this keystone.")
    end
end

-- Please don't hate me for this, but no idea how else to do this conversion!
local function GetActivityGrpIdFromMapId(map_id)
    if type(map_id) ~= "number" then map_id = tonumber(map_id) end

    local map_name = C_ChallengeMode.GetMapUIInfo(map_id)

    -- Create map of map name -> group id
    local grp_id_dict = {}
    for i = 259, 266 do
        local name = C_LFGList.GetActivityGroupInfo(i)
        grp_id_dict[name] = i
    end

    return grp_id_dict[map_name]
end

local function CreateListing(item_string)
    local item_data = {strsplit(":", item_string)}

    -- If the item is not a keystone, do nothing
    if item_data[1] ~= "keystone" then return end

    -- Open up group creation panel if not already open
    local panel = LFGListFrame.EntryCreation
    if (not LFGListFrame.EntryCreation:IsVisible()) then
        PVEFrame_ShowFrame("GroupFinderFrame", "LFGListPVEStub")

        -- categoryID 2 == Dungeons
        LFGListEntryCreation_Show(panel, LFGListFrame.baseFilters, 2,
                                  panel.selectedFilters)
    end

    -- Fill out group info

    -- Select correct dungeon
    local group_id = GetActivityGrpIdFromMapId(item_data[3])
    LFGListEntryCreation_Select(panel, nil, nil, group_id, nil)

    -- Fill in required ilvl info
    if addon.c("autofill_ilvl") then
        local config = addon.get_module("config")

        local min_ilvl = 0
        if addon.c("autofill_ilvl_mode") == config.AutofillModes.ROUND then
            -- Get min ilvl by rounding down to next multiple of "autofill_ilvl_nr"
            local _, avg_ilvl, _ = GetAverageItemLevel()
            min_ilvl = avg_ilvl - avg_ilvl % addon.c("autofill_ilvl_nr")
        elseif addon.c("autofill_ilvl_mode") == config.AutofillModes.STATIC then
            -- Use a static ilvl for autofilling
            min_ilvl = addon.c("autofill_ilvl_nr")
        end

        -- Set min ilvl
        panel.ItemLevel.EditBox:SetText(min_ilvl)
    else
        panel.ItemLevel.EditBox:SetText("")
        panel.ItemLevel.CheckButton:SetChecked(false)
    end

    -- Change title to include name suggestion
    local level = item_data[4]

    panel.NameLabel:SetText("Title (suggested: \"" ..
                                colors:colorise_string("+" .. level, "blue") .. "\")")
end

local function OnModifiedClick(self, button)
    if IsAltKeyDown() and button == "LeftButton" and not CursorHasItem() then
        local link =
            GetContainerItemLink(self:GetParent():GetID(), self:GetID())
        -- Retuturn if user clicked on nothing
        if (not link) then return end
        local item_string = select(3, strfind(link, "|H(.+)|h"))
        CreateListing(item_string)
    end
end

local function OnHyperlinkClick(chatFrame, link, text, button)
    if IsAltKeyDown() and button == "LeftButton" then CreateListing(link) end
end

function quickgroups:init()
    addon.print("Called quickgroups init!")
    -- Hook up tooltip addition
    GameTooltip:HookScript("OnTooltipSetItem", add_tooltip_text)

    -- Hook up alt clicking keystone
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", OnModifiedClick)
    hooksecurefunc("ChatFrame_OnHyperlinkShow", OnHyperlinkClick)
end
